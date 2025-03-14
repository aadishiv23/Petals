//
//  PetalFetchCanvasAssignmentsTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/12/25.
//

import Foundation
import SwiftUI

public final class PetalFetchCanvasAssignmentsTool: OllamaCompatibleTool {
    
    
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

    public struct Output: Codable {
        let assignments: String
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


    public func execute(_ input: Input) async throws -> Output {
        let courseId = try await getCourseId(for: input.courseName)
        guard let courseId = courseId else {
            return Output(assignments: "Course not found.")
        }

        let result = try await fetchAssignments(courseId: courseId)
        return Output(assignments: result)
    }

    private func getCourseId(for courseName: String) async throws -> Int? {
        let urlString = "\(canvasBaseURL)courses"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(canvasAPIKey)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let courses = try JSONDecoder().decode([CanvasCourse].self, from: data)

        return courses.first { $0.name.localizedCaseInsensitiveContains(courseName) }?.id
    }

    private func fetchAssignments(courseId: Int) async throws -> String {
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
        if assignments.isEmpty { return "No assignments found." }

        return assignments.map { "• \($0.name) (Due: \($0.dueAt ?? "No due date"))" }.joined(separator: "\n")
    }

    init() {}
}
