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
