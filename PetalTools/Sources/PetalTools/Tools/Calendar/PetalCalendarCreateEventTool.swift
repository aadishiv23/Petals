//
//  PetalCalendarCreateEventTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/11/25.
//
//  This version uses FLEXIBLE date parsing to handle various common formats.
//

import EventKit
import Foundation
import PetalCore // Make sure PetalCore contains necessary definitions like PetalToolError if used
import SwiftUI // If used for Logger, otherwise can be removed

public final class PetalCalendarCreateEventTool: OllamaCompatibleTool, MLXCompatibleTool {

    public init() {}

    // MARK: - Ollama Tool Definition

    public func asOllamaTool() -> OllamaTool {
        OllamaTool(
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
                            description: "Date/time string (e.g., ISO 8601, YYYY-MM-DD HH:mm:ss, YYYY-MM-DD) for the event start time." // Flexible description
                        ),
                        "endDate": OllamaFunctionProperty(
                            type: "string",
                            description: "Date/time string (e.g., ISO 8601, YYYY-MM-DD HH:mm:ss, YYYY-MM-DD) for the event end time." // Flexible description
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
                description: "Date/time string (e.g., ISO 8601, YYYY-MM-DD HH:mm:ss, YYYY-MM-DD) for the event start time.", // Flexible description
                dataType: .string,
                required: true,
                example: AnyCodable("2025-03-20T10:00:00Z")
            ),
            PetalToolParameter(
                name: "endDate",
                description: "Date/time string (e.g., ISO 8601, YYYY-MM-DD HH:mm:ss, YYYY-MM-DD) for the event end time.", // Flexible description
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
        public let frequency: String // e.g., "daily", "weekly"
        public let interval: Int?    // e.g., 1 for every week, 2 for every other week
        public let endDate: String?  // Date string (needs flexible parsing too)
        public let occurrences: Int? // Number of times
        // Add support for daysOfWeek, daysOfMonth etc. if needed later
    }

    public struct Output: Codable, Sendable {
        public let event: String // Confirmation message
    }

    public func execute(_ input: Input) async throws -> Output {
        let eventStore = EKEventStore()
        // Request permission using the helper function
        try await requestCalendarAccess(eventStore: eventStore)

        let event = EKEvent(eventStore: eventStore)
        event.title = input.title

        // --- Flexible Date Parsing Logic ---
        // Use the helper function defined below
        guard let start = parseFlexibleDateString(input.startDate) else {
            print("ERROR: Failed to parse start date: \(input.startDate)")
            throw PetalToolError.invalidDateFormat(input.startDate)
        }

        guard let end = parseFlexibleDateString(input.endDate, isEndDate: true) else {
             print("ERROR: Failed to parse end date: \(input.endDate)")
            throw PetalToolError.invalidDateFormat(input.endDate)
        }

        // Ensure end date is after start date
        guard end > start else {
            let errorMsg = "End date (\(end)) must be after start date (\(start))."
            print("ERROR: \(errorMsg)")
            throw PetalToolError.invalidDateLogic(errorMsg)
        }

        event.startDate = start
        event.endDate = end
        print("INFO: Successfully parsed dates - Start: \(start), End: \(end)")
        // --- End of Flexible Date Parsing ---


        // Choose calendar
        if let calName = input.calendarName?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !calName.isEmpty,
           let foundCal = eventStore.calendars(for: .event)
           .first(where: { $0.title.lowercased() == calName })
        {
            event.calendar = foundCal
            print("INFO: Found and selected calendar: \(foundCal.title)")
        } else if let defaultCal = eventStore.defaultCalendarForNewEvents {
            event.calendar = defaultCal
             print("INFO: Calendar '\(input.calendarName ?? "Not Specified")' not found or not provided. Using default calendar: \(defaultCal.title)")
        } else {
             print("ERROR: No default calendar available and requested calendar not found.")
            throw PetalToolError.internalError("No default calendar found and specified calendar was invalid or not provided.")
        }

        // Optional fields
        event.location = input.location?.trimmingCharacters(in: .whitespacesAndNewlines)
        event.notes = input.notes
        if let urlString = input.url, let parsedURL = URL(string: urlString) {
            event.url = parsedURL
        }
        // Handle allDay before setting availability, as it might affect it
        if let isAllDay = input.isAllDay {
            event.isAllDay = isAllDay
            if isAllDay {
                // All-day events typically span from start of start day to start of day after end day
                event.startDate = Calendar.current.startOfDay(for: start)
                // To make an all-day event span one full day from a date-only input:
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: event.startDate) ?? end
                event.endDate = Calendar.current.startOfDay(for: endOfDay)
                print("INFO: Adjusted dates for all-day event: \(event.startDate!) to \(event.endDate!)")
            }
        }
        if let availability = input.availability {
            event.availability = EKEventAvailability(availability) // Assumes extension exists
        }
        if let alarms = input.alarms {
            // Ensure alarms are non-negative offsets
            event.alarms = alarms.filter { $0 >= 0 }.map { EKAlarm(relativeOffset: -TimeInterval($0 * 60)) }
        }

        // Recurrence
        if let rec = input.recurrence {
            let freq = EKRecurrenceFrequency(rec.frequency) // Assumes extension exists
            let interval = rec.interval ?? 1
            let endRecurrence: EKRecurrenceEnd? = {
                // Use flexible parsing for the recurrence end date too
                if let endDateStr = rec.endDate, let parsedEnd = parseFlexibleDateString(endDateStr, isEndDate: true) {
                    // Recurrence end date should generally be inclusive
                    return EKRecurrenceEnd(end: parsedEnd)
                } else if let occurrences = rec.occurrences, occurrences > 0 {
                    return EKRecurrenceEnd(occurrenceCount: occurrences)
                }
                 print("WARN: Could not parse recurrence end date '\(rec.endDate ?? "nil")' or invalid occurrences '\(rec.occurrences ?? -1)'. No recurrence end set.")
                return nil
            }()
            // Ensure interval is positive
            let rule = EKRecurrenceRule(recurrenceWith: freq, interval: max(1, interval), end: endRecurrence)
            event.recurrenceRules = [rule]
             print("INFO: Added recurrence rule: Freq=\(freq), Interval=\(max(1, interval)), End=\(String(describing: endRecurrence))")
        }

        // Save event
        do {
            // For recurring events, .futureEvents is often needed to apply to all instances
            let span: EKSpan = event.hasRecurrenceRules ? .futureEvents : .thisEvent
            try eventStore.save(event, span: span)
            print("INFO: Event '\(event.title ?? "")' saved successfully to calendar '\(event.calendar.title)' with span '\(span == .futureEvents ? "Future Events" : "This Event")'.")
        } catch {
             print("ERROR: Failed to save event: \(error.localizedDescription)")
            throw PetalToolError.eventSaveFailed(error)
        }

        // Use DateFormatter for user-friendly confirmation message
        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateStyle = .medium
        outputDateFormatter.timeStyle = .short
        let startStrFormatted = outputDateFormatter.string(from: event.startDate)
        let endStrFormatted = outputDateFormatter.string(from: event.endDate)

        let confirmation = "OK. Event '\(event.title ?? "Untitled")' scheduled in calendar '\(event.calendar.title)' from \(startStrFormatted) to \(endStrFormatted)."
        return Output(event: confirmation)
    }


