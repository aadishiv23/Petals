//
//  OllamaService.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/15/25.
//

import Foundation
import SwiftUI

// MARK: - OllamaService

/// This service is used to interact with Ollama using the HTTP API.
/// It provides methods for sending messages, streaming responses, and fetching available models.
class OllamaService {

    /// The base URL for Ollama's API, stored in AppStorage for persistence.
    @AppStorage("ollamaBaseURL") private var baseURLString = AppConstants.ollamaDefaultBaseURL

    /// The maximum context window length available for the model.
    @AppStorage("contextWindowLength") private var contextWindowLength = AppConstants.contextWindowLength

    /// Computed property to get the base URL as a `URL` object.
    /// - Throws a fatal error if the stored URL string is invalid.
    private var baseURL: URL {
        guard let url = URL(string: baseURLString) else {
            fatalError("Invalid base URL: \(baseURLString)")
        }
        return url
    }

    // MARK: - Methods

    /// Sends a single message to the Ollama API and returns the response as a `String`.
    ///
    /// - Parameters:
    ///   - model: The model to use for generating responses.
    ///   - messages: A list of chat messages representing the conversation history.
    /// - Returns: The generated response message as a `String`.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    func sendSingleMessage(model: String, messages: [OllamaChatMessage]) async throws -> String {
        let url = baseURL.appendingPathComponent("chat")
        let payload = OllamaChatRequest(
            model: model,
            messages: messages,
            stream: false,
            options: OllamaChatRequestOptions(num_ctx: contextWindowLength)
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(OllamaChatResponse.self, from: data)

        return res.message?.content ?? ""
    }

    /// Streams conversation responses from the Ollama API as they arrive.
    ///
    /// - Parameters:
    ///   - model: The model to use for generating responses.
    ///   - messages: A list of chat messages representing the conversation history.
    /// - Returns: An `AsyncThrowingStream` that yields chunks of the response as they are received.
    func streamConversation(model: String, messages: [OllamaChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = baseURL.appendingPathComponent("chat")
                    let payload = OllamaChatRequest(
                        model: model,
                        messages: messages,
                        stream: true,
                        options: OllamaChatRequestOptions(num_ctx: contextWindowLength)
                    )

                    var req = URLRequest(url: url)
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.httpBody = try JSONEncoder().encode(payload)

                    let (stream, _) = try await URLSession.shared.bytes(for: req)

                    for try await line in stream.lines {
                        if let data = line.data(using: .utf8),
                           let res = try? JSONDecoder().decode(OllamaChatResponse.self, from: data)
                        {
                            if let content = res.message?.content {
                                continuation.yield(content)
                            }
                            if res.done {
                                continuation.finish()
                                return
                            }
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Fetches the list of available models from the Ollama API.
    ///
    /// - Returns: An array of model names available for use.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    func fetchModelList() async throws -> [String] {
        let url = baseURL.appendingPathComponent("tags")

        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(OllamaModelResponse.self, from: data)

        return res.models.map(\.name)
    }
}
