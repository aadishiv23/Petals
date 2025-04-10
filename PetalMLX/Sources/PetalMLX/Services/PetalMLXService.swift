//
//  PetalMLXService.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 3/26/25.
//

import Foundation
import MLXLLM
import MLXLMCommon
import PetalCore
import PetalTools
import SwiftUI

enum PetalMLXServiceError: Error {
    case unexpectedModelContainerType
}

@MainActor
public class PetalMLXService {
    private let modelService = CoreModelService()
    private let toolCallHandler = AppToolCallHandler.shared
    private let evaluator = ToolTriggerEvaluator()


    /// Determines whether the message should trigger tool usage.
    private func shouldUseTools(for message: String) -> Bool {
        return ExemplarProvider.shared.shouldUseTools(for: message)
    }

    /// Formats chat messages into the MLX expected dictionary format.
    private func formatMessages(_ messages: [ChatMessage]) -> [[String: String]] {
        messages.map { ["role": $0.participant.stringValue, "content": $0.message] }
    }

    /// Generates a complete response from the MLX model.
    public func sendSingleMessage(
        model: ModelConfiguration,
        messages: [ChatMessage]
    ) async throws -> String {
        let lastMessage = messages.last?.message ?? ""
        let useTools = shouldUseTools(for: lastMessage)
        // Get the MLX-compatible tool objects if needed.
        let tools: [any MLXCompatibleTool]? = useTools ? await PetalMLXToolRegistry.mlxTools() : nil

        let formattedMessages = formatMessages(messages)

        // --- CHANGE START ---
        let rawContainer = modelService.provideModelContainer()
        guard let container = rawContainer as? ConcreteCoreModelContainer else {
            throw PetalMLXServiceError.unexpectedModelContainerType
        }
        // --- CHANGE END ---

        let toolDefinitions: [[String: any Sendable]]? = tools?.map { tool in
            tool.asMLXToolDefinition().toDictionary()
        }

        let result = try await container.generate(
            messages: formattedMessages,
            tools: toolDefinitions,
            onProgress: { _ in }
        ) as! GenerateResult

        // Process the result for potential tool calls.
        let finalOutput = try await processToolCallsIfNeeded(result)
        return finalOutput
    }

    /// Streams the conversation as an async sequence of output chunks.
    public func streamConversation(
        model: ModelConfiguration,
        messages: [ChatMessage]
    ) -> AsyncThrowingStream<PetalMessageStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let lastMessage = messages.last?.message ?? ""
                    let useTools = await shouldUseTools(for: lastMessage)
                    let tools: [any MLXCompatibleTool]? = useTools ? await PetalMLXToolRegistry.mlxTools() : nil
                    let formattedMessages = formatMessages(messages)

                    let rawContainer = modelService.provideModelContainer()
                    guard let container = rawContainer as? ConcreteCoreModelContainer else {
                        throw PetalMLXServiceError.unexpectedModelContainerType
                    }

                    // Convert each MLXCompatibleTool to a dictionary using its MLXToolDefinition.
                    let toolDefinitions: [[String: any Sendable]]? = tools?.map { tool in
                        tool.asMLXToolDefinition().toDictionary()
                    }

                    // Create an actor to safely store and access the complete output
                    actor OutputStore {
                        private(set) var completeOutput: String = ""
                        private(set) var isToolCall: Bool = false

                        func update(with text: String) {
                            completeOutput = text
                            // Check if this contains a tool call marker
                            isToolCall = text.contains("<|python_tag|>") ||
                                text.contains("<tool_call>") ||
                                text.contains("\"function_call\"") ||
                                text.contains("\"type\": \"function\"")
                        }

                        func getCurrentOutput() -> String {
                            completeOutput
                        }

                        func getIsToolCall() -> Bool {
                            isToolCall
                        }
                    }

                    let outputStore = OutputStore()

                    // Yield a placeholder to indicate tool processing is starting
                    if useTools {
                        // Don't yield any real content yet, just set the toolCallName
                        // This will make the UI show the loading state
                        let potentialToolName = detectPotentialToolName(from: lastMessage)
                        continuation.yield(PetalMessageStreamChunk(
                            message: "",
                            toolCallName: potentialToolName
                        ))
                    }

                    let result = try await container.generate(
                        messages: formattedMessages,
                        tools: toolDefinitions,
                        onProgress: { progressText in
                            // Safely update the complete output through the actor
                            Task {
                                await outputStore.update(with: progressText)
                                let isToolCall = await outputStore.getIsToolCall()

                                // Only stream the content if it's NOT a tool call
                                if !isToolCall {
                                    continuation.yield(PetalMessageStreamChunk(
                                        message: progressText,
                                        toolCallName: nil
                                    ))
                                }
                                // Otherwise we don't yield during streaming for tool calls
                            }
                        }
                    ) as! GenerateResult

