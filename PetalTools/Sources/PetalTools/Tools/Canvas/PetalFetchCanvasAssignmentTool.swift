//
//  PetalFetchCanvasAssignmentsTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/12/25.
//

import Foundation
import SwiftUI
import PetalCore

public final class PetalFetchCanvasAssignmentsTool: OllamaCompatibleTool, MLXCompatibleTool {
    
    private let canvasBaseURL = "https://umich.instructure.com/api/v1/"
    private let canvasAPIKey = "1770~ZDxrEf7eVyeHkYL3wQXvYXKDRkGm8UN9ZhBQDUkGJUAf7mPRZmJX34JLeR7AUByD"

    public let uuid: UUID = .init()

    public var id: String { "petalFetchCanvasAssignmentsTool" }

    public var name: String { "Fetch Canvas Assignments Tool" }

    public var description: String { "Fetches assignments for a specific Canvas course." }

    public var parameters: [PetalToolParameter] {
        [PetalToolParameter(
            name: "courseName",
            description: "Name of the course to fetch assignments for.",
            dataType: .string,
            required: true,
            example: AnyCodable("EECS 280")
        )]
    }

    public let triggerKeywords: [String] = ["assignments", "classwork"]

    public var domain: String { "education" }

    public var requiredPermission: PetalToolPermission { .basic }

    public struct Input: Codable {
        let courseName: String
    }

    public struct Output: Codable, Sendable {
        public let assignments: String
    }
    
    public func asOllamaTool() -> OllamaTool {
        return OllamaTool(
            type: "function",
            function: OllamaFunction(
                name: "petalFetchCanvasAssignmentsTool",
                description: "Fetches assignments for a specific Canvas course.",
                parameters: OllamaFunctionParameters(
                    type: "object",
                    properties: [
                        "courseName": OllamaFunctionProperty(
                            type: "string",
                            description: "Name of the course to fetch assignments for."
                        )
                    ],
                    required: ["courseName"]
                )
            )
        )
    }

    // MARK: - MLX-Compatible
    
    public func asMLXToolDefinition() -> MLXToolDefinition {
        return MLXToolDefinition(
            type: "function",
            function: MLXFunctionDefinition(
                name: "petalFetchCanvasAssignmentsTool",
                description: "Fetches assignments for a specific Canvas course.",
                parameters: MLXParametersDefinition(
                    type: "object",
                    properties: [
                        "courseName": MLXParameterProperty(
                            type: "string",
                            description: "Name of the course to fetch assignments for."
                        )
                    ],
                    required: ["courseName"]
                )
            )
        )
    }

    public func execute(_ input: Input) async throws -> Output {
        // Get the course ID based on the course name provided by the user
        let (courseId, courseName) = try await getCourseIdAndName(for: input.courseName)
        
        // Handle case where no matching course was found
        guard let courseId = courseId, let courseName = courseName else {
            return Output(assignments: "Course '\(input.courseName)' not found. Please check the course name and try again.")
        }

        // Fetch assignments for the found course
        let result = try await fetchAssignments(courseId: courseId, courseName: courseName)
        return Output(assignments: result)
    }

    private func getCourseIdAndName(for courseName: String) async throws -> (Int?, String?) {
        // Create the API URL
        let urlString = "\(canvasBaseURL)courses?enrollment_state=active"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "PetalTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Canvas API URL"])
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(canvasAPIKey)", forHTTPHeaderField: "Authorization")

        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check for a valid response
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "PetalTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch Canvas courses"])
        }

        // Parse the response
        let decoder = JSONDecoder()
        let courses = try decoder.decode([CanvasCourse].self, from: data)
        
        // Find the course that matches the user's input (case insensitive)
        if let matchedCourse = courses.first(where: { $0.name.localizedCaseInsensitiveContains(courseName) }) {
            return (matchedCourse.id, matchedCourse.name)
        }
        
        return (nil, nil)
    }

    private func fetchAssignments(courseId: Int, courseName: String) async throws -> String {
        let urlString = "\(canvasBaseURL)courses/\(courseId)/assignments"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "PetalTools", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid Canvas API URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(canvasAPIKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return "Failed to fetch assignments. Please check your API key and try again."
            }

            let decoder = JSONDecoder()
            let assignments = try decoder.decode([CanvasAssignment].self, from: data)
            
            if assignments.isEmpty {
                return "Course: \(courseName)\n\nNo assignments found for this course."
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

            let formatted = assignments.map { assignment in
                let dueDate = assignment.dueAt.flatMap { formatter.date(from: $0)?.formatted(date: .abbreviated, time: .shortened) } ?? "No due date"
                let points = assignment.pointsPossible != nil ? "\(assignment.pointsPossible!) pts" : "No point value"
                let fullDescription = assignment.description?
                    .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) ?? "No description"
                return """
                • \(assignment.name)
                  - Due: \(dueDate)
                  - Points: \(points)
                  - Types: \(assignment.submissionTypes.joined(separator: ", "))
                  - Description: \(fullDescription)...
                  - Link: \(assignment.htmlURL ?? "N/A")
                """
            }

            // Prepend the course name to the output
            return "Course: \(courseName)\n\n" + formatted.joined(separator: "\n\n")
        } catch {
            return "Error fetching assignments: \(error.localizedDescription)"
        }
    }

    public init() {}
}
