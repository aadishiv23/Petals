//
//  PetalFetchCanvasGradesTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/12/25.
//

import Foundation
import SwiftUI
import PetalCore

public final class PetalFetchCanvasGradesTool: OllamaCompatibleTool {
    
    private let canvasBaseURL = "https://umich.instructure.com/api/v1/"
    private let canvasAPIKey = "1770~ZDxrEf7eVyeHkYL3wQXvYXKDRkGm8UN9ZhBQDUkGJUAf7mPRZmJX34JLeR7AUByD"

    public let uuid: UUID = .init()

    public var id: String { "petalFetchCanvasGradesTool" }

    public var name: String { "Fetch Canvas Grades Tool" }

    public var description: String { "Fetches grades for a specific Canvas course." }

    public var parameters: [PetalToolParameter] {
        [PetalToolParameter(
            name: "courseName",
            description: "Name of the course to fetch grades for.",
            dataType: .string,
            required: true,
            example: AnyCodable("EECS 280")
        )]
    }

    public let triggerKeywords: [String] = ["grades", "performance"]

    public var domain: String { "education" }

    public var requiredPermission: PetalToolPermission { .basic }

    public struct Input: Codable {
        let courseName: String
    }

    public struct Output: Codable {
        let grades: String
    }
    
    public func asOllamaTool() -> OllamaTool {
        return OllamaTool(
            type: "function",
            function: OllamaFunction(
                name: "petalFetchCanvasGradesTool",
                description: "Fetches grades for a specific Canvas course.",
                parameters: OllamaFunctionParameters(
                    type: "object",
                    properties: [
                        "courseName": OllamaFunctionProperty(
                            type: "string",
                            description: "Name of the course to fetch grades for."
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
            return Output(grades: "Course not found.")
        }

        let result = try await fetchGrades(courseId: courseId)
        return Output(grades: result)
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

    private func fetchGrades(courseId: Int) async throws -> String {
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
        if submissions.isEmpty { return "No grades available." }

        return submissions.map { "• \($0.assignmentName): \($0.grade ?? "Not graded")" }.joined(separator: "\n")
    }

    public init() {}
}
