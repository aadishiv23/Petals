//
//  PetalCalendarFetchEventsTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/11/25.
//

import EventKit
import Foundation
import PetalCore
import SwiftUI

public enum PetalToolError: Error, LocalizedError {
    case permissionDenied
    case permissionError(Error)
    case internalError(String)
    case calendarNotFound(String)
    case invalidDateFormat(String)
    case invalidDateLogic(String)
    case eventSaveFailed(Error)
    // Add other tool-specific errors

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Calendar access was denied. Please grant permission in Settings."
        case let .permissionError(underlyingError):
            "An error occurred while requesting calendar permission: \(underlyingError.localizedDescription)"
        case let .internalError(message):
            "An internal tool error occurred: \(message)"
        case let .calendarNotFound(requestedNames):
            "Calendar(s) not found: \(requestedNames). Please use an existing calendar name."
        case let .invalidDateFormat(receivedDate):
            "Invalid date format provided: \(receivedDate). Could not parse with known formats."
        case let .invalidDateLogic(message):
            message // e.g., "End date must be after start date."
        case let .eventSaveFailed(underlyingError):
            "Failed to save the event to the calendar: \(underlyingError.localizedDescription)"
        }
    }
}

/// A tool to fetch calendar events with flexible filtering options.
public final class PetalCalendarFetchEventsTool: OllamaCompatibleTool, MLXCompatibleTool {

    public init() {}

    public let uuid: UUID = .init()
    public var id: String { "petalCalendarFetchEventsTool" }
    public var name: String { "Petal Calendar Fetch Events Tool" }
    public var description: String { "Fetches calendar events with flexible filtering options." }

    public var triggerKeywords: [String] { ["events", "fetch"] }
    public var domain: String { "calendar" }
    public var requiredPermission: PetalToolPermission { .basic }

