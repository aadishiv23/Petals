//
//  OllamaChatModel.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/15/25.
//

import Foundation

class OllamaChatModel: AIChatModel {
    private let ollamaService = OllamaService()
    private let modelName: String

    init(modelName: String = "llama3.2") { // Default Ollama model, default petal: petalllama3.2
        self.modelName = modelName
    }

    func sendMessageStream(_ text: String) -> AsyncStream<String> {
        let messages = [OllamaChatMessage(role: "user", content: text)]

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

    func sendMessage(_ text: String) async throws -> String {
        let messages = [OllamaChatMessage(role: "user", content: text)]
        return try await ollamaService.sendSingleMessage(model: modelName, messages: messages)
    }
}
