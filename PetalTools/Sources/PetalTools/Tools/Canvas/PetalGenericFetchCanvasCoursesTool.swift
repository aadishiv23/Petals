//
//  PetalGenericFetchCanvasCoursesTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/11/25.
//

import Foundation
import SwiftUI
import PetalCore

public final class PetalGenericFetchCanvasCoursesTool: OllamaCompatibleTool {
    
    // TODO: Need beter way to DI this and not leak keuys
    private let canvasBaseURL = "https://umich.instructure.com/api/v1/"
    private let canvasAPIKey =
        "1770~ZDxrEf7eVyeHkYL3wQXvYXKDRkGm8UN9ZhBQDUkGJUAf7mPRZmJX34JLeR7AUByD"

    public let uuid: UUID = .init()

    public var id: String { "petalGenericCanvasCoursesTool" }

    public var name: String { "Petal Generic Fetch Canvas Courses Tool" }

    public var description: String { "Fetches user's Canvas courses." }

    public var parameters: [PetalToolParameter] {
        [PetalToolParameter(
            name: "completed",
            description: "Whether to include completed courses.",
            dataType: .boolean,
            required: false,
            example: AnyCodable(false)
        )]
    }

    public let triggerKeywords: [String] = ["canvas", "courses", "classes"]

    public var domain: String { "education" }

    public var requiredPermission: PetalToolPermission { .basic }

    /// Define the input and output types
    public struct Input: Codable {
        let completed: Bool?
    }

    public struct Output: Codable {
        public let courses: String
    }

    /// Implements the `execute` function required by `PetalTool`
    public func execute(_ input: Input) async throws -> Output {
        let result = try await fetchCanvasCourses(completed: input.completed ?? false)
        return Output(courses: result)
    }

    public func asOllamaTool() -> OllamaTool {
        return OllamaTool(
            type: "function",
            function: OllamaFunction(
                name: "petalGenericCanvasCoursesTool",
                description: "Fetches user's Canvas courses.",
                parameters: OllamaFunctionParameters(
                    type: "object",
                    properties: [
                        "completed": OllamaFunctionProperty(
                            type: "boolean",
                            description: "Whether to include completed courses."
                        )
                    ],
                    required: []
                )
            )
        )
    }

    /// Fetches Canvas courses from the API.
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

    public init() {}
}
