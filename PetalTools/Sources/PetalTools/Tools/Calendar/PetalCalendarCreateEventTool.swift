//
//  PetalCalendarCreateEventTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/11/25.
//

import Foundation
import SwiftUI
import EventKit

public final class PetalCalendarCreateEventTool: OllamaCompatibleTool {
    
    public init() {}
    
    // MARK: - Ollama Tool Definition
    
    public func asOllamaTool() -> OllamaTool {
        // NOTE: Using a minimal approach here—no "items" or "properties" in OllamaFunctionProperty.
        return OllamaTool(
            type: "function",
            function: OllamaFunction(
                name: id,
                description: description,
                parameters: OllamaFunctionParameters(
                    type: "object",
                    properties: [
                        "title": OllamaFunctionProperty(
                            type: "string",
                            description: "The title of the event."
                        ),
                        "startDate": OllamaFunctionProperty(
                            type: "string",
                            description: "ISO date string for the event start time."
                        ),
                        "endDate": OllamaFunctionProperty(
                            type: "string",
                            description: "ISO date string for the event end time."
                        ),
                        "calendarName": OllamaFunctionProperty(
                            type: "string",
                            description: "Name of the calendar to create the event in."
                        ),
                        "location": OllamaFunctionProperty(
                            type: "string",
                            description: "Location of the event."
                        ),
                        "notes": OllamaFunctionProperty(
                            type: "string",
                            description: "Notes or description for the event."
                        ),
                        "url": OllamaFunctionProperty(
                            type: "string",
                            description: "URL associated with the event."
                        ),
                        "isAllDay": OllamaFunctionProperty(
                            type: "boolean",
                            description: "Whether this is an all-day event."
                        ),
                        "availability": OllamaFunctionProperty(
                            type: "string",
                            description: "Availability status (busy, free, tentative, unavailable)."
                        ),
                        "alarms": OllamaFunctionProperty(
                            type: "array",
                            description: "Array of minutes before the event to set alarms."
                        ),
                        "recurrence": OllamaFunctionProperty(
                            type: "object",
                            description: "Recurrence rules for the event."
                        )
                    ],
                    required: ["title", "startDate", "endDate"]
                )
            )
        )
    }
    
    // MARK: - OllamaCompatibleTool Protocol
    
    public let uuid: UUID = .init()
    public var id: String { "petalCalendarCreateEventTool" }
    public var name: String { "Petal Calendar Create Event Tool" }
    public var description: String { "Creates a new calendar event with specified properties." }
    public var triggerKeywords: [String] { ["calendar", "create", "event"] }
    public var domain: String { "calendar" }
    public var requiredPermission: PetalToolPermission { .basic }

    // MARK: - Parameter Definitions

    public var parameters: [PetalToolParameter] {
        [
            PetalToolParameter(
                name: "title",
                description: "The title of the event.",
                dataType: .string,
                required: true,
                example: AnyCodable("Team Meeting")
            ),
            PetalToolParameter(
                name: "startDate",
                description: "ISO date string for the event start time.",
                dataType: .string,
                required: true,
                example: AnyCodable("2025-03-20T10:00:00Z")
            ),
            PetalToolParameter(
                name: "endDate",
                description: "ISO date string for the event end time.",
                dataType: .string,
                required: true,
                example: AnyCodable("2025-03-20T11:00:00Z")
            ),
            PetalToolParameter(
                name: "calendarName",
                description: "Name of the calendar to create the event in (uses default if not specified).",
                dataType: .string,
                required: false,
                example: AnyCodable("Work")
            ),
            PetalToolParameter(
                name: "location",
                description: "Location of the event.",
                dataType: .string,
                required: false,
                example: AnyCodable("Conference Room A")
            ),
            PetalToolParameter(
                name: "notes",
                description: "Notes or description for the event.",
                dataType: .string,
                required: false,
                example: AnyCodable("Discuss quarterly goals")
            ),
            PetalToolParameter(
                name: "url",
                description: "URL associated with the event (e.g., meeting link).",
                dataType: .string,
                required: false,
                example: AnyCodable("https://meet.example.com/meeting")
            ),
            PetalToolParameter(
                name: "isAllDay",
                description: "Whether this is an all-day event.",
                dataType: .boolean,
                required: false,
                example: AnyCodable(false)
            ),
            PetalToolParameter(
                name: "availability",
                description: "Availability status (busy, free, tentative, unavailable).",
                dataType: .string,
                required: false,
                example: AnyCodable("busy")
            ),
            PetalToolParameter(
                name: "alarms",
                description: "Array of minutes before the event to set alarms.",
                dataType: .array,
                required: false,
                example: AnyCodable([0, 15])
            ),
            PetalToolParameter(
                name: "recurrence",
                description: "Recurrence rules for the event.",
                dataType: .object,
                required: false,
                example: AnyCodable([
                    "frequency": "weekly",
                    "interval": 1,
                    "occurrences": 10
                ])
            )
        ]
    }

