//
//  ToolRegistering.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/10/25.
//

import Foundation

// MARK: A protocol to represent any `ToolRegistry` instances.
public protocol PetalToolRegistering {
    
    // TODO: Create a generic TOOL protocol to wrap Gemini/Ollama tools under one
    /// Registers a tool with the registry.
    func registerTool(_ tool: any PetalTool) async
    
    /// Retrieves all registered tools
    func getAllTools() async -> [any PetalTool]
    
    /// Retrieves all registered tools matching given criteria.
    func getTools(matching criteria: PetalToolFilterCriteria) async -> [any PetalTool]
}
