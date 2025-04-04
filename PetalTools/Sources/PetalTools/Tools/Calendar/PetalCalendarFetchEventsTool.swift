//
//  PetalCalendarFetchEventsTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/11/25.
//

import Foundation
import SwiftUI
import EventKit
import PetalCore

/// A tool to fetch calendar events with flexible filtering options.
public final class PetalCalendarFetchEventsTool: OllamaCompatibleTool, MLXCompatibleTool {
    
    public init() {}
    
    public let uuid: UUID = .init()
    public var id: String { "petalCalendarFetchEventsTool" }
    public var name: String { "Petal Calendar Fetch Events Tool" }
    public var description: String { "Fetches calendar events with flexible filtering options." }
    
    public var triggerKeywords: [String] {  ["events", "fetch"] }
    public var domain: String { "calendar" }
    public var requiredPermission: PetalToolPermission { .basic }
    
    /// Define the parameters for this tool.
    public var parameters: [PetalToolParameter] {
        return [
            PetalToolParameter(
                name: "startDate",
                description: "ISO date string for the start of the date range (defaults to now if not specified)",
                dataType: .string,
                required: false,
                example: AnyCodable("2025-03-15T00:00:00Z")
            ),
            PetalToolParameter(
                name: "endDate",
                description: "ISO date string for the end of the date range (defaults to one week from start if not specified)",
                dataType: .string,
                required: false,
                example: AnyCodable("2025-03-22T00:00:00Z")
            ),
            PetalToolParameter(
                name: "calendarNames",
                description: "Names of calendars to fetch from. If empty or not specified, fetches from all calendars.",
                dataType: .array,
                required: false,
                example: AnyCodable(["Work", "Personal"])
            ),
            PetalToolParameter(
                name: "searchText",
                description: "Text to search for in event titles and locations",
                dataType: .string,
                required: false,
                example: AnyCodable("Meeting")
            ),
            PetalToolParameter(
                name: "includeAllDay",
                description: "Whether to include all-day events",
                dataType: .boolean,
                required: false,
                example: AnyCodable(true)
            ),
            PetalToolParameter(
                name: "status",
                description: "Filter by event status (none, tentative, confirmed, canceled)",
                dataType: .string,
                required: false,
                example: AnyCodable("confirmed")
            ),
            PetalToolParameter(
                name: "availability",
                description: "Filter by availability status (busy, free, tentative, unavailable)",
                dataType: .string,
                required: false,
                example: AnyCodable("busy")
            ),
            PetalToolParameter(
                name: "hasAlarms",
                description: "Filter for events that have alarms/reminders set",
                dataType: .boolean,
                required: false,
                example: AnyCodable(true)
            ),
            PetalToolParameter(
                name: "isRecurring",
                description: "Filter for recurring events",
                dataType: .boolean,
                required: false,
                example: AnyCodable(false)
            )
        ]
    }
    
    /// Input parameters for fetching events.
    public struct Input: Codable {
        public let startDate: String?
        public let endDate: String?
        public let calendarNames: [String]?
        public let searchText: String?
        public let includeAllDay: Bool?
        public let status: String?
        public let availability: String?
        public let hasAlarms: Bool?
        public let isRecurring: Bool?
    }
    
    /// Output containing a formatted list of events.
    public struct Output: Codable, Sendable {
        public let events: String
    }
    
    /// Executes the tool by fetching calendar events based on the provided input.
    ///
    /// - Parameter input: An `Input` struct containing filtering options.
    /// - Returns: An `Output` struct with a string listing of the events.
    public func execute(_ input: Input) async throws -> Output {
        let eventStore = EKEventStore()
        
        // Request access to the calendar if not already authorized.
        if EKEventStore.authorizationStatus(for: .event) != .authorized {
            try await eventStore.requestAccess(to: .event)
        }
        
        let isoFormatter = ISO8601DateFormatter()
        let now = Date()
        var startDate = now
        var endDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: now)!
        
        if let startStr = input.startDate, let parsed = isoFormatter.date(from: startStr) {
            startDate = parsed
        }
        if let endStr = input.endDate, let parsed = isoFormatter.date(from: endStr) {
            endDate = parsed
        }
        
        // Filter calendars if specific names are provided.
        var calendars = eventStore.calendars(for: .event)
        if let names = input.calendarNames, !names.isEmpty {
            let lowercasedNames = Set(names.map { $0.lowercased() })
            calendars = calendars.filter { lowercasedNames.contains($0.title.lowercased()) }
        }
        
        // Create predicate for events within the given date range.
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        var events = eventStore.events(matching: predicate)
        
        // Apply additional filters.
        if let includeAllDay = input.includeAllDay, includeAllDay == false {
            events = events.filter { !$0.isAllDay }
        }
        
        if let search = input.searchText, !search.isEmpty {
            events = events.filter {
                ($0.title?.localizedCaseInsensitiveContains(search) ?? false)
                || ($0.location?.localizedCaseInsensitiveContains(search) ?? false)
            }
        }
        
