//
//  CanvasModels.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/28/25.
//

import Foundation

/// Add this model for Canvas courses
struct CanvasCourse: Decodable {
    let id: Int
    let name: String
    let courseCode: String
    let workflowState: String
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case courseCode = "course_code"
        case workflowState = "workflow_state"
        case completedAt = "completed_at"
    }
}
