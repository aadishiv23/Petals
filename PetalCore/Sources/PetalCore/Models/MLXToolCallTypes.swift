//
//  File.swift
//  PetalCore
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import Foundation

// MARK: - Tool Call Structure

/// Represents a tool call requested by the language model.
///
/// This struct standardizes the representation of a tool call, handling variations
/// in naming conventions used by different LLMs (e.g., "name"/"function", "parameters"/"arguments").
public struct MLXToolCall: Codable {
    /// The specific tool being called.
    public let name: MLXToolCallType
    /// The arguments provided for the tool call.
    public let parameters: MLXToolCallArguments

    /// Coding keys to handle alternative field names from different LLM providers.
    enum CodingKeys: String, CodingKey {
        case name
        case function // Alternative key for name (e.g., some OpenAI formats)
        case parameters
        case arguments // Alternative key for parameters
    }

    /// Creates an `MLXToolCall` by decoding from a decoder.
    ///
    /// Handles variations in key names ("name"/"function", "parameters"/"arguments") and
    /// attempts to decode the arguments into the appropriate `MLXToolCallArguments` case.
    /// If arguments cannot be decoded or are not present, `parameters` defaults to `.unknown`.
    ///
    /// - Throws: `DecodingError` if essential fields like "name" or "function" are missing,
    ///           or if the tool name string doesn't match a valid `MLXToolCallType`.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle both 'name' and 'function' fields for flexibility
        let nameString: String
        if let name = try? container.decodeIfPresent(String.self, forKey: .name) {
            nameString = name
        } else if let function = try? container.decodeIfPresent(String.self, forKey: .function) {
            nameString = function
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.name, // Report 'name' as the expected key
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Neither 'name' nor 'function' field found in tool call"
                )
            )
        }

        // Convert string to MLXToolCallType enum
        if let toolType = MLXToolCallType(rawValue: nameString) {
            self.name = toolType
        } else {
            // If the name doesn't match any known tool type
            throw DecodingError.dataCorruptedError(
                forKey: .name, // Or .function, contextually
                in: container,
                debugDescription: "Invalid or unknown tool name received: \(nameString)"
            )
        }

        // Handle both 'parameters' and 'arguments' fields for the arguments payload
        // Use `decodeIfPresent` to handle cases where arguments might be missing or null
        if let parameters = try? container.decodeIfPresent(MLXToolCallArguments.self, forKey: .parameters) {
            self.parameters = parameters
        } else if let arguments = try? container.decodeIfPresent(MLXToolCallArguments.self, forKey: .arguments) {
            self.parameters = arguments
        } else {
            // If neither 'parameters' nor 'arguments' key is found, or if decoding fails silently,
            // check if the container *actually* contains one of the keys but with null/empty value.
            // If keys are truly absent, defaulting to .unknown might be acceptable if tools can handle it.
            // If keys are present but empty/null, .unknown might still be the correct interpretation.
            print("⚠️ MLXToolCall.init: Neither 'parameters' nor 'arguments' field found or decoded successfully for tool '\(nameString)'. Defaulting arguments to .unknown.")
            self.parameters = .unknown
        }
    }

    /// Encodes this `MLXToolCall` to an encoder.
    ///
    /// Uses the standard "name" and "arguments" keys for output consistency.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Encode using standard keys
        try container.encode(name.rawValue, forKey: .name)
        try container.encode(parameters, forKey: .arguments)
    }
}

// MARK: - Tool Call Type Enum

/// Enumerates the known types of tools that the LLM can call.
///
/// Raw values correspond to the expected "name" or "function" string from the LLM.
public enum MLXToolCallType: String, Codable, CaseIterable { // Added CaseIterable for potential use
    case petalGenericCanvasCoursesTool
    case petalFetchCanvasAssignmentsTool
    case petalFetchCanvasGradesTool
    case petalCalendarCreateEventTool
    case petalCalendarFetchEventsTool
    // case petalFetchRemindersTool // Consider uncommenting if using the old reminder fetch tool
    case petalNotesTool
    case petalRemindersTool // The unified reminders tool
}

// MARK: - Tool Call Arguments Enum

