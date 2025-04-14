//
//  File.swift
//  PetalCore
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import Foundation

public struct MLXToolCall: Codable {
    public let name: MLXToolCallType
    public let parameters: MLXToolCallArguments

    enum CodingKeys: String, CodingKey {
        case name
        case function // Alternative key for name in some LLM formats
        case parameters
        case arguments // Alternative key for parameters
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle both name and function fields for flexibility
        let nameString: String
        if let name = try? container.decodeIfPresent(String.self, forKey: .name) {
            nameString = name
        } else if let function = try? container.decodeIfPresent(String.self, forKey: .function) {
            nameString = function
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.name,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Neither 'name' nor 'function' field found in tool call"
                )
            )
        }

        // Convert string to MLXToolCallType
        if let toolType = MLXToolCallType(rawValue: nameString) {
            self.name = toolType
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .name,
                in: container,
                debugDescription: "Invalid tool name: \(nameString)"
            )
        }

        // Handle both parameters and arguments fields
        if let parameters = try? container.decodeIfPresent(MLXToolCallArguments.self, forKey: .parameters) {
            self.parameters = parameters
        } else if let arguments = try? container.decodeIfPresent(MLXToolCallArguments.self, forKey: .arguments) {
            self.parameters = arguments
        } else {
            // Default to unknown if no parameters provided
            self.parameters = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name.rawValue, forKey: .name)
        try container.encode(parameters, forKey: .arguments)
    }
}

public enum MLXToolCallType: String, Codable {
    case petalGenericCanvasCoursesTool
    case petalFetchCanvasAssignmentsTool
    case petalFetchCanvasGradesTool
    case petalCalendarCreateEventTool
    case petalCalendarFetchEventsTool
    // case petalFetchRemindersTool
    case petalNotesTool
    case petalRemindersTool
}

public enum MLXToolCallArguments: Codable {
    case canvasCourses(CanvasCoursesArguments)
    case canvasAssignments(CanvasAssignmentsArguments)
    case canvasGrades(CanvasGradesArguments)
    case calendarCreateEvent(CalendarCreateEventArguments)
    case calendarFetchEvents(CalendarFetchEventsArguments)
    case reminders(RemindersArguments)
    case notes(NotesArguments)
    case unknown

    enum CodingKeys: String, CodingKey {
        case completed
        case courseName
        case title
        case startDate
        case endDate
        case calendarName
        case location
        case notes
        case calendarNames
        case searchText
        case includeAllDay
        case status
        case availability
        case hasAlarms
        case isRecurring
        case includeCompleted
        case listName
        case search
        case action
        case body
        case folderName
        case name
        case dueDate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Check for Notes tool
        if let action = try container.decodeIfPresent(String.self, forKey: .action) {
            let searchText = try container.decodeIfPresent(String.self, forKey: .searchText)
            let title = try container.decodeIfPresent(String.self, forKey: .title)
            let body = try container.decodeIfPresent(String.self, forKey: .body)
            let folderName = try container.decodeIfPresent(String.self, forKey: .folderName)

            self = .notes(NotesArguments(
                action: action,
                searchText: searchText,
                title: title,
                body: body,
                folderName: folderName
            ))
            return
        }

        // Check for Canvas Courses arguments
        if let completed = try container.decodeIfPresent(Bool.self, forKey: .completed) {
            self = .canvasCourses(CanvasCoursesArguments(completed: completed))
            return
        }

        // Check for Canvas Assignments arguments
        if let courseName = try container.decodeIfPresent(String.self, forKey: .courseName) {
            self = .canvasAssignments(CanvasAssignmentsArguments(courseName: courseName))
            return
        }

        // Check for Canvas Grades arguments
        if let courseName = try container.decodeIfPresent(String.self, forKey: .courseName) {
            if try container.contains(.title) == false {
                // If there's no title, it's likely grades and not a calendar event
                self = .canvasGrades(CanvasGradesArguments(courseName: courseName))
                return
            }
        }

        // Check for Calendar Create Event arguments
        if let title = try container.decodeIfPresent(String.self, forKey: .title),
           let startDate = try container.decodeIfPresent(String.self, forKey: .startDate),
           let endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        {
            let calendarName = try container.decodeIfPresent(String.self, forKey: .calendarName)
            let location = try container.decodeIfPresent(String.self, forKey: .location)
            let notes = try container.decodeIfPresent(String.self, forKey: .notes)

            self = .calendarCreateEvent(CalendarCreateEventArguments(
                title: title,
                startDate: startDate,
                endDate: endDate,
                calendarName: calendarName,
                location: location,
                notes: notes
            ))
            return
        }