    /// Define the parameters for this tool.
    public var parameters: [PetalToolParameter] {
        [
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
        // Use os.Logger for better logging if preferred over print
        // let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PetalTools", category:
        // "PetalCalendarFetchEventsTool")
        // logger.debug("Executing calendar fetch with input: \(String(describing: input)) - NOTE: Secondary filters
        // will be ignored.")
        print(
            "DEBUG: Executing calendar fetch with input: \(String(describing: input)) - NOTE: Secondary filters will be ignored."
        )

        let eventStore = EKEventStore()

        // --- Request Calendar Access ---
        let currentStatus = EKEventStore.authorizationStatus(for: .event)
        if currentStatus != .authorized {
            print("INFO: Requesting calendar access...")
            do {
                let granted = try await eventStore.requestAccess(to: .event)
                if !granted {
                    print("ERROR: Calendar access denied by user.")
                    throw PetalToolError.permissionDenied
                }
                print("INFO: Calendar access granted.")
            } catch {
                print("ERROR: Failed to request calendar access: \(error.localizedDescription)")
                throw PetalToolError.permissionError(error)
            }
        } else {
            print("INFO: Calendar access already authorized.")
        }

        // --- Date Handling (Includes fix for YYYY-MM-DD) ---
        let isoFormatter = ISO8601DateFormatter() // Keep instance accessible
        let now = Date()
        let pastDateThreshold = Calendar.current
            .date(byAdding: .day, value: -7, to: now)! // Threshold for overriding past dates

        // Default window: Start of today to end of day 7 days from now
        var effectiveStartDate = Calendar.current.startOfDay(for: now)
        var effectiveEndDate = Calendar.current.date(byAdding: .day, value: 7, to: effectiveStartDate)!
        effectiveEndDate = Calendar.current
            .date(bySettingHour: 23, minute: 59, second: 59, of: effectiveEndDate) ?? effectiveEndDate

        var providedStartDate: Date? = nil
        if let startStr = input.startDate, !startStr.isEmpty, startStr.lowercased() != "null" {
            // Try full ISO format first
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsed = isoFormatter.date(from: startStr) {
                providedStartDate = parsed
            } else {
                isoFormatter.formatOptions = [.withInternetDateTime] // Try without fractional seconds
                if let parsed = isoFormatter.date(from: startStr) {
                    providedStartDate = parsed
                } else {
                    isoFormatter.formatOptions = [.withFullDate] // Try YYYY-MM-DD
                    if let parsed = isoFormatter.date(from: startStr) {
                        providedStartDate = Calendar.current.startOfDay(for: parsed) // Assume start of day
                        print("INFO: Parsed start date string '\(startStr)' as YYYY-MM-DD.")
                    } else {
                        print("WARN: Could not parse provided start date string with any known format: \(startStr)")
                        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Reset
                    }
                }
            }
        }

        var providedEndDate: Date? = nil
        if let endStr = input.endDate, !endStr.isEmpty, endStr.lowercased() != "null" {
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Reset before trying end date
            if let parsed = isoFormatter.date(from: endStr) {
                providedEndDate = parsed
            } else {
                isoFormatter.formatOptions = [.withInternetDateTime]
                if let parsed = isoFormatter.date(from: endStr) {
                    providedEndDate = parsed
                } else {
                    isoFormatter.formatOptions = [.withFullDate] // Try YYYY-MM-DD
                    if let parsed = isoFormatter.date(from: endStr) {
                        // Assume end of day for date-only end date
                        providedEndDate = Calendar.current
                            .date(bySettingHour: 23, minute: 59, second: 59, of: parsed) ?? Calendar.current
                            .startOfDay(for: parsed)
                        print("INFO: Parsed end date string '\(endStr)' as YYYY-MM-DD.")
                    } else {
                        print("WARN: Could not parse provided end date string with any known format: \(endStr)")
                    }
                }
            }
        }
        // Reset formatter options after use if it matters elsewhere
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // --- Decide Which Date Range to Use ---
        if let start = providedStartDate, let end = providedEndDate {
            if start >= pastDateThreshold {
                print("INFO: Using provided date range: \(start) to \(end)")
                effectiveStartDate = start
                effectiveEndDate = end
            } else {
                print(
                    "WARN: Provided start date \(start) is too far in the past (< \(pastDateThreshold)). Overriding with default range: \(effectiveStartDate) to \(effectiveEndDate)"
                )
            }
        } else if let start = providedStartDate {
            if start >= pastDateThreshold {
                effectiveStartDate = start
                effectiveEndDate = Calendar.current
                    .date(byAdding: .day, value: 1, to: effectiveStartDate)! // Default end = start + 1 day
                effectiveEndDate = Calendar.current.date(
                    bySettingHour: 23,
                    minute: 59,
                    second: 59,
                    of: effectiveEndDate
                ) ?? effectiveEndDate
                print("INFO: Using provided start date \(start), defaulting end date to \(effectiveEndDate)")
            } else {
                print(
                    "WARN: Provided start date \(start) is too far in the past (< \(pastDateThreshold)). Overriding with default range: \(effectiveStartDate) to \(effectiveEndDate)"
                )
            }
        } else if let end = providedEndDate {
            let reasonableStartDate = Calendar.current.date(byAdding: .day, value: -1, to: end)!
            if reasonableStartDate >= pastDateThreshold {
                effectiveStartDate = reasonableStartDate
                effectiveEndDate = end
                print(
                    "INFO: Only end date \(end) provided. Using calculated range: \(effectiveStartDate) to \(effectiveEndDate)"
                )
            } else {
                print(
                    "WARN: Only end date \(end) provided, but calculated range is too far in the past. Overriding with default range: \(effectiveStartDate) to \(effectiveEndDate)"
                )
            }
        } else {
            print(
                "INFO: No valid start/end dates parsed from LLM input. Using default range: \(effectiveStartDate) to \(effectiveEndDate)"
            )
        }

        // --- Filter Calendars ---
        var calendarsToSearch: [EKCalendar] = []
        let allCalendars = eventStore.calendars(for: .event)
        if let requestedNames = input.calendarNames, !requestedNames.isEmpty {
            let lowercasedNames = Set(
                requestedNames
                    .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            )
            calendarsToSearch = allCalendars.filter { lowercasedNames.contains($0.title.lowercased()) }
            print(
                "INFO: Filtering calendars by names: \(requestedNames). Found matching: \(calendarsToSearch.map(\.title))"
            )
            // Decide on fallback or error if no match
            if calendarsToSearch.isEmpty {
                print(
                    "WARN: No calendars found matching requested names: \(requestedNames). Fetching from ALL calendars as fallback."
                )
                calendarsToSearch = allCalendars // Fallback to all
                // OR throw an error:
                // throw PetalToolError.calendarNotFound(requestedNames.joined(separator: ", "))
            }
        } else {
            print("INFO: No specific calendar names provided. Fetching from all calendars.")
            calendarsToSearch = allCalendars
        }

        guard !calendarsToSearch.isEmpty else {
            print("ERROR: No calendars available to search (either none exist or filtering failed without fallback).")
            return Output(events: "No calendars were found to search.")
        }

        // --- Create Predicate (Based only on Date and Calendars) ---
        print(
            "INFO: Creating predicate with effective start: \(effectiveStartDate), effective end: \(effectiveEndDate), calendars: \(calendarsToSearch.map(\.title))"
        )
        let predicate = eventStore.predicateForEvents(
            withStart: effectiveStartDate,
            end: effectiveEndDate,
            calendars: calendarsToSearch
        )

        // --- Fetch Events ---
        var fetchedEvents = eventStore.events(matching: predicate)
        print("INFO: Found \(fetchedEvents.count) events matching date/calendar predicate. Secondary filters IGNORED.")

        // --- Apply Additional Filters ---
        //
        //      <<<<< THIS SECTION IS NOW SKIPPED >>>>>
        //
        // print("DEBUG: Skipping secondary filters (searchText, availability, status, etc.)")
        // // Filter by All-Day status
        // // if let includeAllDay = input.includeAllDay, includeAllDay == false { ... }
        // // Filter by Search Text
        // // if let search = input.searchText, !search.isEmpty { ... }
        // // Filter by Status
        // // if let statusStr = input.status, !statusStr.isEmpty, statusStr.lowercased() != "null" { ... }
        // // Filter by Availability
        // // if let availabilityStr = input.availability, !availabilityStr.isEmpty, availabilityStr.lowercased() !=
        // /"null" { ... }
        // // Filter by Has Alarms
        // // if let hasAlarms = input.hasAlarms { ... }
        // // Filter by Recurring Status
        // // if let isRecurring = input.isRecurring { ... }
        //

        // --- Sort Events (Still useful) ---
        fetchedEvents.sort { $0.startDate < $1.startDate }
        print("INFO: Sorted remaining \(fetchedEvents.count) events by start date.")

        // --- Format Output ---
        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateStyle = .medium // e.g., Apr 14, 2025
        outputDateFormatter.timeStyle = .short // e.g., 9:00 AM

        let eventList = fetchedEvents.map { event -> String in
            let title = event.title ?? "Untitled Event"
            let startStr = outputDateFormatter.string(from: event.startDate)
            let endStr = outputDateFormatter.string(from: event.endDate)
            let calendarTitle = event.calendar.title
            let location = event.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            var detailString = "(\(calendarTitle))"
            if event.isAllDay {
                detailString += " [All Day]"
            } else {
                detailString += " [\(startStr) - \(endStr)]"
            }
            if !location.isEmpty {
                detailString += " @ \(location)"
            }
            return "• \(title) \(detailString)"
        }.joined(separator: "\n")

        let eventsOutput: String
        let dateRangeString =
            "\(outputDateFormatter.string(from: effectiveStartDate)) to \(outputDateFormatter.string(from: effectiveEndDate))"
        if fetchedEvents.isEmpty {
            eventsOutput = "No events found within the range \(dateRangeString) for the selected calendars."
            print("OUTPUT: No events found.")
        } else {
            // Modify output to clarify that filters were ignored
            eventsOutput = "Found Events (\(dateRangeString) - Filters Ignored):\n\(eventList)"
            print("OUTPUT: Found \(fetchedEvents.count) events.")
        }

        return Output(events: eventsOutput)
    }

    /// Converts this tool into an Ollama-compatible tool representation.
    public func asOllamaTool() -> OllamaTool {
        OllamaTool(
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
        MLXToolDefinition(
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
