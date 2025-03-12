//
//  File.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/11/25.
//

import Foundation

/// Concrete implementation of `PetalToolRegistry`
public actor PetalToolRegistry: PetalToolRegistering {

    /// Singleton instance.
    public static let shared = PetalToolRegistry()

    /// The list of tools registered.
    private var tools: [any PetalTool] = []

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
        if let index = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[index] = tool
        } else {
            tools.append(tool)
        }
    }

    /// Registers default tools **if not already registered**.
    private func registerDefaultTools() async {
        let calendarTool = await PetalToolFactory.createCalendarTool()
        let canvasTool = await PetalToolFactory.createFetchCanvasCoursesTool()
        await registerTool(calendarTool)
        await registerTool(canvasTool)
        isInitialized = true
    }

    /// Retrieves all `PetalTool`s that are registered **after ensuring initialization**.
    public func getAllTools() async -> [any PetalTool] {
        await ensureInitialized()
        return tools
    }
    
    /// Retrieves all registered tools matching given criteria.
    public func getTools(matching criteria: PetalToolFilterCriteria) async -> [any PetalTool] {
        var filteredTools = tools

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
