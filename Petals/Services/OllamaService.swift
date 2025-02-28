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

    @AppStorage("canvasBaseURL") private var canvasBaseURL = "https://umich.instructure.com/api/v1/"
    @AppStorage("canvasAPIKey") private var canvasAPIKey =
        "1770~ZDxrEf7eVyeHkYL3wQXvYXKDRkGm8UN9ZhBQDUkGJUAf7mPRZmJX34JLeR7AUByD"

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
            lastMessageContent.contains("canvas") ||
            lastMessageContent.contains("course") ||
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
                        lastMessageContent.contains("canvas") ||
                        lastMessageContent.contains("course") ||
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

            switch toolCall.function.name {
            case "fetchCalendarEvents":
                if let dateValue = toolCall.function.arguments["date"],
                   let dateString = dateValue.value as? String
                {
                    print("Fetching events for date: \(dateString)")
                    let rawResult = fetchCalendarEvents(date: dateString)
                    return try await formatToolResponse("fetchCalendarEvents", raw: rawResult)
                }

            case "fetchCanvasCourses":
                let completedValue = toolCall.function.arguments["completed"]?.value as? Bool ?? false
                print("Fetching Canvas courses (completed: \(completedValue))")
                let rawResult = try await fetchCanvasCourses(completed: completedValue)
                return try await formatToolResponse("fetchCanvasCourses", raw: rawResult)

            default:
                continue
            }
        }
        return ""
    }

    /// A helper function that takes a raw tool response and uses the LLM to rephrase it into a complete sentence.
    private func formatToolResponse(_ toolName: String, raw: String) async throws -> String {
        let prompt: String

        switch toolName {
        case "fetchCalendarEvents":
            prompt = """
            The following is an event from the user's calendar. Respond to the user by describing the event in a natural, friendly manner. Please do not use contractions or abbreviations. Once you have answered, ask the user if there is anything they want you to do.
            Event: "\(raw)"
            """

        case "fetchCanvasCourses":
            prompt = """
            Rewrite the following in a human readable format, in a natural pleasant manner. Only return the human readable classes DO NOT GIVE ANY CODE. ONly return the readable format to the user in a conversational, manner: "\(raw)"
            """

        default:
            return raw // Fallback, return raw response if tool name is unknown
        }

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

    /// Implement the Canvas API function
    private func fetchCanvasCourses(completed: Bool) async throws -> String {
        // Check if we have valid API credentials
        guard !canvasAPIKey.isEmpty else {
            return "Canvas API key not configured. Please add your Canvas API key in settings."
        }

        // Create the API URL
        let urlString = "\(canvasBaseURL)courses?enrollment_state=active"
        guard let url = URL(string: urlString) else {
            return "Invalid Canvas API URL"
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(canvasAPIKey)", forHTTPHeaderField: "Authorization")

        // Make the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Check for a valid response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                return "Failed to fetch Canvas courses. Please check your API key and try again."
            }

            // Parse the response
            let decoder = JSONDecoder()
            let courses = try decoder.decode([CanvasCourse].self, from: data)

            // Filter courses based on completed parameter if needed
            let filteredCourses = completed ? courses : courses.filter { !($0.completedAt != nil) }

            // Format the courses into a readable string
            if filteredCourses.isEmpty {
                return "No \(completed ? "" : "active ")courses found."
            }

            let courseList = filteredCourses.map { "• \($0.name)" }.joined(separator: "\n")
            return "Your \(completed ? "" : "active ")Canvas courses:\n\(courseList)"
        } catch {
            return "Error fetching Canvas courses: \(error.localizedDescription)"
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