        // Check for Calendar Fetch Events arguments
        if try container.contains(.startDate) || container.contains(.endDate) || container.contains(.calendarNames) {
            let startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
            let endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
            let calendarNames: [String]? = {
                if let array = try? container.decodeIfPresent([String].self, forKey: .calendarNames) {
                    return array
                } else if let singleString = try? container.decodeIfPresent(String.self, forKey: .calendarNames) {
                    // Convert string like "['Work', 'Personal']" into an actual array
                    let trimmed = singleString.trimmingCharacters(in: .whitespacesAndNewlines)
                    let noBrackets = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                    let split = noBrackets.split(separator: ",").map {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                    }
                    return split.isEmpty ? nil : split
                } else {
                    return nil
                }
            }()
            let searchText = try container.decodeIfPresent(String.self, forKey: .searchText)
            let includeAllDay = try container.decodeIfPresent(Bool.self, forKey: .includeAllDay)
            let status = try container.decodeIfPresent(String.self, forKey: .status)
            let availability = try container.decodeIfPresent(String.self, forKey: .availability)
            let hasAlarms = try container.decodeIfPresent(Bool.self, forKey: .hasAlarms)
            let isRecurring = try container.decodeIfPresent(Bool.self, forKey: .isRecurring)

            self = .calendarFetchEvents(CalendarFetchEventsArguments(
                startDate: startDate,
                endDate: endDate,
                calendarNames: calendarNames,
                searchText: searchText,
                includeAllDay: includeAllDay,
                status: status,
                availability: availability,
                hasAlarms: hasAlarms,
                isRecurring: isRecurring
            ))
            return
        }

        self = .unknown
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .canvasCourses(args):
            try container.encode(args.completed, forKey: .completed)
        case let .canvasAssignments(args):
            try container.encode(args.courseName, forKey: .courseName)
        case let .canvasGrades(args):
            try container.encode(args.courseName, forKey: .courseName)
        case let .calendarCreateEvent(args):
            try container.encode(args.title, forKey: .title)
            try container.encode(args.startDate, forKey: .startDate)
            try container.encode(args.endDate, forKey: .endDate)
            if let calendarName = args.calendarName {
                try container.encode(calendarName, forKey: .calendarName)
            }
            if let location = args.location {
                try container.encode(location, forKey: .location)
            }
            if let notes = args.notes {
                try container.encode(notes, forKey: .notes)
            }
        case let .calendarFetchEvents(args):
            if let startDate = args.startDate {
                try container.encode(startDate, forKey: .startDate)
            }
            if let endDate = args.endDate {
                try container.encode(endDate, forKey: .endDate)
            }
            if let calendarNames = args.calendarNames {
                try container.encode(calendarNames, forKey: .calendarNames)
            }
            if let searchText = args.searchText {
                try container.encode(searchText, forKey: .searchText)
            }
            if let includeAllDay = args.includeAllDay {
                try container.encode(includeAllDay, forKey: .includeAllDay)
            }
            if let status = args.status {
                try container.encode(status, forKey: .status)
            }
            if let availability = args.availability {
                try container.encode(availability, forKey: .availability)
            }
            if let hasAlarms = args.hasAlarms {
                try container.encode(hasAlarms, forKey: .hasAlarms)
            }
            if let isRecurring = args.isRecurring {
                try container.encode(isRecurring, forKey: .isRecurring)
            }
        case let .reminders(args):
            // Required field (non-optional)
            try container.encode(args.action, forKey: .action)

            // Optional fields
            if let listName = args.listName {
                try container.encode(listName, forKey: .listName)
            }
            if let searchText = args.searchText {
                try container.encode(searchText, forKey: .searchText)
            }
            if let name = args.name {
                try container.encode(name, forKey: .name)
            }
            if let notes = args.notes {
                try container.encode(notes, forKey: .notes)
            }
            if let dueDate = args.dueDate {
                try container.encode(dueDate, forKey: .dueDate)
            }
        case let .notes(args):
            try container.encode(args.action, forKey: .action)
            if let searchText = args.searchText {
                try container.encode(searchText, forKey: .searchText)
            }
            if let title = args.title {
                try container.encode(title, forKey: .title)
            }
            if let body = args.body {
                try container.encode(body, forKey: .body)
            }
            if let folderName = args.folderName {
                try container.encode(folderName, forKey: .folderName)
            }
        case .unknown:
            break
        }
    }
}

public struct CanvasCoursesArguments: Codable {
    public let completed: Bool?
}

public struct CanvasAssignmentsArguments: Codable {
    public let courseName: String
}

public struct CanvasGradesArguments: Codable {
    public let courseName: String
}

public struct CalendarCreateEventArguments: Codable {
    public let title: String
    public let startDate: String
    public let endDate: String
    public let calendarName: String?
    public let location: String?
    public let notes: String?
}

public struct CalendarFetchEventsArguments: Codable {
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

public struct RemindersArguments: Codable {
    public let action: String
    public let listName: String?
    public let searchText: String?
    public let name: String?
    public let notes: String?
    public let dueDate: String?
}

public struct NotesArguments: Codable {
    public let action: String
    public let searchText: String?
    public let title: String?
    public let body: String?
    public let folderName: String?
}
