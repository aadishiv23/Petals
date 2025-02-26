//
//  OllamaService.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/15/25.
//

import Foundation
import SwiftUI

// MARK: - OllamaService

/// A service that interfaces with the Ollama API to handle AI-generated responses.
/// This class provides functionality for sending single messages, streaming responses,
/// and determining when tool calls should be included based on message content.
class OllamaService {

    /// The base URL for Ollama's API, stored in `AppStorage` for persistence.
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

    // MARK: Message Handling

    /// Sends a single message to the Ollama API and returns the response.
    ///
    /// - Parameters:
    ///   - model: The model name to use for generating responses.
    ///   - messages: A list of chat messages representing the conversation history.
    /// - Returns: A `String` containing the assistant's response.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    ///
    /// This function dynamically determines if tool calls should be included based on the message content.
    /// If the last message contains keywords related to a calendar or a date in `YYYY-MM-DD` format,
    /// tools will be included in the request.
    func sendSingleMessage(model: String, messages: [OllamaChatMessage]) async throws -> String {
        let url = baseURL.appendingPathComponent("chat")

        let lastMessageContent = messages.last?.content?.lowercased() ?? ""
        let shouldUseTools: Bool = lastMessageContent.contains("calendar") ||
            lastMessageContent.contains("event") ||
            lastMessageContent.range(of: "\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) != nil

        let payload = OllamaChatRequest(
            model: model,
            messages: messages,
            stream: false,
            tools: shouldUseTools ? ToolRegistry.tools : nil,
            options: OllamaChatRequestOptions(num_ctx: contextWindowLength)
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(OllamaChatResponse.self, from: data)

        if let toolCalls = res.message?.tool_calls, !toolCalls.isEmpty {
            return try await handleToolCall(toolCalls)
        }

        return res.message?.content ?? ""
    }

    // MARK: Streaming Conversation

    /// Streams conversation responses from the Ollama API as they arrive.
    ///
    /// - Parameters:
    ///   - model: The model name to use for generating responses.
    ///   - messages: A list of chat messages representing the conversation history.
    /// - Returns: An `AsyncThrowingStream` that yields chunks of the response as they are received.
    ///
    /// This function determines whether tools should be included based on message content.
    /// If the message is calendar-related or contains a `YYYY-MM-DD` date, tools are enabled.
    func streamConversation(model: String, messages: [OllamaChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = baseURL.appendingPathComponent("chat")

                    let lastMessageContent = messages.last?.content?.lowercased() ?? ""
                    let shouldUseTools: Bool = lastMessageContent.contains("calendar") ||
                        lastMessageContent.contains("event") ||
                        lastMessageContent.range(of: "\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) != nil

                    let payload = OllamaChatRequest(
                        model: model,
                        messages: messages,
                        stream: true,
                        tools: shouldUseTools ? ToolRegistry.tools : nil,
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

                            // If tool calls are present, handle them.
                            if let toolCalls = res.message?.tool_calls, !toolCalls.isEmpty {
                                let toolResponse = try await handleToolCall(toolCalls)
                                continuation.yield(toolResponse)
                            }

                            // If there is content from the assistant, yield it.
                            if let content = res.message?.content, !content.isEmpty {
                                continuation.yield(content)
                            }

                            // If the response is marked as done, finish the stream.
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

    // MARK: Tool Handling

    /// Handles function calls requested by Ollama.
    ///
    /// - Parameter toolCalls: An array of `OllamaToolCall` objects representing requested functions.
    /// - Returns: A `String` containing the tool's response.
    /// - Throws: An error if tool execution fails.
    ///
    /// This function currently supports the `fetchCalendarEvents` tool, which retrieves events for a given date.
    private func handleToolCall(_ toolCalls: [OllamaToolCall]) async throws -> String {
        for toolCall in toolCalls {
            print("Processing Tool Call: \(toolCall.function.name)")
            if toolCall.function.name == "fetchCalendarEvents",
               let dateValue = toolCall.function.arguments["date"],
               let dateString = dateValue.value as? String
            {
                print("Fetching events for date: \(dateString)")
                let rawResult = fetchCalendarEvents(date: dateString)
                return try await formatToolResponse(rawResult)
            }
        }
        return ""
    }

    /// A helper function that takes a raw tool response and uses the LLM to rephrase it into a complete sentence.
    private func formatToolResponse(_ raw: String) async throws -> String {
        let prompt = "The following is an event from user's calendar event. Respond to the user by responding with a full sentence indicating the event. Respond in a natural, friendly manner. Please do not use contractions or abbreviations. Once you have answered, ask the user if there is anything they want you to do: \"\(raw)\""
        return try await summarizeToolResponse(prompt)
    }

    /// Sends a message without checking for tool calls—used for summarizing tool outputs.
    private func summarizeToolResponse(_ prompt: String) async throws -> String {
        let url = baseURL.appendingPathComponent("chat")
        let messages = [OllamaChatMessage(role: "user", content: prompt, tool_calls: [])]
        let payload = OllamaChatRequest(
            model: "llama3.2", // Use your desired model here.
            messages: messages,
            stream: false,
            tools: nil, // No tools to prevent recursion.
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

    /// Mock function: Fetches calendar events for a given date.
    ///
    /// - Parameter date: The requested date in `YYYY-MM-DD` format.
    /// - Returns: A `String` representing the events scheduled for that date.
    ///
    /// This is a placeholder implementation that returns hardcoded events.
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

    // MARK: Model List Fetching

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