/// Enumerates the possible argument structures for each `MLXToolCallType`.
///
/// Includes an `.unknown` case for situations where arguments are missing or cannot be parsed.
/// The `init(from:)` decoder implements robust parsing logic to handle variations in LLM output
/// (e.g., string "null", string "[]", boolean strings) and disambiguate between tools with overlapping keys.
public enum MLXToolCallArguments: Codable {
    case canvasCourses(CanvasCoursesArguments)
    case canvasAssignments(CanvasAssignmentsArguments)
    case canvasGrades(CanvasGradesArguments)
    case calendarCreateEvent(CalendarCreateEventArguments)
    case calendarFetchEvents(CalendarFetchEventsArguments)
    case reminders(RemindersArguments)
    case notes(NotesArguments)
    /// Represents a state where arguments were missing, couldn't be parsed, or didn't match a known tool structure.
    case unknown

    /// Coding keys corresponding to the expected argument names within the JSON payload.
    enum CodingKeys: String, CodingKey {
        // Common & Canvas
        case completed
        case courseName
        case includeCompleted // Often used with fetching completed items

        // Calendar & Event Related
        case title
        case startDate
        case endDate
        case calendarName // Single calendar for create
        case location
        case notes          // Event notes / Reminder notes
        case calendarNames  // Multiple calendars for fetch
        case includeAllDay
        case status         // Event status
        case availability   // Event availability
        case hasAlarms
        case isRecurring

        // Notes & Reminders Related
        case action         // e.g., "create", "fetch", "update", "delete"
        case body           // Note body
        case folderName     // Note folder
        case listName       // Reminder list
        case name           // Reminder title (distinct from calendar title/event name)
        case dueDate        // Reminder due date

        // Search Related (used by multiple tools)
        case searchText
        case search // If LLM uses this instead of searchText, map it if necessary
    }

    /// Creates `MLXToolCallArguments` by decoding from a decoder.
    ///
    /// This initializer attempts to determine the correct tool argument case based on the
    /// presence and values of keys in the decoded JSON. It uses helper functions
    /// (`decodeBoolTolerantly`, `decodeCalendarNamesTolerantly`, `nilIfNullString`)
    /// to handle potentially inconsistent LLM output formatting (e.g., `"null"`, `"[]"`, `"true"` as strings).
    ///
    /// - Throws: `DecodingError` only if decoding fundamentally fails (e.g., malformed JSON),
    ///           but tries to gracefully handle missing keys or unexpected values by falling back to `.unknown`.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let allKeys = container.allKeys // Get available keys for checking presence

        // --- Tool Argument Type Disambiguation ---
        // Determine the tool based on unique or strongly indicative keys first.

        // 1. Check for Notes tool ('action' + body/folderName or searchText without calendar focus)
        if let action = try container.decodeIfPresent(String.self, forKey: .action),
           (allKeys.contains(.body) || allKeys.contains(.folderName) ||
            (allKeys.contains(.searchText) && !allKeys.contains(.calendarNames) && !allKeys.contains(.listName))) // Heuristic: action + search without calendar/reminder context
        {
            let searchText = try container.decodeIfPresent(String.self, forKey: .searchText)?.nilIfNullString()
            let title = try container.decodeIfPresent(String.self, forKey: .title)?.nilIfNullString() // Notes can have titles
            let body = try container.decodeIfPresent(String.self, forKey: .body)?.nilIfNullString()
            let folderName = try container.decodeIfPresent(String.self, forKey: .folderName)?.nilIfNullString()

            self = .notes(NotesArguments(
                action: action,
                searchText: searchText,
                title: title,
                body: body,
                folderName: folderName
            ))
            return
        }

        // 2. Check for Reminders tool ('action' + listName/dueDate/name)
        if let action = try container.decodeIfPresent(String.self, forKey: .action),
           (allKeys.contains(.listName) || allKeys.contains(.dueDate) || allKeys.contains(.name)) // 'name' is reminder title key
        {
            let listName = try container.decodeIfPresent(String.self, forKey: .listName)?.nilIfNullString()
            let searchText = try container.decodeIfPresent(String.self, forKey: .searchText)?.nilIfNullString()
            let name = try container.decodeIfPresent(String.self, forKey: .name)?.nilIfNullString() // Reminder title
            let notes = try container.decodeIfPresent(String.self, forKey: .notes)?.nilIfNullString() // Reminder notes/body
            let dueDate = try container.decodeIfPresent(String.self, forKey: .dueDate)?.nilIfNullString() // Handle "null"

            self = .reminders(RemindersArguments(
                action: action,
                listName: listName,
                searchText: searchText,
                name: name,
                notes: notes,
                dueDate: dueDate
            ))
            return
        }