        if let statusStr = input.status {
            let statusValue = EKEventStatus(statusStr)
            events = events.filter { $0.status == statusValue }
        }
        
        if let availabilityStr = input.availability {
            let availValue = EKEventAvailability(availabilityStr)
            events = events.filter { $0.availability == availValue }
        }
        
        if let hasAlarms = input.hasAlarms {
            events = events.filter { $0.hasAlarms == hasAlarms }
        }
        
        if let isRecurring = input.isRecurring {
            events = events.filter { $0.hasRecurrenceRules == isRecurring }
        }
        
        // Format the events into a readable string.
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        let eventList = events.map { event in
            let title = event.title ?? "Untitled Event"
            let startStr = dateFormatter.string(from: event.startDate)
            let location = event.location ?? ""
            return "• \(title) @ \(startStr)" + (location.isEmpty ? "" : " - \(location)")
        }.joined(separator: "\n")
        
        let eventsOutput = eventList.isEmpty ? "No events found for the specified criteria." : eventList
        return Output(events: eventsOutput)
    }
    
    /// Converts this tool into an Ollama-compatible tool representation.
    public func asOllamaTool() -> OllamaTool {
        return OllamaTool(
            type: "function",
            function: OllamaFunction(
                name: "petalCalendarFetchEventsTool",
                description: "Fetches calendar events with flexible filtering options.",
                parameters: OllamaFunctionParameters(
                    type: "object",
                    properties: [
                        "startDate": OllamaFunctionProperty(
                            type: "string",
                            description: "ISO date string for the start of the date range."
                        ),
                        "endDate": OllamaFunctionProperty(
                            type: "string",
                            description: "ISO date string for the end of the date range."
                        ),
                        "calendarNames": OllamaFunctionProperty(
                            type: "array",
                            description: "List of calendar names to fetch events from."
                        ),
                        "searchText": OllamaFunctionProperty(
                            type: "string",
                            description: "Text to search in event titles and locations."
                        ),
                        "includeAllDay": OllamaFunctionProperty(
                            type: "boolean",
                            description: "Whether to include all-day events."
                        ),
                        "status": OllamaFunctionProperty(
                            type: "string",
                            description: "Filter by event status (none, tentative, confirmed, canceled)."
                        ),
                        "availability": OllamaFunctionProperty(
                            type: "string",
                            description: "Filter by availability status (busy, free, tentative, unavailable)."
                        ),
                        "hasAlarms": OllamaFunctionProperty(
                            type: "boolean",
                            description: "Filter for events that have alarms/reminders set."
                        ),
                        "isRecurring": OllamaFunctionProperty(
                            type: "boolean",
                            description: "Filter for recurring events."
                        )
                    ],
                    required: []
                )
            )
        )
    }
    
    // MARK: - MLX-Compatible
    
    public func asMLXToolDefinition() -> MLXToolDefinition {
        return MLXToolDefinition(
            type: "function",
            function: MLXFunctionDefinition(
                name: "petalCalendarFetchEventsTool",
                description: "Fetches calendar events with flexible filtering options.",
                parameters: MLXParametersDefinition(
                    type: "object",
                    properties: [
                        "startDate": MLXParameterProperty(
                            type: "string",
                            description: "ISO date string for the start of the date range."
                        ),
                        "endDate": MLXParameterProperty(
                            type: "string",
                            description: "ISO date string for the end of the date range."
                        ),
                        "calendarNames": MLXParameterProperty(
                            type: "array",
                            description: "List of calendar names to fetch events from."
                        ),
                        "searchText": MLXParameterProperty(
                            type: "string",
                            description: "Text to search in event titles and locations."
                        ),
                        "includeAllDay": MLXParameterProperty(
                            type: "boolean",
                            description: "Whether to include all-day events."
                        ),
                        "status": MLXParameterProperty(
                            type: "string",
                            description: "Filter by event status (none, tentative, confirmed, canceled)."
                        ),
                        "availability": MLXParameterProperty(
                            type: "string",
                            description: "Filter by availability status (busy, free, tentative, unavailable)."
                        ),
                        "hasAlarms": MLXParameterProperty(
                            type: "boolean",
                            description: "Filter for events that have alarms/reminders set."
                        ),
                        "isRecurring": MLXParameterProperty(
                            type: "boolean",
                            description: "Filter for recurring events."
                        )
                    ],
                    required: []
                )
            )
        )
    }
}

/// Extension to initialize EKEventStatus from a string.
extension EKEventStatus {
    fileprivate init(_ string: String) {
        switch string.lowercased() {
        case "none": self = .none
        case "tentative": self = .tentative
        case "confirmed": self = .confirmed
        case "canceled": self = .canceled
        default: self = .none
        }
    }
}

/// Extension to initialize EKEventAvailability from a string.
extension EKEventAvailability {
    fileprivate init(_ string: String) {
        switch string.lowercased() {
        case "busy": self = .busy
        case "free": self = .free
        case "tentative": self = .tentative
        case "unavailable": self = .unavailable
        default: self = .busy
        }
    }
}
