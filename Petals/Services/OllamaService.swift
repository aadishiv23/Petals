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

    // MARK: Methods

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
            tools: ToolRegistry.tools,
            options: OllamaChatRequestOptions(num_ctx: contextWindowLength)
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(OllamaChatResponse.self, from: data)

        if let toolCalls = res.message?.tool_calls {
            // Handle tool calls
            return try await handleToolCall(toolCalls)
        }

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
                        tools: ToolRegistry.tools,
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
                            print("Role: \(String(describing: res.message?.role))")
                            print("Content: \(String(describing: res.message?.content))")
                            print("Tool Calls: \(String(describing: res.message?.tool_calls))")

                            // 🛠️ If a tool call is present, handle it
                            if let toolCalls = res.message?.tool_calls {
                                let toolResponse = try await handleToolCall(toolCalls)
                                continuation.yield(toolResponse)
                            }

                            // 🟢 If there is content from the assistant, return it
                            if let content = res.message?.content, !content.isEmpty {
                                continuation.yield(content)
                            }

                            // 🔴 If there's no content and no tool calls, continue waiting for more responses
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

    /// Handles function calls requested by Ollama.
    private func handleToolCall(_ toolCalls: [OllamaToolCall]) async throws -> String {
        for toolCall in toolCalls {
            print("Processing Tool Call: \(toolCall.function.name)")

            if toolCall.function.name == "fetchCalendarEvents",
               let dateValue = toolCall.function.arguments["date"],
               let dateString = dateValue.value as? String
            {
                print("Fetching events for date: \(dateString)")
                return fetchCalendarEvents(date: dateString)
            }
        }
        return "Unknown function call."
    }

    /// Mock function: Fetches calendar events for a given date.
    private func fetchCalendarEvents(date: String) -> String {
        switch date {
        case "2025-02-24":
            "Gym with Michael"
        case "2025-02-25":
            "Lunch with Nandan"
        case "2025-02-26":
            "No events"
        default:
            "No events scheduled"
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
