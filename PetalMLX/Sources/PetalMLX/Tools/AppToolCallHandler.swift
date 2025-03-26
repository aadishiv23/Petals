//
//  AppToolCallHandler.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 3/26/25.
//

import Foundation

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

        // Look up the handler in the tool registry.
        if let handler = PetalToolRegistry.shared.handler(for: toolCall.name) {
            return try await handler.handle(json: data)
        } else {
            throw ToolCallError.unknownTool(toolCall.name)
        }
    }
}
