//
//  PetalToolFactory.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/11/25.
//

import Foundation

/// Factory for creating standardized tools.
public class PetalToolFactory {
    
    /// Creates a generic calendar tool.
    public static func createCalendarTool() async -> any PetalTool {
        let calendarTool = PetalMockCalendarTool()
        await PetalToolRegistry.shared.registerTool(calendarTool)
        return calendarTool
    }
    
    /// Creates a generic Canvas tool for fetching courses.
    public static func createFetchCanvasCoursesTool() async -> any PetalTool {
        let canvasTool = PetalGenericFetchCanvasCoursesTool()
        await PetalToolRegistry.shared.registerTool(canvasTool)
        return canvasTool
    }

    /// Creates a Canvas tool for fetching assignments.
    public static func createFetchCanvasAssignmentsTool() async -> any PetalTool {
        let assignmentsTool = PetalFetchCanvasAssignmentsTool()
        await PetalToolRegistry.shared.registerTool(assignmentsTool)
        return assignmentsTool
    }

    /// Creates a Canvas tool for fetching grades.
    public static func createFetchCanvasGradesTool() async -> any PetalTool {
        let gradesTool = PetalFetchCanvasGradesTool()
        await PetalToolRegistry.shared.registerTool(gradesTool)
        return gradesTool
    }
    
    public static func createCalendarCreateEventTool() async -> any PetalTool {
        let gradesTool = PetalCalendarCreateEventTool()
        await PetalToolRegistry.shared.registerTool(gradesTool)
        return gradesTool
    }
    
    public static func createCalendarFetchEventTool() async -> any PetalTool {
        let gradesTool = PetalCalendarFetchEventsTool()
        await PetalToolRegistry.shared.registerTool(gradesTool)
        return gradesTool
    }
    
    public static func createFetchRemindersTool() async -> any PetalTool {
        let remindersTool = PetalFetchRemindersTool()
        await PetalToolRegistry.shared.registerTool(remindersTool)
        return remindersTool
    }
    
    #if os(iOS)
    public static func createContactsTool() async -> any PetalTool {
        let contactsTool = PetalContactsTool()
        await PetalToolRegistry.shared.registerTool(contactsTool)
        return contactsTool
    }

    public static func createRemindersTool() async -> any PetalTool {
        let remindersTool = PetalRemindersTool()
        await PetalToolRegistry.shared.registerTool(remindersTool)
        return remindersTool
    }
    #endif
    
    #if os(macOS)
    public static func createNotesTool() async -> any PetalTool {
        let notesTool = PetalNotesTool()
        await PetalToolRegistry.shared.registerTool(notesTool)
        return notesTool
    }
    
    public static func createRemindersTool() async -> any PetalTool {
        let remindersTool = PetalRemindersTool()
        await PetalToolRegistry.shared.registerTool(remindersTool)
        return remindersTool
    }
    
    #endif
}

