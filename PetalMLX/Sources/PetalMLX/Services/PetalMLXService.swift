//
//  PetalMLXService.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 3/26/25.
//

import Foundation
import MLXLLM
import MLXLMCommon
import SwiftUI

public class PetalMLXService {
    private let modelService = CoreModelService()
    private let toolCallHandler = AppToolCallHandler.shared
    
    /// A simple chat message structure.

    public struct ChatMessage: Identifiable, Equatable, Hashable {
        let id = UUID()
        let date = Date()
        
        var message: String
        var pending: Bool = false
        var participant: Participant
        var toolCallName: String? = nil

        enum Participant {
            case user
            case system
            case llm
        }

        static func pending(participant: Participant) -> ChatMessage {
            return ChatMessage(message: "", pending: true, participant: participant)
        }
    }
    
    /// Structure for streaming message chunks.
    public struct MLXPetalMessageStreamChunk {
        
        /// The message returned by the LLM.
        public let message: String
        
        /// (Optional) The name of the tool call used by the assistant.
        public let toolCallName: String?
        
        // MARK: Initializer
        
        public init(message: String, toolCallName: String?) {
            self.message = message
            self.toolCallName = toolCallName
        }
    }
    
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
        return messages.map { ["role": $0.role, "content": $0.content] }
    }
    
    /// Generates a complete response from the MLX model.
    public func sendSingleMessage(model: ModelConfiguration,
                                  messages: [ChatMessage]) async throws -> String {
        let lastMessage = messages.last?.content ?? ""
        let useTools = shouldUseTools(for: lastMessage)
        let tools: [[String: any Sendable]]? = useTools ? await PetalToolRegistry.mlxTools() : nil
        
        let formattedMessages = formatMessages(messages)
        let container = modelService.provideModelContainer()
        let result = try await container.generate(
            messages: formattedMessages,
            tools: tools,
            onProgress: { _ in }
        )
        
        // Process tool calls if detected.
        let finalOutput = try await processToolCallsIfNeeded(result.output)
        return finalOutput
    }
    
    /// Streams the conversation as an async sequence of output chunks.
    public func streamConversation(model: ModelConfiguration,
                                   messages: [ChatMessage]) -> AsyncThrowingStream<PetalMessageStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let lastMessage = messages.last?.content ?? ""
                    let useTools = shouldUseTools(for: lastMessage)
                    let tools: [[String: any Sendable]]? = useTools ? await PetalToolRegistry.mlxTools() : nil
                    let formattedMessages = formatMessages(messages)
                    let container = modelService.provideModelContainer()
                    
                    let result = try await container.generate(
                        messages: formattedMessages,
                        tools: tools,
                        onProgress: { progressText in
                            continuation.yield(PetalMessageStreamChunk(message: progressText, toolCallName: nil))
                        }
                    )
                    
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
