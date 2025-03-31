//
//  File.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/11/25.
//

import Foundation
import PetalCore

/// Concrete implementation of `PetalToolRegistry`
public actor PetalToolRegistry: PetalToolRegistering {

    /// Singleton instance.
    public static let shared = PetalToolRegistry()

    /// The list of tools registered.
    private var tools: [String: any PetalTool] = [:]

    /// Tracks whether tools have been registered.
    private var isInitialized = false

    /// Private initializer for singleton.
    private init() {}

    /// Ensures tools are registered before usage.
    private func ensureInitialized() async {
        if !isInitialized {
            await registerDefaultTools()
            print("true")
            isInitialized = true
        }
    }

    /// Registers a `PetalTool` within the registry.
    public func registerTool(_ tool: any PetalTool) async {
        tools[tool.id] = tool
    }

    /// Registers default tools **if not already registered**.
    private func registerDefaultTools() async {
        let calendarTool = await PetalToolFactory.createCalendarTool()
        let getCanvasCoursesTool = await PetalToolFactory.createFetchCanvasCoursesTool()
        let fetchCanvasAssignmentsTool = await PetalToolFactory.createFetchCanvasAssignmentsTool()
        let fetchCanvasGradesTool = await PetalToolFactory.createFetchCanvasGradesTool()
        let calendarCreateEventTool = await PetalToolFactory.createCalendarCreateEventTool()
        let calendarFetchEventTool = await PetalToolFactory.createCalendarFetchEventTool()
        let fetchRemindersTool = await PetalToolFactory.createFetchRemindersTool()
        await registerTool(calendarTool)
        await registerTool(getCanvasCoursesTool)
        await registerTool(fetchCanvasAssignmentsTool)
        await registerTool(fetchCanvasGradesTool)
        await registerTool(calendarCreateEventTool)
        await registerTool(calendarFetchEventTool)
        await registerTool(fetchRemindersTool)
        isInitialized = true
    }

    /// Retrieves all `PetalTool`s that are registered **after ensuring initialization**.
    public func getAllTools() async -> [any PetalTool] {
        await ensureInitialized()
        return Array(tools.values)
    }

    /// Retrieves a tool by its ID.
    public func getTool(id: String) async -> (any PetalTool)? {
        await ensureInitialized()
        return tools[id]
    }
    
    /// Retrieves all registered tools matching given criteria.
    public func getTools(matching criteria: PetalToolFilterCriteria) async -> [any PetalTool] {
        var filteredTools = Array(tools.values)

        if let domain = criteria.domain {
            filteredTools = filteredTools.filter { $0.domain.lowercased() == domain.lowercased() }
        }

        if let keyword = criteria.keyword {
            filteredTools = filteredTools.filter { tool in
                tool.triggerKeywords.contains { $0.lowercased().contains(keyword.lowercased()) }
            }
        }

        if let maxPermission = criteria.maxPermissionLevel {
            filteredTools = filteredTools.filter { $0.requiredPermission <= maxPermission }
        }

        return filteredTools
    }

    /// Retrieves tools in **Ollama API format** after ensuring initialization.
    public static func ollamaTools() async -> [OllamaTool] {
        await shared.ensureInitialized()
        return await shared.getAllTools().compactMap { tool in
            (tool as? (any OllamaCompatibleTool))?.asOllamaTool()
        }
    }
}
