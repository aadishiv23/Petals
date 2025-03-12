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
    
    /// Create a generic canvas tool.
    public static func createFetchCanvasCoursesTool() async -> any PetalTool {
        let canvasTool = PetalGenericFetchCanvasCoursesTool()
        await PetalToolRegistry.shared.registerTool(canvasTool)
        return canvasTool
    }
}
