//
//  ToolRegistry.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/25/25.
//

import Foundation

enum ToolRegistry {
    static let tools: [OllamaTool] = [
        OllamaTool(
            type: "function",
            function: OllamaFunction(
                name: "fetchCalendarEvents",
                description: "Fetches calendar events for a particular date.",
                parameters: OllamaFunctionParameters(
                    type: "object",
                    properties: [
                        "date": OllamaFunctionProperty(type: "string",
                                                       description: "The date for which to fetch events (YYYY-MM-DD).")
                    ],
                    required: ["date"]
                )
            )
        )
    ]

    /// Gets the tool by name (useful for backend calls)
    static func getTool(by name: String) -> OllamaTool? {
        tools.first { $0.function.name == name }
    }
}