                    // Get the final state
                    let finalOutput = await outputStore.getCurrentOutput()
                    let isToolCall = await outputStore.getIsToolCall()

                    // If it was a tool call, process it
                    if isToolCall || useTools {
                        let processedResult = try await processToolCallsIfNeeded(result)
                        let toolName = extractToolName(from: finalOutput)

                        // Yield the final processed result for the tool call
                        continuation.yield(PetalMessageStreamChunk(
                            message: processedResult,
                            toolCallName: toolName
                        ))
                    } else if !useTools {
                        // If we didn't stream any content and it wasn't a tool call,
                        // make sure we yield the final output
                        continuation.yield(PetalMessageStreamChunk(
                            message: finalOutput,
                            toolCallName: nil
                        ))
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Try to predict potential tool name from the message to improve UX
    private func detectPotentialToolName(from message: String) -> String? {
        let lowercasedMessage = message.lowercased()

        if lowercasedMessage.contains("canvas") &&
            (lowercasedMessage.contains("course") || lowercasedMessage.contains("class"))
        {
            return "petalGenericCanvasCoursesTool"
        } else if lowercasedMessage.contains("calendar") || lowercasedMessage.contains("event") {
            return "petalCalendarFetchEventsTool"
        } else if lowercasedMessage.contains("reminder") || lowercasedMessage.contains("task") {
            return "petalRemindersTool"
        } else if lowercasedMessage.contains("assignment") {
            return "petalFetchCanvasAssignmentsTool"
        } else if lowercasedMessage.contains("grade") {
            return "petalFetchCanvasGradesTool"
        }

        return nil
    }

    /// Helper method to extract tool name from output if present
    private func extractToolName(from output: String) -> String? {
        // Check if the output contains a JSON string with a tool name
        if output.contains("\"name\":") || output.contains("\"name\": ") {
            // Try to find the name pattern in the Llama format JSON string
            if let range = output.range(of: "\"name\"\\s*:\\s*\"([^\"]+)\"", options: .regularExpression) {
                let matched = output[range]
                let namePattern = "\"([^\"]+)\"$"
                if let nameRange = matched.range(of: namePattern, options: .regularExpression) {
                    let nameWithQuotes = matched[nameRange]
                    // Remove the quotes around the name
                    return String(nameWithQuotes.dropFirst().dropLast())
                }
            }

            // Alternative approach for JSON that might be differently formatted
            do {
                // Extract JSON string if it's within a larger text
                var jsonString = output
                if let jsonStart = output.range(of: "{", options: .backwards),
                   let jsonEnd = output.range(of: "}", options: .backwards)
                {
                    let startIndex = jsonStart.lowerBound
                    let endIndex = jsonEnd.upperBound
                    if startIndex < endIndex {
                        jsonString = String(output[startIndex..<endIndex])
                    }
                }

                // Try to parse as JSON
                if let data = jsonString.data(using: .utf8),
                   let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let name = json["name"] as? String
                {
                    return name
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }

        return nil
    }

    /// If a tool call is detected in the generated result, process it and then format the response.
    private func processToolCallsIfNeeded(_ result: GenerateResult) async throws -> String {
        let processed = try await toolCallHandler.processLLMOutput(result)
//        if processed.toolCalled, let toolName = processed.toolName {
//            return try await formatToolResponse(toolName: toolName, raw: processed.processedOutput)
//        }
        return processed.processedOutput
    }

    /// Formats the raw result from a tool call into a user-friendly message.
    private func formatToolResponse(toolName: String, raw: String) async throws -> String {
        // Use the model to rephrase the raw result into something natural
        let refinementPrompt = """
        The tool returned the following raw output:

        \(raw)

        Please summarize this result in a friendly, helpful way as if you're explaining it to a user.
        """

        // We'll send this to the model without tools enabled (so it doesn't recurse into another tool call)
        let summaryMessages = [
            ["role": "system", "content": "You are a helpful assistant that summarizes tool results."],
            ["role": "user", "content": refinementPrompt]
        ]

        let container = modelService.provideModelContainer()
        guard let container = container as? ConcreteCoreModelContainer else {
            throw PetalMLXServiceError.unexpectedModelContainerType
        }

        let summaryResult = try await container.generate(
            messages: summaryMessages,
            tools: nil,
            onProgress: { _ in }
        ) as! GenerateResult

        return summaryResult.output
    }

}
