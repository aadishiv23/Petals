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
            lastMessageContent.contains("assignment") ||
            lastMessageContent.contains("classwork") ||
            lastMessageContent.contains("grades") ||
            lastMessageContent.contains("performance") ||
            lastMessageContent.contains("hw") ||
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
                        lastMessageContent.contains("assignment") ||
                        lastMessageContent.contains("classwork") ||
                        lastMessageContent.contains("grades") ||
                        lastMessageContent.contains("performance") ||
                        lastMessageContent.contains("hw") ||
                        lastMessageContent.range(of: "\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) != nil

                    let toolList: [OllamaTool]? = shouldUseTools
                        ? await PetalToolRegistry.ollamaTools() as? [OllamaTool]
                        : nil

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
            let arguments = toolCall.function.arguments
            let toolName = toolCall.function.name

            let rawResult: String
            switch toolName {
            case "petalMockCalendarTool":
                if let dateString = arguments["date"]?.value as? String {
                    rawResult = fetchCalendarEvents(date: dateString)
                } else {
                    continue
                }

            case "petalGenericCanvasCoursesTool":
                let completed = arguments["completed"]?.value as? Bool ?? false
                rawResult = try await fetchCanvasCourses(completed: completed)

            case "petalFetchCanvasAssignmentsTool":
                if let courseName = arguments["courseName"]?.value as? String {
                    rawResult = try await fetchCanvasAssignments(courseName: courseName)
                } else {
                    continue
                }

            case "petalFetchCanvasGradesTool":
                if let courseName = arguments["courseName"]?.value as? String {
                    rawResult = try await fetchCanvasGrades(courseName: courseName)
                } else {
                    continue
                }

            default:
                continue
            }

            // Use the restored `formatToolResponse` to clean up output
            return try await formatToolResponse(toolName, raw: rawResult)
        }
        return ""
    }

    // MARK: - Canvas API Fetch Methods

    /// Fetches the user's enrolled courses from Canvas.
    private func fetchCanvasCourses(completed: Bool) async throws -> String {
        guard !canvasAPIKey.isEmpty else {
            return "Canvas API key not configured. Please add your Canvas API key in settings."
        }

        let urlString = "\(canvasBaseURL)courses?enrollment_state=active"
        guard let url = URL(string: urlString) else {
            return "Invalid Canvas API URL"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(canvasAPIKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return "Failed to fetch Canvas courses."
        }

        let courses = try JSONDecoder().decode([CanvasCourse].self, from: data)
        let filteredCourses = completed ? courses : courses.filter { $0.completedAt == nil }

        if filteredCourses.isEmpty {
            return "No \(completed ? "" : "active ")courses found."
        }

        return filteredCourses.map { "• \($0.name)" }.joined(separator: "\n")
    }

    /// Fetches assignments for a given course.
    private func fetchCanvasAssignments(courseName: String) async throws -> String {
        guard let courseId = try await getCanvasCourseId(for: courseName) else {
            return "Course not found."
        }

        let urlString = "\(canvasBaseURL)courses/\(courseId)/assignments"
        guard let url = URL(string: urlString) else {
            return "Invalid Canvas API URL"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(canvasAPIKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return "Failed to fetch assignments."
        }

        let assignments = try JSONDecoder().decode([CanvasAssignment].self, from: data)
        if assignments.isEmpty {
            return "No assignments found."
        }

        return assignments.map { "• \($0.name) (Due: \($0.dueAt ?? "No due date"))" }.joined(separator: "\n")
    }


    /// Fetches grades for a given course.
    /// Fetches grades for a given course.
    private func fetchCanvasGrades(courseName: String) async throws -> String {
        guard let courseId = try await getCanvasCourseId(for: courseName) else {
            return "Course not found."
        }

        let urlString = "\(canvasBaseURL)courses/\(courseId)/students/submissions"
        guard let url = URL(string: urlString) else {
            return "Invalid Canvas API URL"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(canvasAPIKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return "Failed to fetch grades."
        }

        let submissions = try JSONDecoder().decode([CanvasSubmission].self, from: data)
        if submissions.isEmpty {
            return "No grades available."
        }

        return submissions.map { "• \($0.assignmentName): \($0.grade ?? "Not graded")" }.joined(separator: "\n")
    }


    /// Gets the course ID for a given course name.
    /// Gets the course ID for a given course name.
    private func getCanvasCourseId(for courseName: String) async throws -> Int? {
        let urlString = "\(canvasBaseURL)courses"
        guard let url = URL(string: urlString) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(canvasAPIKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        // Print the raw response for debugging
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
        }

        let rawResponseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        print("Raw API Response: \(rawResponseString)")

        let courses = try JSONDecoder().decode([CanvasCourse].self, from: data)

        return courses.first { $0.name.localizedCaseInsensitiveContains(courseName) }?.id
    }


    // MARK: - Formatting & Summarization

    /// Helper to format the tool response.
    private func formatToolResponse(_ toolName: String, raw: String) async throws -> String {
        // If response already contains bullets or structured output, return as-is.
        guard !raw.contains("•") else { return raw }

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
            The following is data from the user's Learning Management System or Canvas. It lists the classes they are enrolled in. ONLY RETURN the list of classes in a readable list format: "\(
                raw
            )".
            """
        case "petalFetchCanvasAssignmentsTool":
            prompt = """
            The following assignments were retrieved for a course: "\(
                raw
            )". Convert this data into a neatly formatted list.
            """
        case "petalFetchCanvasGradesTool":
            prompt = """
            The following grades were retrieved for a course: "\(raw)". Convert this into a clean, structured summary.
            """
        default:
            return raw // If it's an unknown tool, return as-is.
        }
        return try await summarizeToolResponse(prompt)
    }

    /// Uses the Ollama model to clean up the response.
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

//    private func fetchCanvasCourses(completed: Bool) async throws -> String {
//        // Check if we have valid API credentials
//        guard !canvasAPIKey.isEmpty else {
//            return "Canvas API key not configured. Please add your Canvas API key in settings."
//        }
//
//        // Create the API URL
//        let urlString = "\(canvasBaseURL)courses?enrollment_state=active"
//        guard let url = URL(string: urlString) else {
//            return "Invalid Canvas API URL"
//        }
//
//        // Create the request
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(canvasAPIKey)", forHTTPHeaderField: "Authorization")
//
//        // Make the request
//        do {
//            let (data, response) = try await URLSession.shared.data(for: request)
//
//            // Check for a valid response
//            guard let httpResponse = response as? HTTPURLResponse,
//                  httpResponse.statusCode == 200
//            else {
//                return "Failed to fetch Canvas courses. Please check your API key and try again."
//            }
//
//            // Parse the response
//            let decoder = JSONDecoder()
//            let courses = try decoder.decode([CanvasCourse].self, from: data)
//
//            // Filter courses based on completed parameter if needed
//            let filteredCourses = completed ? courses : courses.filter { !($0.completedAt != nil) }
//
//            // Format the courses into a readable string
//            if filteredCourses.isEmpty {
//                return "No \(completed ? "" : "active ")courses found."
//            }
//
//            let courseList = filteredCourses.map { "• \($0.name)" }.joined(separator: "\n")
//            return "Your \(completed ? "" : "active ")Canvas courses:\n\(courseList)"
//        } catch {
//            return "Error fetching Canvas courses: \(error.localizedDescription)"
//        }
//    }

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