        // 3. Check for Canvas Courses (fairly unique 'completed' key)
        if allKeys.contains(.completed) && !allKeys.contains(.action) { // Ensure not confused with reminder completion if 'completed' is ever added there
            let completed = try decodeBoolTolerantly(from: container, forKey: .completed)
            // Requires courseName as well? The struct only has completed.
            // If it needs courseName, the logic needs adjustment. Assuming it only needs 'completed'.
            self = .canvasCourses(CanvasCoursesArguments(completed: completed))
            // If courseName is *also* required, this check needs refinement or CanvasCoursesArguments needs updating.
            return
        }

        // 4. Check for Canvas Grades/Assignments (uses 'courseName')
        // This check must run *after* calendar checks if title/dates might also be present.
        // Let's refine: Check specifically if 'courseName' is present *without* strong calendar/event indicators.
        if let courseName = try container.decodeIfPresent(String.self, forKey: .courseName)?.nilIfNullString(),
           !courseName.isEmpty, // Ensure it's not just an empty string
           !allKeys.contains(.action), // Not Notes/Reminders
           !allKeys.contains(.title), // Not Calendar Create
           !allKeys.contains(.startDate), !allKeys.contains(.endDate), // Not Calendar Create/Fetch with dates
           !allKeys.contains(.calendarNames) // Not Calendar Fetch with names
        {
            // At this point, 'courseName' is present, and major calendar/event/action keys are absent.
            // It's likely Canvas Assignments or Grades.
            // The final distinction relies on the MLXToolCallType.name provided in the outer struct.
            // We create one case here; the AppToolCallHandler will dispatch based on the .name.
            // Let's default to creating Assignments here, as it's listed first. Both structs are identical anyway.
            // *Important*: This assumes AppToolCallHandler uses `MLXToolCall.name` to pick the correct tool execution path.
            self = .canvasAssignments(CanvasAssignmentsArguments(courseName: courseName))
            // We could also assign .canvasGrades here; it doesn't matter as long as the structure is parsed.
            // self = .canvasGrades(CanvasGradesArguments(courseName: courseName))
            return
        }

        // 5. Check for Calendar Create Event (requires 'title', 'startDate', 'endDate')
        // Must check *before* Fetch if dates are present.
        if let title = try container.decodeIfPresent(String.self, forKey: .title)?.nilIfNullString(), !title.isEmpty,
           let startDateStr = try container.decodeIfPresent(String.self, forKey: .startDate)?.nilIfNullString(), !startDateStr.isEmpty,
           let endDateStr = try container.decodeIfPresent(String.self, forKey: .endDate)?.nilIfNullString(), !endDateStr.isEmpty,
           !allKeys.contains(.action) // Ensure not confused with Notes/Reminders potentially having dates/title
        {
            // This strongly suggests a create event
            let calendarName = try container.decodeIfPresent(String.self, forKey: .calendarName)?.nilIfNullString()
            let location = try container.decodeIfPresent(String.self, forKey: .location)?.nilIfNullString()
            let notes = try container.decodeIfPresent(String.self, forKey: .notes)?.nilIfNullString()

            self = .calendarCreateEvent(CalendarCreateEventArguments(
                title: title,
                startDate: startDateStr,
                endDate: endDateStr,
                calendarName: calendarName,
                location: location,
                notes: notes
            ))
            return
        }

        // 6. Check for Calendar Fetch Events (uses optional date/time/filter keys, often *without* title or action)
        // Check for keys specific to fetch or optional date keys, ensuring it's not Create/Notes/Reminders.
        let hasFetchKeys = allKeys.contains(.calendarNames) || allKeys.contains(.searchText) ||
                           allKeys.contains(.includeAllDay) || allKeys.contains(.status) ||
                           allKeys.contains(.availability) || allKeys.contains(.hasAlarms) ||
                           allKeys.contains(.isRecurring)
        let hasOptionalDates = allKeys.contains(.startDate) || allKeys.contains(.endDate)

