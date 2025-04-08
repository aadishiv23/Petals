//
//  ToolMessageView.swift
//  Petals
//
//  Created for ChatBubbleView
//

import Foundation
import PetalCore
import SwiftUI

struct ToolMessageView: View {
    let message: ChatMessage
    let bubbleColor: Color
    let toolName: String

    var body: some View {
        switch toolName {
        case "petalCalendarCreateEventTool":
            CalendarCreateEventView(message: message, bubbleColor: bubbleColor)
        case "petalCalendarFetchEventsTool":
            CalendarEventsView(message: message, bubbleColor: bubbleColor)
        case "petalFetchCanvasAssignmentsTool":
            CanvasAssignmentsView(message: message, bubbleColor: bubbleColor)
        case "petalGenericCanvasCoursesTool":
            CanvasCoursesView(message: message, bubbleColor: bubbleColor)
        default:
            GenericToolMessageView(message: message, bubbleColor: bubbleColor, toolName: toolName)
        }
    }
} 