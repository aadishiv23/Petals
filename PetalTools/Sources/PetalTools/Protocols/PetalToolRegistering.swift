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
    public func registerTool(_ tool: PetalTool)
    
    /// Retrieves all registered tools
    public func getAllTools() -> [PetalTool]
    
    /// Retrieves all registered tools matching given criteria.
    public func getTools(matching criteria: PetalToolFilterCriteria) -> [PetalTool]
}
