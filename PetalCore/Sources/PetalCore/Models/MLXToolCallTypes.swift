//
//  File.swift
//  PetalCore
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import Foundation

public struct MLXToolCall: Codable {
    public let name: MLXToolCallType
    public let parameters: MLXToolCallArguments

    enum CodingKeys: String, CodingKey {
        case name
        case parameters = "arguments" // <- THIS is the fix
    }
}

public enum MLXToolCallType: String, Codable {
    case petalGenericCanvasCoursesTool
}

public enum MLXToolCallArguments: Codable {
    case canvasCourses(CanvasCoursesArguments)
    case unknown

    enum CodingKeys: String, CodingKey {
        case completed
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let completed = try container.decodeIfPresent(Bool.self, forKey: .completed) {
            self = .canvasCourses(CanvasCoursesArguments(completed: completed))
        } else {
            self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .canvasCourses(args):
            try container.encode(args.completed, forKey: .completed)
        case .unknown:
            break
        }
    }
}

public struct CanvasCoursesArguments: Codable {
    public let completed: Bool?
}