        if (hasFetchKeys || hasOptionalDates) && !allKeys.contains(.action) && !allKeys.contains(.title) {
            // Decode optional strings, converting "null" string to nil
            let startDate = try container.decodeIfPresent(String.self, forKey: .startDate)?.nilIfNullString()
            let endDate = try container.decodeIfPresent(String.self, forKey: .endDate)?.nilIfNullString()
            // Default empty string if null/missing, then check if empty later
            let searchText = try container.decodeIfPresent(String.self, forKey: .searchText)?.nilIfNullString() ?? ""
            let status = try container.decodeIfPresent(String.self, forKey: .status)?.nilIfNullString()
            let availability = try container.decodeIfPresent(String.self, forKey: .availability)?.nilIfNullString()

            // Decode optional booleans tolerantly
            let includeAllDay = try decodeBoolTolerantly(from: container, forKey: .includeAllDay)
            let hasAlarms = try decodeBoolTolerantly(from: container, forKey: .hasAlarms)
            let isRecurring = try decodeBoolTolerantly(from: container, forKey: .isRecurring)

            // Decode calendarNames tolerantly
            let calendarNames: [String]? = try decodeCalendarNamesTolerantly(from: container, forKey: .calendarNames)

            // Only assign if at least one relevant fetch argument was present and decoded something meaningful
            // (Prevents matching empty {} arguments as fetch)
            if startDate != nil || endDate != nil || calendarNames != nil || !searchText.isEmpty ||
               includeAllDay != nil || status != nil || availability != nil || hasAlarms != nil || isRecurring != nil
            {
                self = .calendarFetchEvents(CalendarFetchEventsArguments(
                    startDate: startDate,
                    endDate: endDate,
                    calendarNames: calendarNames,
                    searchText: searchText.isEmpty ? nil : searchText, // Store nil if search was effectively empty
                    includeAllDay: includeAllDay,
                    status: status,
                    availability: availability,
                    hasAlarms: hasAlarms,
                    isRecurring: isRecurring
                ))
                return
            }
        }

        // --- Fallback ---
        // If none of the specific tool argument structures matched...
        print("⚠️ MLXToolCallArguments.init: Could not definitively match arguments to a known tool structure. Falling back to .unknown. Keys present: \(allKeys.map(\.rawValue))")
        // You could try decoding into a generic [String: Any] here for detailed debugging if needed:
        // if let genericArgs = try? decoder.singleValueContainer().decode([String: AnyCodable].self) {
        //     print("Generic args decoded: \(genericArgs)")
        // }
        self = .unknown
    }

    /// Encodes the arguments to an encoder based on the specific case.
    /// Uses `encodeIfPresent` for optional fields to avoid including `null` unless necessary.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .canvasCourses(args):
            try container.encodeIfPresent(args.completed, forKey: .completed) // Optional
        case let .canvasAssignments(args):
            try container.encode(args.courseName, forKey: .courseName) // Required
        case let .canvasGrades(args):
            try container.encode(args.courseName, forKey: .courseName) // Required
        case let .calendarCreateEvent(args):
            try container.encode(args.title, forKey: .title) // Required
            try container.encode(args.startDate, forKey: .startDate) // Required
            try container.encode(args.endDate, forKey: .endDate) // Required
            try container.encodeIfPresent(args.calendarName, forKey: .calendarName) // Optional
            try container.encodeIfPresent(args.location, forKey: .location) // Optional
            try container.encodeIfPresent(args.notes, forKey: .notes) // Optional
        case let .calendarFetchEvents(args):
            // All fields are optional for fetch
            try container.encodeIfPresent(args.startDate, forKey: .startDate)
            try container.encodeIfPresent(args.endDate, forKey: .endDate)
            try container.encodeIfPresent(args.calendarNames, forKey: .calendarNames)
            try container.encodeIfPresent(args.searchText, forKey: .searchText)
            try container.encodeIfPresent(args.includeAllDay, forKey: .includeAllDay)
            try container.encodeIfPresent(args.status, forKey: .status)
            try container.encodeIfPresent(args.availability, forKey: .availability)
            try container.encodeIfPresent(args.hasAlarms, forKey: .hasAlarms)
            try container.encodeIfPresent(args.isRecurring, forKey: .isRecurring)
        case let .reminders(args):
            try container.encode(args.action, forKey: .action) // Required
            // Optional fields
            try container.encodeIfPresent(args.listName, forKey: .listName)
            try container.encodeIfPresent(args.searchText, forKey: .searchText)
            try container.encodeIfPresent(args.name, forKey: .name) // Reminder title
            try container.encodeIfPresent(args.notes, forKey: .notes)
            try container.encodeIfPresent(args.dueDate, forKey: .dueDate)
        case let .notes(args):
            try container.encode(args.action, forKey: .action) // Required
            // Optional fields
            try container.encodeIfPresent(args.searchText, forKey: .searchText)
            try container.encodeIfPresent(args.title, forKey: .title)
            try container.encodeIfPresent(args.body, forKey: .body)
            try container.encodeIfPresent(args.folderName, forKey: .folderName)
        case .unknown:
            // Encode as an empty object or handle as needed.
            // Encoding nothing might be appropriate if the outer call expects arguments.
            // Let's encode an empty object for clarity.
            // NOTE: This might need adjustment based on how the receiving end handles .unknown
             var unknownContainer = encoder.container(keyedBy: CodingKeys.self)
             // No keys encoded, resulting in {}
            break
        }
    }
}