    // MARK: - Execution Logic

    public struct Input: Codable {
        public let title: String
        public let startDate: String
        public let endDate: String
        public let calendarName: String?
        public let location: String?
        public let notes: String?
        public let url: String?
        public let isAllDay: Bool?
        public let availability: String?
        public let alarms: [Int]?
        public let recurrence: Recurrence?
    }

    public struct Recurrence: Codable {
        public let frequency: String
        public let interval: Int?
        public let endDate: String?
        public let occurrences: Int?
    }

    public struct Output: Codable {
        public let event: String
    }

    public func execute(_ input: Input) async throws -> Output {
        let eventStore = EKEventStore()
        try await requestCalendarAccess(eventStore: eventStore)

        let event = EKEvent(eventStore: eventStore)
        event.title = input.title

        let isoFormatter = ISO8601DateFormatter()
        guard
            let start = isoFormatter.date(from: input.startDate),
            let end = isoFormatter.date(from: input.endDate)
        else {
            throw NSError(
                domain: "CalendarError",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid date format."]
            )
        }
        event.startDate = start
        event.endDate = end

        // Choose calendar
        if let calName = input.calendarName?.lowercased(),
           let foundCal = eventStore.calendars(for: .event)
               .first(where: { $0.title.lowercased() == calName })
        {
            event.calendar = foundCal
        } else if let defaultCal = eventStore.defaultCalendarForNewEvents {
            event.calendar = defaultCal
        } else {
            throw NSError(
                domain: "CalendarError",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "No available calendar. Please select one."]
            )
        }

        // Optional fields
        event.location = input.location
        event.notes = input.notes
        if let urlString = input.url, let parsedURL = URL(string: urlString) {
            event.url = parsedURL
        }
        if let isAllDay = input.isAllDay {
            event.isAllDay = isAllDay
        }
        if let availability = input.availability {
            event.availability = EKEventAvailability(availability)
        }
        if let alarms = input.alarms {
            event.alarms = alarms.map { EKAlarm(relativeOffset: -TimeInterval($0 * 60)) }
        }

        // Recurrence
        if let rec = input.recurrence {
            let freq = EKRecurrenceFrequency(rec.frequency)
            let interval = rec.interval ?? 1
            let end: EKRecurrenceEnd? = {
                if let endDateStr = rec.endDate, let parsedEnd = isoFormatter.date(from: endDateStr) {
                    return EKRecurrenceEnd(end: parsedEnd)
                } else if let occurrences = rec.occurrences {
                    return EKRecurrenceEnd(occurrenceCount: occurrences)
                }
                return nil
            }()
            let rule = EKRecurrenceRule(recurrenceWith: freq, interval: interval, end: end)
            event.recurrenceRules = [rule]
        }

        // Save event
        try eventStore.save(event, span: .thisEvent)

        let confirmation = "Event '\(event.title ?? "Untitled")' scheduled from \(input.startDate) to \(input.endDate)."
        return Output(event: confirmation)
    }

    // MARK: - Permissions

    private func requestCalendarAccess(eventStore: EKEventStore) async throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            let granted = try await eventStore.requestAccess(to: .event)
            if !granted {
                throw NSError(domain: "CalendarError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access denied"])
            }
        case .denied, .restricted:
            throw NSError(domain: "CalendarError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access denied"])
        case .authorized, .fullAccess:
            return
        case .writeOnly:
            throw NSError(domain: "CalendarError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Write-only access is insufficient."])

        @unknown default:
            throw NSError(domain: "CalendarError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown authorization status"])
        }
    }
}

// MARK: - Availability / Recurrence Extensions

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

extension EKRecurrenceFrequency {
    fileprivate init(_ string: String) {
        switch string.lowercased() {
        case "daily": self = .daily
        case "weekly": self = .weekly
        case "monthly": self = .monthly
        case "yearly": self = .yearly
        default: self = .daily
        }
    }
}
