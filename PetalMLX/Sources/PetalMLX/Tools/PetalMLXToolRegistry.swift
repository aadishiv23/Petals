//
//  PetalMLXToolRegistry.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 3/26/25.
//

import Foundation

/// A simple registry to hold tool handlers.
public class PetalMLXToolRegistry {

    @MainActor public static let shared = PetalMLXToolRegistry()
    
    private var handlers: [String: any MLXToolHandling] = [:]
    
    public init() { }
    
    /// Register a tool handler.
    public func registerHandler(toolName: String, handler: any MLXToolHandling) {
        handlers[toolName] = handler
    }
    
    /// Retrieve a tool handler for a given tool name.
    public func handler(for toolName: String) -> (any MLXToolHandling)? {
        return handlers[toolName]
    }
    
    /// Returns a list of MLX tool definitions.
    /// (Custom/hybrid implementation)
    /// TODO: Better description and name.
    public static func mlxTools() async -> [[String: any Sendable]] {
        return [
            ["name": "calendarTool", "description": "Fetch or create calendar events"],
            ["name": "canvasCoursesTool", "description": "Retrieve Canvas courses"],
            ["name": "canvasAssignmentsTool", "description": "Retrieve Canvas assignments"],
            ["name": "canvasGradesTool", "description": "Retrieve Canvas grades"],
            ["name": "remindersTool", "description": "Retrieve reminders"]
        ]
    }
}