// MARK: - Argument Struct Definitions

/// Arguments for fetching Canvas courses.
public struct CanvasCoursesArguments: Codable {
    /// Filter for completed status (optional).
    public let completed: Bool?
    // Add courseName here if it's actually needed by the tool
    // public let courseName: String?
}

/// Arguments for fetching Canvas assignments (currently only by course name).
public struct CanvasAssignmentsArguments: Codable {
    /// The name of the course to fetch assignments for.
    public let courseName: String
}

/// Arguments for fetching Canvas grades (currently only by course name).
public struct CanvasGradesArguments: Codable {
    /// The name of the course to fetch grades for.
    public let courseName: String
}

/// Arguments for creating a calendar event.
public struct CalendarCreateEventArguments: Codable {
    /// The title of the event (required).
    public let title: String
    /// ISO 8601 formatted start date/time string (required).
    public let startDate: String
    /// ISO 8601 formatted end date/time string (required).
    public let endDate: String
    /// The name of the calendar to add the event to (optional).
    public let calendarName: String?
    /// The location of the event (optional).
    public let location: String?
    /// Notes associated with the event (optional).
    public let notes: String?
}

/// Arguments for fetching calendar events with various filters.
public struct CalendarFetchEventsArguments: Codable {
    /// ISO 8601 formatted start date/time string for the search range (optional).
    public let startDate: String?
    /// ISO 8601 formatted end date/time string for the search range (optional).
    public let endDate: String?
    /// List of calendar names to filter by (optional; fetches from all if nil/empty).
    public let calendarNames: [String]?
    /// Text to search for in event titles, locations, or notes (optional).
    public let searchText: String?
    /// Whether to include all-day events (optional; defaults may vary by tool implementation).
    public let includeAllDay: Bool?
    /// Filter by event status (e.g., "confirmed", "tentative", "canceled") (optional).
    public let status: String?
    /// Filter by event availability (e.g., "busy", "free") (optional).
    public let availability: String?
    /// Filter for events that have alarms set (optional).
    public let hasAlarms: Bool?
    /// Filter for recurring events (optional).
    public let isRecurring: Bool?
}

/// Arguments for interacting with Reminders (create, fetch, update, etc.).
public struct RemindersArguments: Codable {
    /// The action to perform (e.g., "create", "fetch") (required).
    public let action: String
    /// The name of the reminder list (optional).
    public let listName: String?
    /// Text to search for within reminders (optional).
    public let searchText: String?
    /// The title/name of the reminder (optional, but required for creation).
    public let name: String?
    /// Notes associated with the reminder (optional).
    public let notes: String?
    /// ISO 8601 formatted due date string (optional).
    public let dueDate: String?
    // Consider adding 'completed: Bool?' if needed for update/fetch actions
}

/// Arguments for interacting with Notes (create, fetch, update, etc.).
public struct NotesArguments: Codable {
    /// The action to perform (e.g., "create", "fetch") (required).
    public let action: String
    /// Text to search for within notes (optional).
    public let searchText: String?
    /// The title of the note (optional, potentially required for creation).
    public let title: String?
    /// The body content of the note (optional, potentially required for creation).
    public let body: String?
    /// The name of the folder the note belongs to or should be created in (optional).
    public let folderName: String?
}


