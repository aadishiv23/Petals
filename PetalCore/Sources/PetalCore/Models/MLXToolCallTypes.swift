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
        case parameters = "arguments" // <- THIS is the fix
    }
}

public enum MLXToolCallType: String, Codable {
    case petalGenericCanvasCoursesTool
    case petalFetchCanvasAssignmentsTool
    case petalFetchCanvasGradesTool
    case petalCalendarCreateEventTool
    case petalCalendarFetchEventsTool
    case petalFetchRemindersTool
}

public enum MLXToolCallArguments: Codable {
    case canvasCourses(CanvasCoursesArguments)
    case canvasAssignments(CanvasAssignmentsArguments)
    case canvasGrades(CanvasGradesArguments)
    case calendarCreateEvent(CalendarCreateEventArguments)
    case calendarFetchEvents(CalendarFetchEventsArguments)
    case reminders(RemindersArguments)
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
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
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
           let endDate = try container.decodeIfPresent(String.self, forKey: .endDate) {
            
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
            let calendarNames = try container.decodeIfPresent([String].self, forKey: .calendarNames)
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
        
        // Check for Reminders arguments
        if try container.contains(.includeCompleted) || container.contains(.listName) || container.contains(.search) {
            let includeCompleted = try container.decodeIfPresent(Bool.self, forKey: .includeCompleted)
            let listName = try container.decodeIfPresent(String.self, forKey: .listName)
            let search = try container.decodeIfPresent(String.self, forKey: .search)
            
            self = .reminders(RemindersArguments(
                includeCompleted: includeCompleted,
                listName: listName,
                search: search
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
            if let includeCompleted = args.includeCompleted {
                try container.encode(includeCompleted, forKey: .includeCompleted)
            }
            if let listName = args.listName {
                try container.encode(listName, forKey: .listName)
            }
            if let search = args.search {
                try container.encode(search, forKey: .search)
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
    public let includeCompleted: Bool?
    public let listName: String?
    public let search: String?
}
