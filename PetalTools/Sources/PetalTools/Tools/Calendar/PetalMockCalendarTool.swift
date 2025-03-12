//
//  File.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/11/25.
//

import Foundation

/// A tool to interface with a mock calendar tool.
public final class PetalMockCalendarTool: OllamaCompatibleTool {

    public let uuid: UUID = UUID()
    
    public var id: String { "petalMockCalendarTool" }
    
    public var name: String { "Petal Mock Calendar Tool" }
    
    public var description: String { "Fetches mock calendar events given a date" }
    
    public var parameters: [PetalToolParameter] {
        [PetalToolParameter(
            name: "date",
            description: "The date (YYYY-MM-DD) for which to fetch events.",
            dataType: .string,
            required: true,
            example: AnyCodable("2025-02-24")
        )]
    }
    
    public let triggerKeywords: [String] = ["calendar", "events", "date"]
    
    public var domain: String { "productivity" }
    
    public var requiredPermission: PetalToolPermission { .basic }
    
    /// Define the input and output types
    public struct Input: Codable {
        let date: String
    }

    public struct Output: Codable {
        let events: [String]
    }

    /// Implements the `execute` function required by `PetalTool`
    public func execute(_ input: Input) async throws -> Output {
        return Output(events: fetchCalendarEvents(date: input.date))
    }
    
    public func asOllamaTool() -> OllamaTool {
        return OllamaTool(
            type: "function",
            function: OllamaFunction(
                name: id,
                description: description,
                parameters: OllamaFunctionParameters(
                    type: "object",
                    properties: [
                        "date": OllamaFunctionProperty(
                            type: "string",
                            description: "The date (YYYY-MM-DD) for which to fetch events."
                        )
                    ],
                    required: ["date"]
                )
            )
        )
    }


    /// Private helper function to mock calendar events
    private func fetchCalendarEvents(date: String) -> [String] {
        switch date {
        case "2025-02-24":
            return ["Gym with Michael"]
        case "2025-02-25":
            return ["Lunch with Nandan"]
        case "2025-02-26":
            return ["No events"]
        default:
            return ["No events scheduled"]
        }
    }

    init() {
        
    }
}