// MARK: - Helper Functions and Extensions

/// Extension to handle the `"null"` string case for Optionals more easily.
fileprivate extension String {
    /// Returns `nil` if the string is `"null"` (case-insensitive), otherwise returns the original string.
    /// Useful for decoding optional string fields where the LLM might send the string `"null"` instead of JSON null.
    func nilIfNullString() -> String? {
        return self.lowercased() == "null" ? nil : self
    }
}

/// Decodes a `Bool?` from a container, tolerating various representations.
///
/// Handles:
/// - Actual JSON `true`/`false`.
/// - Actual JSON `null`.
/// - String `"true"`/`"false"` (case-insensitive).
/// - String `"null"` (case-insensitive).
///
/// Returns `nil` if the key is not present, the value is JSON null or the string `"null"`,
/// or if the value is a string that cannot be interpreted as a boolean.
///
/// - Parameters:
///   - container: The keyed decoding container.
///   - key: The key to decode.
/// - Returns: The decoded `Bool` or `nil`.
/// - Throws: Rethrows decoding errors only if the container access itself fails.
fileprivate func decodeBoolTolerantly(from container: KeyedDecodingContainer<MLXToolCallArguments.CodingKeys>, forKey key: MLXToolCallArguments.CodingKeys) throws -> Bool? {
    // 1. Try decoding as Bool directly (handles true, false, JSON null)
    if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: key) {
        return boolValue // Correctly handles JSON null -> nil
    }
    // 2. If that failed (e.g., value was a string) or key wasn't present, try decoding as String
    if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
        switch stringValue.lowercased() {
        case "true": return true
        case "false": return false
        case "null": return nil // Treat "null" string as nil
        default:
            // Optionally log a warning for unexpected strings
            print("⚠️ decodeBoolTolerantly: Unexpected string value '\(stringValue)' for key '\(key.rawValue)'. Treating as nil.")
            return nil
        }
    }
    // 3. Key not present, or present with a type other than Bool or String
    return nil
}

/// Decodes `[String]?` from a container, tolerating various representations.
///
/// Handles:
/// - Actual JSON array `[]` or `["a"]`.
/// - Actual JSON `null`.
/// - String representation of an empty array (`"[]"`).
/// - String representation of a populated array (e.g., `"['a', 'b']"`, `"[\"a\",\"b\"]"`).
/// - String `"null"` (case-insensitive).
///
/// Returns `nil` if the key is not present, the value is JSON null or the string `"null"`,
/// represents an empty array (`[]` or `"[]"`), or is an unparseable string.
///
/// - Parameters:
///   - container: The keyed decoding container.
///   - key: The key to decode.
/// - Returns: The decoded `[String]` or `nil`.
/// - Throws: Rethrows decoding errors only if the container access itself fails.
fileprivate func decodeCalendarNamesTolerantly(from container: KeyedDecodingContainer<MLXToolCallArguments.CodingKeys>, forKey key: MLXToolCallArguments.CodingKeys) throws -> [String]? {
    // 1. Try decoding as actual array [String] (handles JSON null correctly -> nil)
    if let arrayValue = try? container.decodeIfPresent([String].self, forKey: key) {
        // Return the array if not empty, otherwise nil (treat empty array as nil for filters)
        return arrayValue.isEmpty ? nil : arrayValue
    }
    // 2. If that failed or key wasn't present, try decoding as String
    if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
        let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle explicit "null" string or empty array string "[]" -> nil
        if trimmed.lowercased() == "null" || trimmed == "[]" {
            return nil
        }

        // Attempt to parse string like "['a', 'b']" or "'a','b'" or "[\"a\", \"b\"]"
        // Basic parsing: remove outer brackets/quotes, split by comma, trim inner quotes/whitespace
        let noOuterBrackets = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        let components = noOuterBrackets.split(separator: ",")
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                  .trimmingCharacters(in: CharacterSet(charactersIn: "'\"")) // Remove inner quotes
            }
            .filter { !$0.isEmpty } // Filter out potential empty strings

        // Return components if any were found, otherwise nil
        return components.isEmpty ? nil : components
    }
    // 3. Key not present, or present with a type other than Array or String
    return nil
}
