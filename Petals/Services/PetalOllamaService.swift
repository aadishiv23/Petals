//
//  PetalOllamaService.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/11/25.
//

import Foundation
import PetalTools
import SwiftUI

/// Service that interfaces with the Ollama API.
class PetalOllamaService {
    /// Base URL for the Ollama API, persisted via AppStorage.
    @AppStorage("ollamaBaseURL") private var baseURLString = AppConstants.ollamaDefaultBaseURL

    /// Maximum context window length.
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

    // MARK: - Message Handling

    /// Sends a single message to the Ollama API.
    func sendSingleMessage(model: String, messages: [OllamaChatMessage]) async throws -> String {
        let url = baseURL.appendingPathComponent("chat")

        let lastMessageContent = messages.last?.content?.lowercased() ?? ""
        let shouldUseTools = lastMessageContent.contains("calendar") ||
            lastMessageContent.contains("event") ||
            lastMessageContent.contains("canvas") ||
            lastMessageContent.contains("course") ||
            lastMessageContent.range(of: "\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) != nil

        // Use the tool registry from PetalTools to provide tools to the API.
        let payload = OllamaChatRequest(
            model: model,
            messages: messages,
            stream: false,
            tools: shouldUseTools ? await PetalToolRegistry.ollamaTools() as [OllamaTool] : nil,
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

    // MARK: - Stream Conversation

    /// Method to stream conversation.
    func streamConversation(model: String, messages: [OllamaChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = baseURL.appendingPathComponent("chat")

                    let lastMessageContent = messages.last?.content?.lowercased() ?? ""
                    let shouldUseTools = lastMessageContent.contains("calendar") ||
                        lastMessageContent.contains("event") ||
                        lastMessageContent.contains("canvas") ||
                        lastMessageContent.contains("course") ||
                        lastMessageContent.range(of: "\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) != nil

                    let toolList: [OllamaTool]? = shouldUseTools ? await PetalToolRegistry.ollamaTools() as? [OllamaTool] : nil

                    let payload = OllamaChatRequest(
                        model: model,
                        messages: messages,
                        stream: true,
                        tools: toolList,
                        options: OllamaChatRequestOptions(num_ctx: Int(contextWindowLength))
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
                            if let toolCalls = res.message?.tool_calls, !toolCalls.isEmpty {
                                let toolResponse = try await handleToolCall(toolCalls)
                                continuation.yield(toolResponse)
                            }

                            if let content = res.message?.content, !content.isEmpty {
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

    // MARK: - Tool Handling

    /// Processes tool calls returned by Ollama.
    private func handleToolCall(_ toolCalls: [OllamaToolCall]) async throws -> String {
        for toolCall in toolCalls {
            print("Processing Tool Call: \(toolCall.function.name)")
            switch toolCall.function.name {
            case "petalMockCalendarTool":
                if let dateValue = toolCall.function.arguments["date"],
                   let dateString = dateValue.value as? String
                {
                    let rawResult = fetchCalendarEvents(date: dateString)
                    return try await formatToolResponse("petalMockCalendarTool", raw: rawResult)
                }
            case "petalGenericCanvasCoursesTool":
                let completed = toolCall.function.arguments["completed"]?.value as? Bool ?? false
                let rawResult = try await fetchCanvasCourses(completed: completed)
                return try await formatToolResponse("petalGenericCanvasCoursesTool", raw: rawResult)
            default:
                continue
            }
        }
        return ""
    }

    /// Helper to rephrase a tool response.
    private func formatToolResponse(_ toolName: String, raw: String) async throws -> String {
        let prompt: String
        switch toolName {
        case "petalMockCalendarTool":
            prompt = """
            The following event was fetched from your calendar: "\(
                raw
            )". Please describe this event in a friendly manner and ask if further action is needed.
            """
        case "petalGenericCanvasCoursesTool":
            prompt = """
            The following is data from the user's Learning Management System or Canvas. It lists the classes they are enrolled in. ONLY RETURN the list of classes in a readable list format: "\(raw)".
            """
        default:
            return raw
        }
        return try await summarizeToolResponse(prompt)
    }

    /// Sends a prompt to Ollama to summarize tool output.
    private func summarizeToolResponse(_ prompt: String) async throws -> String {
        let url = baseURL.appendingPathComponent("chat")
        let messages = [OllamaChatMessage(role: "user", content: prompt, tool_calls: nil)]
        let payload = OllamaChatRequest(
            model: "llama3.1",
            messages: messages,
            stream: false,
            tools: nil,
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

    // MARK: - Mock Implementations

    private func fetchCalendarEvents(date: String) -> String {
        switch date {
        case "2025-02-24": "Gym with Michael"
        case "2025-02-25": "Lunch with Nandan"
        case "2025-02-26": "No events"
        default: "No events scheduled"
        }
    }

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

    /// Fetches available models from Ollama.
    func fetchModelList() async throws -> [String] {
        let url = baseURL.appendingPathComponent("tags")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode(OllamaModelResponse.self, from: data)
        return res.models.map(\.name)
    }
}
