//
//  OllamaSwiftService.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/17/25.
//

// DOESNT WORK RIGHT NOW
/*
import Foundation
import Ollama
import SwiftUI

// MARK: - OllamaSwiftService

/// This service is used to interface with Ollama using the `OllamaSwift` package.
final class OllamaSwiftService {

    /// The URL through which send HTTP requests to communicate with Ollama.
    @AppStorage("ollamaBaseURL") private var baseURLString = AppConstants.ollamaDefaultBaseURL

    /// The maximum context window length available to our model. Currently, 2048 tokens.
    @AppStorage("contextWindowLength") private var contextWindowLength = AppConstants.contextWindowLength

    /// Initialize the client for OllamaSwift.
    private var client: Client {
        Client.default
    }

    // MARK: Methods

    /// THis functions sends a single message to the Ollama API and returns the reponse as a `String`.
    func sendSingleMessage(
        model: String,
        messages: [OllamaChatMessage]
    ) async throws -> String {
        let ollamaMessages = messages.map {
            OllamaChatMessage(
                role: $0.role,
                content: $0.content
            )
        }
        let response = try await client.chat(model: model, messages: ollamaMessages)
        return response.message?.message ?? ""
    }

    /// Streams conversation responses as they come in.
    func streamConversation(
        model: String,
        messages: [OllamaChatMessage]
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let prompt = messages.map(\.content).joined(separator: "\n")

                    let response = try await client.generate(
                        model: Model.ID(rawValue: model),
                        prompt: prompt,
                        stream: true
                    )

                    continuation.yield(response.response)
                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
*/
