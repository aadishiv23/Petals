//
//  PetalMLXToolRegistry.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 3/26/25.
//

import Foundation
import PetalTools
import PetalCore

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
    
    /// Returns a list of MLX-compatible tool definitions (i.e. the actual tool objects).
    public static func mlxTools() async -> [any MLXCompatibleTool] {
        let canvasCoursesTool = PetalGenericFetchCanvasCoursesTool()
        let canvasAssignmentsTool = PetalFetchCanvasAssignmentsTool()
        let canvasGradesTool = PetalFetchCanvasGradesTool()
        let calendarCreateEventTool = PetalCalendarCreateEventTool()
        let calendarFetchEventsTool = PetalCalendarFetchEventsTool()
        let remindersTool = PetalFetchRemindersTool()

        var tools: [any MLXCompatibleTool] = [
            canvasCoursesTool,
            canvasAssignmentsTool,
            canvasGradesTool,
            calendarCreateEventTool,
            calendarFetchEventsTool,
            remindersTool
        ]

        #if os(macOS)
        let notesTool = PetalNotesTool()
        tools.append(notesTool)
        #endif

        return tools
    }

}
