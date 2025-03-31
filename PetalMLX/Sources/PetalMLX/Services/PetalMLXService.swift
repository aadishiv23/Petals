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
import SwiftUI

/// Define a simple error for the cast failure
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
            "calendarTool": [
                "create a calendar event",
                "schedule an event",
                "book a meeting"
            ],
            "canvasCoursesTool": [
                "show me my courses",
                "list my classes",
                "display my canvas courses"
            ]
            // Add additional tool exemplars as needed.
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
        let tools: [[String: any Sendable]]? = useTools ? await PetalMLXToolRegistry.mlxTools() : nil

        let formattedMessages = formatMessages(messages)

        // --- CHANGE START ---
        // Get the container conforming to the protocol
        let rawContainer = modelService.provideModelContainer()

        // Explicitly cast to the concrete Sendable type before awaiting its method
        guard let container = rawContainer as? ConcreteCoreModelContainer else {
            // Handle the case where the container isn't the expected concrete type
            throw PetalMLXServiceError.unexpectedModelContainerType
        }
        // --- CHANGE END ---
        let result: MLXLMCommon.GenerateResult = try await container.generate(
            messages: formattedMessages,
            tools: tools,
            onProgress: { _ in }
        ) as! GenerateResult

        // Process tool calls if detected.
        let finalOutput = try await processToolCallsIfNeeded(result.output)
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
                    let tools: [[String: any Sendable]]? = useTools ? await PetalMLXToolRegistry.mlxTools() : nil
                    let formattedMessages = formatMessages(messages)
                    let container = modelService.provideModelContainer()
                    
                    // --- CHANGE START ---
                    // Get the container conforming to the protocol
                    let rawContainer = modelService.provideModelContainer()

                    // Explicitly cast to the concrete Sendable type before awaiting its method
                    guard let container = rawContainer as? ConcreteCoreModelContainer else {
                        // Handle the case where the container isn't the expected concrete type
                        throw PetalMLXServiceError.unexpectedModelContainerType
                    }
                    // --- CHANGE END ---
                    // if i dont do above: Non-sendable type 'Any' returned by implicitly asynchronous call to nonisolated function cannot cross actor boundary

                    let result: MLXLMCommon.GenerateResult = try await container.generate(
                        messages: formattedMessages,
                        tools: tools,
                        onProgress: { progressText in
                            continuation.yield(PetalMessageStreamChunk(message: progressText, toolCallName: nil))
                        }
                    ) as! GenerateResult

                    let finalOutput = try await processToolCallsIfNeeded(result.output)
                    continuation.yield(PetalMessageStreamChunk(message: finalOutput, toolCallName: nil))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Processes tool calls in the generated output if any are detected.
    private func processToolCallsIfNeeded(_ output: String) async throws -> String {
        if let processed = try? await toolCallHandler.processLLMOutput(output) {
            return processed
        }
        return output
    }
}
