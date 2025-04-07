//
//  CanvasModels.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/28/25.
//

import Foundation

/// Add this model for Canvas courses
public struct CanvasCourse: Decodable {
    public let id: Int
    public let name: String
    public let courseCode: String
    public let workflowState: String
    public let completedAt: String?

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case courseCode = "course_code"
        case workflowState = "workflow_state"
        case completedAt = "completed_at"
    }
}

struct CanvasAssignment: Codable {
    let id: Int
    let name: String
    let description: String?
    let dueAt: String?
    let pointsPossible: Double?
    let submissionTypes: [String]
    let htmlURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case dueAt = "due_at"
        case pointsPossible = "points_possible"
        case submissionTypes = "submission_types"
        case htmlURL = "html_url"
    }
}


public struct CanvasSubmission: Decodable {
    public let assignmentId: Int
    public let grade: String?

    public enum CodingKeys: String, CodingKey {
        case assignmentId = "assignment_id"
        case grade
    }

    public var assignmentName: String {
        "Assignment \(assignmentId)"
    }
}
