//
//  MobileChatBubbleView.swift
//  PetalsiOS
//
//  Created for iOS target
//

import SwiftUI
import PetalCore

struct MobileChatBubbleView: View {
    let message: ChatMessage
    @State private var showingOptions = false

    var body: some View {
        HStack(alignment: .top) {
            // Avatar
            if message.participant == .llm {
                MobileAvatar(participant: .llm)
                    .padding(.top, 4)
            }

            // Message bubble
            VStack(alignment: message.participant == .user ? .trailing : .leading, spacing: 4) {
                // Message content
                if let toolName = message.toolCallName {
                    // If it's a tool message, use the appropriate view
                    MobileToolMessageView(message: message, toolName: toolName)
                } else {
                    // Regular text message
                    Text(message.message)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    message.participant == .user
                                        ? Color(hex: "5E5CE6")
                                        : Color(UIColor.secondarySystemBackground)
                                )
                        )
                        .foregroundColor(
                            message.participant == .user
                                ? .white
                                : Color.primary
                        )
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = message.message
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                }
                
                // Timestamp
                Text(message.date.formatted(date: .numeric, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)
                    .frame(maxWidth: .infinity, alignment: message.participant == .user ? .trailing : .leading)
            }
            .frame(maxWidth: .infinity, alignment: message.participant == .user ? .trailing : .leading)

            // User avatar (right side)
            if message.participant == .user {
                MobileAvatar(participant: .user)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Tool Message View
struct MobileToolMessageView: View {
    let message: ChatMessage
    let toolName: String
    
    var body: some View {
        switch toolName {
        case "petalCalendarCreateEventTool":
            MobileCalendarCreateEventView(message: message)
        case "petalCalendarFetchEventsTool":
            MobileCalendarEventsView(message: message)
        case "petalFetchCanvasAssignmentsTool":
            MobileCanvasAssignmentsView(message: message)
        case "petalGenericCanvasCoursesTool":
            MobileCanvasCoursesView(message: message)
        default:
            MobileGenericToolMessageView(message: message, toolName: toolName)
        }
    }
}

// MARK: - Generic Tool Message View
struct MobileGenericToolMessageView: View {
    let message: ChatMessage
    let toolName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "hammer")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text("Tool: \(toolName)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(message.message)
                .padding(.top, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = message.message
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }
} 