//
//  PetalTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/10/25.
//

import Foundation

/// A generic protocol used to represent a tool used by Petals (Ollama, Gemini, etc...)
public protocol PetalTool: Sendable {

    /// A unique internal UUID for strict identification.
    var uuid: UUID { get }

    /// A unique human-readable identifier for easy debugging.
    var id: String { get }

    /// A human-readable name for the tool.
    var name: String { get }

    /// A description of what the tool does.
    var description: String { get }

    // TODO: Implement ToolParameter.
    /// Parameters accepted by the tool (for AI tool execution).
    var parameters: [PetalToolParameter] { get }

    /// Keywords that might trigger this tool (used by AI models).
    var triggerKeywords: [String] { get }

    /// Domain this tool belongs to (e.g., "calendar", "education", "productivity").
    var domain: String { get }

    // TODO: Implement ToolPermission.
    /// Permission level required to use this tool (security & access control).
    var requiredPermission: PetalToolPermission { get }

    /// Defines the input type required for execution.
    associatedtype Input: Codable

    /// Defines the output type returned after execution.
    associatedtype Output: Codable

    /// Executes the tool with the given input and returns an output.
    func execute(_ input: Input) async throws -> Output
}