    // MARK: - Date Parsing Helper

    /// Attempts to parse a date string using multiple common formats.
    /// - Parameters:
    ///   - dateString: The string potentially containing a date.
    ///   - isEndDate: If true and the format is date-only (YYYY-MM-DD), adjusts the time to the end of that day.
    /// - Returns: A `Date` object if parsing is successful, otherwise `nil`.
    private func parseFlexibleDateString(_ dateString: String, isEndDate: Bool = false) -> Date? {
        let trimmedString = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return nil }

        // Reusable formatters
        let isoFormatter = ISO8601DateFormatter()
        let standardFormatter = DateFormatter()
        standardFormatter.locale = Locale(identifier: "en_US_POSIX") // Crucial for fixed formats

        // 1. Try ISO8601 with Timezone/Fractional Seconds (Most specific)
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: trimmedString) { return date }

        // 2. Try ISO8601 with Timezone (No fractional seconds)
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: trimmedString) { return date }

        // 3. Try "YYYY-MM-DD HH:mm:ss" (Common non-ISO format)
        standardFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = standardFormatter.date(from: trimmedString) { return date }

        // 4. Try "YYYY-MM-DD HH:mm" (Slight variation)
        standardFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        if let date = standardFormatter.date(from: trimmedString) { return date }

        // 5. Try "YYYY-MM-DD" (Date only)
        isoFormatter.formatOptions = [.withFullDate]
        if let date = isoFormatter.date(from: trimmedString) {
            // Adjust time for date-only strings
            if isEndDate {
                // For end dates, go to the very end of the day for inclusiveness
                return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date)
            } else {
                // For start dates, use the beginning of the day
                return Calendar.current.startOfDay(for: date)
            }
        }

        // 6. Add more formats if needed (e.g., "MM/dd/yyyy HH:mm", "MMM d, yyyy h:mm a")
        // standardFormatter.dateFormat = "MM/dd/yyyy HH:mm"
        // if let date = standardFormatter.date(from: trimmedString) { return date }

        print("WARN: Could not parse date string '\(trimmedString)' with any known format.")
        return nil // Failed to parse with any known format
    }


    // MARK: - Permissions

    /// Requests calendar access if not already determined or granted.
    /// Throws a `PetalToolError` if access is denied, restricted, or cannot be obtained.
    private func requestCalendarAccess(eventStore: EKEventStore) async throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            print("INFO: Calendar access not determined. Requesting...")
            // Use requestFullAccessToEvents if targeting iOS 17+, otherwise requestAccess
            let granted: Bool
            if #available(iOS 17.0, macOS 14.0, *) {
                 granted = try await eventStore.requestFullAccessToEvents()
            } else {
                 granted = try await eventStore.requestAccess(to: .event)
            }

            if !granted {
                print("ERROR: Calendar access denied by user during request.")
                throw PetalToolError.permissionDenied
            }
             print("INFO: Calendar access granted after request.")
        case .denied, .restricted:
             print("ERROR: Calendar access is denied or restricted.")
            throw PetalToolError.permissionDenied // Treat restricted same as denied for create
        case .authorized, .fullAccess: // .authorized is deprecated but handle for compatibility
            print("INFO: Calendar access already granted.")
            return
        case .writeOnly:
            // WriteOnly might be sufficient for creating, but reading default cal might fail? Test this.
            // Let's assume it's OK for now, but full access is safer.
             print("WARN: Calendar access is write-only. Proceeding, but might encounter issues reading default calendar.")
             return
        @unknown default:
             print("ERROR: Unknown calendar authorization status encountered.")
            throw PetalToolError.internalError("Unknown calendar authorization status.")
        }
    }

    // MARK: - MLX-Compatible

    public func asMLXToolDefinition() -> MLXToolDefinition {
        return MLXToolDefinition(
            type: "function",
            function: MLXFunctionDefinition(
                name: "petalCalendarCreateEventTool",
                description: "Creates a calendar event with flexible options.",
                parameters: MLXParametersDefinition(
                    type: "object",
                    properties: [
                        "title": MLXParameterProperty(
                            type: "string",
                            description: "The title of the event."
                        ),
                        "startDate": MLXParameterProperty(
                            type: "string",
                            description: "Date/time string (e.g., ISO 8601, YYYY-MM-DD HH:mm:ss, YYYY-MM-DD) for the event start time." // Flexible description
                        ),
                        "endDate": MLXParameterProperty(
                            type: "string",
                            description: "Date/time string (e.g., ISO 8601, YYYY-MM-DD HH:mm:ss, YYYY-MM-DD) for the event end time." // Flexible description
                        ),
                        "calendarName": MLXParameterProperty(
                            type: "string",
                            description: "Name of the calendar to create the event in."
                        ),
                        "location": MLXParameterProperty(
                            type: "string",
                            description: "Location of the event."
                        ),
                        "notes": MLXParameterProperty(
                            type: "string",
                            description: "Notes or description for the event."
                        )
                        // Add other optional parameters here if desired for MLX definition
                    ],
                    required: ["title", "startDate", "endDate"]
                )
            )
        )
    }
}

// MARK: - Availability / Recurrence Extensions

extension EKEventAvailability {
    /// Initializes EKEventAvailability based on a lowercase string representation.
    /// Defaults to `.busy` if the string doesn't match known availabilities.
    fileprivate init(_ string: String) {
        switch string.lowercased() {
        case "busy": self = .busy
        case "free": self = .free
        case "tentative": self = .tentative
        case "unavailable": self = .unavailable
        default:
             print("WARN: Unknown EKEventAvailability string '\(string)', defaulting to .busy")
             self = .busy
        }
    }
}

extension EKRecurrenceFrequency {
    /// Initializes EKRecurrenceFrequency based on a lowercase string representation.
    /// Defaults to `.daily` if the string doesn't match known frequencies.
    fileprivate init(_ string: String) {
        switch string.lowercased() {
        case "daily": self = .daily
        case "weekly": self = .weekly
        case "monthly": self = .monthly
        case "yearly": self = .yearly
        default:
            print("WARN: Unknown EKRecurrenceFrequency string '\(string)', defaulting to .daily")
            self = .daily
        }
    }
}
