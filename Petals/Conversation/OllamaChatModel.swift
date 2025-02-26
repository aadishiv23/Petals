//
//  OllamaChatModel.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/15/25.
//

import Foundation

/// A chat model that interfaces with the Ollama service for handling AI-generated responses.
///
/// This model supports both single-response messaging and streaming responses, leveraging
/// the `OllamaService` to communicate with the locally hosted Ollama model.
class OllamaChatModel: AIChatModel {
    
    // MARK: Private Properties
    
    /// The service responsible for communicating with the Ollama API.
    private let ollamaService = OllamaService()
    
    /// The name of the AI model used for processing messages.
    private let modelName: String

    // MARK: Initializer
    
    /// Initializes the Ollama chat model with an optional model name.
    ///
    /// - Parameter modelName: The name of the model to use. Defaults to `"llama3.2"` `petallama3.2` is a WIP custom model.
    init(modelName: String = "llama3.2") {
        self.modelName = modelName
    }

    // MARK: Streaming Message Handling
    
    /// Sends a user message and returns a streaming response from the AI model.
    ///
    /// - Parameter text: The user input message.
    /// - Returns: An `AsyncStream<String>` where each chunk represents part of the AI response.
    ///
    /// This function:
    /// - Constructs a message payload.
    /// - Calls `OllamaService.streamConversation` to fetch a streaming response.
    /// - Yields each chunk of the response asynchronously.
    /// - Handles errors and ensures the stream is properly closed.
    func sendMessageStream(_ text: String) -> AsyncStream<String> {
        let messages = [OllamaChatMessage(role: "user", content: text, tool_calls: [])]

        return AsyncStream { continuation in
            Task {
                do {
                    for try await chunk in ollamaService.streamConversation(model: modelName, messages: messages) {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    print("Ollama streaming error: \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }

    // MARK: Single Message Handling
    
    /// Sends a user message and returns a single response from the AI model.
    ///
    /// - Parameter text: The user input message.
    /// - Returns: A `String` containing the AI's response.
    ///
    /// This function:
    /// - Constructs a message payload.
    /// - Calls `OllamaService.sendSingleMessage` for processing.
    /// - Returns the AI's response.
    /// - Throws an error if the request fails.
    func sendMessage(_ text: String) async throws -> String {
        let messages = [OllamaChatMessage(role: "user", content: text, tool_calls: [])]
        return try await ollamaService.sendSingleMessage(model: modelName, messages: messages)
    }
}
