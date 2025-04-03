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

    /// Determines whether the message should trigger tool usage.
    private func shouldUseTools(for message: String) -> Bool {
        let toolExemplars: [String: [String]] = [
            "petalCalendarFetchEventsTool": [
                "Fetch calendar events for me",
                "Show calendar events",
                "List my events",
                "Get events from my calendar",
                "Retrieve calendar events"
            ],
            "petalCalendarCreateEventTool": [
                "Create a calendar event on [date]",
                "Schedule a new calendar event",
                "Add a calendar event to my schedule",
                "Book an event on my calendar",
                "Set up a calendar event"
            ],
            "petalFetchRemindersTool": [
                "Show me my reminders",
                "List my tasks for today",
                "Fetch completed reminders",
                "Get all my pending reminders",
                "Find reminders containing 'doctor'"
            ],
            "petalGenericCanvasCoursesTool": [
                "Show me my Canvas courses",
                "List my classes on Canvas",
                "Display my Canvas courses",
                "What courses am I enrolled in?",
                "Fetch my Canvas classes"
            ],
            "petalFetchCanvasAssignmentsTool": [
                "Fetch assignments for my course",
                "Show my Canvas assignments",
                "Get assignments for my class",
                "Retrieve course assignments from Canvas",
                "List assignments for my course"
            ],
            "petalFetchCanvasGradesTool": [
                "Show me my grades",
                "Get my Canvas grades",
                "Fetch my course grades",
                "Display grades for my class",
                "Retrieve my grades from Canvas"
            ]
        ]

        for (_, exemplars) in toolExemplars {
            for exemplar in exemplars {
                if message.lowercased().contains(exemplar.lowercased()) {
                    return true
                }
            }
        }
        return false
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
                    let useTools = shouldUseTools(for: lastMessage)
                    let tools: [any MLXCompatibleTool]? = useTools ? await PetalMLXToolRegistry.mlxTools() : nil
                    let formattedMessages = formatMessages(messages)

                    // --- CHANGE START ---
                    let rawContainer = modelService.provideModelContainer()
                    guard let container = rawContainer as? ConcreteCoreModelContainer else {
                        throw PetalMLXServiceError.unexpectedModelContainerType
                    }
                    // --- CHANGE END ---

                    // Convert each MLXCompatibleTool to a dictionary using its MLXToolDefinition.
                    let toolDefinitions: [[String: any Sendable]]? = tools?.map { tool in
                        tool.asMLXToolDefinition().toDictionary()
                    }

                    let result = try await container.generate(
                        messages: formattedMessages,
                        tools: toolDefinitions, // Pass the converted tool definitions here
                        onProgress: { progressText in
                           // continuation.yield(PetalMessageStreamChunk(message: progressText, toolCallName: nil))
                        }
                    )

                    let finalOutput = try await processToolCallsIfNeeded(result)
                    continuation.yield(PetalMessageStreamChunk(message: finalOutput, toolCallName: nil))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// If a tool call is detected in the generated result, process it and then format the response.
    private func processToolCallsIfNeeded(_ result: GenerateResult) async throws -> String {
        let processed = try await toolCallHandler.processLLMOutput(result)
        if processed.toolCalled, let toolName = processed.toolName {
            return try await formatToolResponse(toolName: toolName, raw: processed.processedOutput)
        }
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
