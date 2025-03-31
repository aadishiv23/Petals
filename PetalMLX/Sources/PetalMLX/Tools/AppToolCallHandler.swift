//
//  AppToolCallHandler.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 3/26/25.
//

import Foundation
import PetalCore
import PetalTools

public enum ToolCallError: Error {
    case invalidJSON
    case unknownTool(String)
}

@MainActor
public class AppToolCallHandler {
    /// Singleton instance for simplicity.
    public static let shared = AppToolCallHandler()

    private init() {}

    /// Processes LLM output to see if it contains a tool call.
    /// If so, decodes the JSON and dispatches to a registered tool handler.
    public func processLLMOutput(_ text: String) async throws -> String {
        // For simplicity, if the text doesn’t start with “{”, assume no tool call.
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).first == "{" else {
            return text
        }

        guard let data = text.data(using: .utf8) else {
            throw ToolCallError.invalidJSON
        }

        struct ToolCall: Codable {
            let name: String
            let arguments: [String: String]?
        }

        let toolCall = try JSONDecoder().decode(ToolCall.self, from: data)

        
        // Look up the handler in the tool registry (accessing registry is safe from @MainActor)
        guard let handler = PetalMLXToolRegistry.shared.handler(for: toolCall.name) else {
            throw ToolCallError.unknownTool(toolCall.name)
        }

        // --- CHANGE: Execute the handler in a detached Task ---
        // This ensures the potentially long-running 'handle' method
        // does not block the main thread and satisfies concurrency checks,
        // assuming MLXToolHandling requires Sendable.
        let result = try await Task { // Runs on a background thread pool
            try await handler.handle(json: data)
        }.value // .value unwraps the result or rethrows the error from the Task

        return result
        // --- END CHANGE ---
    }
}
