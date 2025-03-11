//
//  File.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/11/25.
//

import Foundation

/// Concrete implementation of `PetalToolRegistry`
public class PetalToolRegistry: PetalToolRegistering {

    /// Singleton instance.
    public static let shared = PetalToolRegistry()

    /// The list of tools registered.
    let tools: [PetalTool] = []

    /// Private initializer for singleton.
    private init() {}

    /// Registers a `PetalTool` within the registry.
    public func registerTool(_ tool: any PetalTool) {
        if let index = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[index] = tool
        } else {
            tools.append(tool)
        }
    }

    /// Retrieves all `PetalTool`'s that are registed.
    public func getAllTools() -> [any PetalTool] {
        tools
    }

    /// Retrieves all registered tools matching given criteria.
    public func getTools(matching criteria: PetalToolFilterCriteria) -> [any PetalTool] {
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

    /// Tools available for use in Ollama API format.
    public static var ollamaTools: [OllamaTool] {
        shared.getAllTools().compactMap { tool in
            (tool as? OllamaCompatibleTool)?.asOllamaTool()
        }
    }
}
