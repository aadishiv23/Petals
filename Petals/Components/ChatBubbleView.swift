//
//  ChatBubbleView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/12/25.
//

import Foundation
import SwiftUI
import PetalCore

struct ChatBubbleView: View {
    let message: ChatMessage

    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false

    /// Message appearance based on sender
    var bubbleColor: Color {
        message.participant == .user
            ? Color(hex: "5E5CE6")
            : (colorScheme == .dark ? Color(NSColor.controlBackgroundColor) : Color(NSColor.controlBackgroundColor))
    }

    var textColor: Color {
        message.participant == .user
            ? .white
            : (colorScheme == .dark ? .white : .primary)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.participant == .llm || message.participant == .system {
                Avatar(participant: .llm)
                    .offset(y: 2)

                MessageContentView(message: message, bubbleColor: bubbleColor, textColor: textColor)
                    .padding(.trailing, 60)

                Spacer()
            } else {
                Spacer()

                MessageContentView(message: message, bubbleColor: bubbleColor, textColor: textColor)
                    .padding(.leading, 60)

                Avatar(participant: .user)
                    .offset(y: 2)
            }
        }
        .padding(.vertical, 2)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Message Content View

struct CanvasAssignmentsView: View {
    let message: ChatMessage
    let bubbleColor: Color
    @State private var expandedAssignment: String? = nil
    @State private var hoveredAssignment: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Text("Upcoming Assignments")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    // Mock refresh action
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            Divider()
                .padding(.vertical, 2)

            let assignments = message.message
                .components(separatedBy: .newlines)
                .filter { !$0.isEmpty }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(assignments, id: \.self) { assignmentLine in
                        let components = assignmentLine.components(separatedBy: " (Due: ")
                        let assignmentText = components[0]
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "• ", with: "")

                        let courseParts = assignmentText.components(separatedBy: " — ")
                        let course = courseParts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let title = courseParts.count > 1 ? courseParts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""

                        let dueDateText = components.count > 1 ? components[1].replacingOccurrences(of: ")", with: "") : "No due date"

                        let isPastDue = components.count > 1 && !dueDateText.contains("No due date") &&
                            (dueDateText.contains("2025-02") || dueDateText.contains("2025-01"))

                        let isDueSoon = components.count > 1 && !dueDateText.contains("No due date") &&
                            dueDateText.contains("2025-03-22")
                        
                        let isExpanded = expandedAssignment == assignmentLine
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if expandedAssignment == assignmentLine {
                                    expandedAssignment = nil
                                } else {
                                    expandedAssignment = assignmentLine
                                }
                            }
                        }) {
                            VStack(spacing: 0) {
                                HStack(alignment: .top, spacing: 10) {
                                    if isPastDue {
                                        ZStack {
                                            Circle()
                                                .fill(Color.red.opacity(0.15))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: "exclamationmark.circle")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.red)
                                        }
                                    } else if isDueSoon {
                                        ZStack {
                                            Circle()
                                                .fill(Color.orange.opacity(0.15))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: "clock")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.orange)
                                        }
                                    } else {
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.15))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: "doc.text")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.blue)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .lineLimit(2)

                                        HStack(spacing: 6) {
                                            Text(course)
                                                .font(.system(size: 12, weight: .medium))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.gray.opacity(0.15))
                                                .cornerRadius(4)

                                            Spacer()

                                            HStack(spacing: 4) {
                                                Image(systemName: isPastDue ? "calendar.badge.exclamationmark" : "calendar")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(isPastDue ? .red : isDueSoon ? .orange : .gray)

                                                Text(dueDateText.replacingOccurrences(of: "T", with: " "))
                                                    .font(.system(size: 12))
                                                    .foregroundColor(isPastDue ? .red : isDueSoon ? .orange : .gray)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        .padding(.leading, 4)
                                }
                                
                                if isExpanded {
                                    VStack(spacing: 12) {
                                        Divider()
                                            .padding(.top, 8)
                                        
                                        HStack(spacing: 0) {
                                            Button(action: {}) {
                                                VStack(spacing: 4) {
                                                    Image(systemName: "checkmark.circle")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.green)
                                                    Text("Mark Done")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.primary)
                                                }
                                                .frame(maxWidth: .infinity)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Button(action: {}) {
                                                VStack(spacing: 4) {
                                                    Image(systemName: "bell")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.blue)
                                                    Text("Remind Me")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.primary)
                                                }
                                                .frame(maxWidth: .infinity)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Button(action: {}) {
                                                VStack(spacing: 4) {
                                                    Image(systemName: "arrow.right.circle")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.purple)
                                                    Text("View Details")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.primary)
                                                }
                                                .frame(maxWidth: .infinity)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding(12)
                            .background(Color(hoveredAssignment == assignmentLine ? (isPastDue ? .red : isDueSoon ? .orange : .blue) : .gray).opacity(hoveredAssignment == assignmentLine ? 0.08 : 0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(isPastDue ? .red : isDueSoon ? .orange : .blue).opacity(0.3), lineWidth: isExpanded ? 1 : 0)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                hoveredAssignment = hovering ? assignmentLine : nil
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 400)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(bubbleColor)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
        .contextMenu {
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.message, forType: .string)
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }
}

private struct MessageContentView: View {
    let message: ChatMessage
    let bubbleColor: Color
    let textColor: Color

    var body: some View {
        VStack(alignment: message.participant == .user ? .trailing : .leading, spacing: 4) {
            if message.pending {
                TypingIndicator()
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Capsule().fill(bubbleColor))
            } else if let toolName = message.toolCallName {
                ToolMessageView(message: message, bubbleColor: bubbleColor, toolName: toolName)
            } else {
                TextMessageView(message: message, bubbleColor: bubbleColor, textColor: textColor)
            }

            if !message.pending {
                Text("\(message.date.formatted(date: .numeric, time: .shortened))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)
            }
        }
    }
}

// MARK: - Tool Message View

private struct ToolMessageView: View {
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

// MARK: - Text Message View



struct TextMessageView: View {
    let message: ChatMessage
    let bubbleColor: Color
    let textColor: Color

    var body: some View {
        Text(message.message)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .foregroundColor(textColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(BubbleShape(isUser: message.participant == .user).fill(bubbleColor))
            .contextMenu {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message.message, forType: .string)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
    }
}

// MARK: - Specialized Tool Views

struct CanvasCoursesView: View {
    let message: ChatMessage
    let bubbleColor: Color
    @State private var selectedCourse: String? = nil
    
    // 1) Helper method to decide background/icon based on course text
    private func style(for courseText: String) -> (Color, String) {
        if courseText.contains("EECS") || courseText.contains("Engineer") {
            return (Color.blue.opacity(0.15), "laptopcomputer")
        } else if courseText.contains("BIO") || courseText.contains("CHEM") {
            return (Color.green.opacity(0.15), "flask")
        } else if courseText.contains("PSYCH") {
            return (Color.purple.opacity(0.15), "brain")
        } else if courseText.contains("CMPLXSYS") {
            return (Color.orange.opacity(0.15), "network")
        } else if courseText.contains("Community") {
            return (Color.pink.opacity(0.15), "person.3")
        } else if courseText.contains("XR") || courseText.contains("Visual") {
            return (Color.indigo.opacity(0.15), "visionpro")
        } else {
            return (Color.gray.opacity(0.15), "book")
        }
    }
    
    // Course actions popup
    private func courseActionsSheet(for course: String) -> some View {
        let (backgroundColor, _) = style(for: course)
        
        return VStack(spacing: 0) {
            Text(course)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
            
            Divider()
            
            ForEach(courseActions(for: course), id: \.title) { action in
                Button(action: {
                    // Mock action handler
                    selectedCourse = nil
                }) {
                    HStack {
                        Image(systemName: action.icon)
                            .font(.system(size: 18))
                            .foregroundColor(action.color)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(action.title)
                                .font(.system(size: 16, weight: .medium))
                            
                            if let subtitle = action.subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                
                if action.title != courseActions(for: course).last?.title {
                    Divider()
                        .padding(.leading, 50)
                }
            }
            
            Button(action: { selectedCourse = nil }) {
                Text("Cancel")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.secondary)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .padding()
    }
    
    // Generate actions based on course type
    private func courseActions(for course: String) -> [(title: String, subtitle: String?, icon: String, color: Color)] {
        var actions: [(title: String, subtitle: String?, icon: String, color: Color)] = [
            ("View Assignments", "Due soon: 3", "list.clipboard", .blue),
            ("Course Materials", "12 documents", "folder", .orange),
            ("Set Reminders", nil, "bell.badge", .red),
        ]
        
        if course.contains("EECS") || course.contains("CMPLXSYS") {
            actions.append(("Coding Environment", "Open IDE", "hammer.circle", .purple))
        }
        
        if course.contains("BIO") || course.contains("CHEM") {
            actions.append(("Lab Resources", "Protocols & Data", "testtube.2", .green))
        }
        
        if course.contains("Community") {
            actions.append(("Discussion Board", "5 new posts", "bubble.left.and.bubble.right", .teal))
        }
        
        if course.contains("XR") || course.contains("Visual") {
            actions.append(("3D Assets", "Access models", "square.3d.cube", .indigo))
        }
        
        return actions
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Active Canvas Courses")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Divider().padding(.vertical, 4)
            
            let headerLine = "Your active Canvas courses:"
            let coursesText = message.message.replacingOccurrences(of: headerLine, with: "")
            let courses = coursesText
                .components(separatedBy: .newlines)
                .filter { !$0.isEmpty && !$0.contains(headerLine) }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(courses, id: \.self) { course in
                    let courseText = course
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "• ", with: "")

                    let (backgroundColor, iconName) = style(for: courseText)

                    Button(action: {
                        selectedCourse = courseText
                    }) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                // Enhanced icon appearance
                                ZStack {
                                    Circle()
                                        .fill(backgroundColor.opacity(1.5))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: iconName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(backgroundColor.opacity(5))
                                }
                                
                                Text(courseText)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                
                                Spacer()
                            }
                        }
                        .padding(10)
                        .background(backgroundColor.opacity(0.7))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(bubbleColor)
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
        .contextMenu {
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.message, forType: .string)
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        .sheet(item: $selectedCourse.animation()) { course in
            courseActionsSheet(for: course)
                .presentationDetents([.medium])
        }
    }
}

// Extension to make String an Identifiable for sheet presentation
extension String: Identifiable {
    public var id: String { self }
}


struct CalendarCreateEventView: View {
    let message: ChatMessage
    let bubbleColor: Color
    @State private var isExpanded = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Text("New Event Created")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isExpanded {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            
            Divider().padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "text.bubble")
                            .font(.system(size: 14))
                            .foregroundColor(.purple)
                    }
                    
                    Text("Project Meeting")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                    }
                    
                    Text("March 20, 2025")
                        .font(.system(size: 14))
                }
                
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    
                    Text("10:00 AM - 11:30 AM")
                        .font(.system(size: 14))
                }
                
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }
                    
                    Text("Conference Room B")
                        .font(.system(size: 14))
                }
                
                if isExpanded {
                    Divider().padding(.vertical, 8)
                    
                    HStack(spacing: 8) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 14))
                                Text("Accept")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.green)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 14))
                                Text("Decline")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 14))
                                Text("Edit")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "person.2")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Text("3 Attendees")
                            .font(.system(size: 14))
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("View All")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "doc.text")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Text("Project status update and planning")
                            .font(.system(size: 14))
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(bubbleColor)
                .shadow(color: Color.black.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 4 : 2, x: 0, y: isHovered ? 3 : 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.message, forType: .string)
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }
}

struct CalendarEventsView: View {
    let message: ChatMessage
    let bubbleColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Calendar Events")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            Divider().padding(.vertical, 2)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(message.message.components(separatedBy: .newlines).filter { !$0.isEmpty }, id: \.self) { eventLine in
                        HStack(alignment: .top, spacing: 10) {
                            let components = eventLine.components(separatedBy: " @ ")
                            let eventName = components.first?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "• ", with: "") ?? ""
                            let dateTimeLocation = components.count > 1 ? components[1] : ""
                            Image(systemName: "calendar.badge.clock")
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                                .padding(6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(eventName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                if !dateTimeLocation.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                        Text(dateTimeLocation)
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(bubbleColor))
    }
}

//private struct CalendarCreateEventView: View {
//    let message: ChatMessage
//    let bubbleColor: Color
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Image(systemName: "calendar.badge.plus")
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundColor(.blue)
//                Text("New Event Created")
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                Spacer()
//            }
//
//            Divider().padding(.vertical, 4)
//
//            HStack(alignment: .top, spacing: 12) {
//                VStack(alignment: .leading, spacing: 8) {
//                    HStack(spacing: 6) {
//                        Image(systemName: "text.bubble")
//                            .frame(width: 20)
//                            .foregroundColor(.gray)
//                        Text("Project Meeting")
//                            .font(.system(size: 15, weight: .medium))
//                    }
//
//                    HStack(spacing: 6) {
//                        Image(systemName: "calendar")
//                            .frame(width: 20)
//                            .foregroundColor(.gray)
//                        Text("March 20, 2025")
//                            .font(.system(size: 14))
//                    }
//
//                    HStack(spacing: 6) {
//                        Image(systemName: "clock")
//                            .frame(width: 20)
//                            .foregroundColor(.gray)
//                        Text("10:00 AM - 11:30 AM")
//                            .font(.system(size: 14))
//                    }
//
//                    HStack(spacing: 6) {
//                        Image(systemName: "mappin.and.ellipse")
//                            .frame(width: 20)
//                            .foregroundColor(.gray)
//                        Text("Conference Room B")
//                            .font(.system(size: 14))
//                    }
//                }
//            }
//        }
//        .padding(.vertical, 10)
//        .padding(.horizontal, 14)
//        .background(RoundedRectangle(cornerRadius: 12).fill(bubbleColor))
//        .contextMenu {
//            Button(action: {
//                NSPasteboard.general.clearContents()
//                NSPasteboard.general.setString(message.message, forType: .string)
//            }) {
//                Label("Copy", systemImage: "doc.on.doc")
//            }
//        }
//    }
//}
//
//private struct CalendarEventsView: View {
//    let message: ChatMessage
//    let bubbleColor: Color
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Image(systemName: "calendar")
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundColor(.blue)
//                Text("Calendar Events")
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                Spacer()
//            }
//
//            Divider().padding(.vertical, 2)
//
//            let events = message.message
//                .components(separatedBy: .newlines)
//                .filter { !$0.isEmpty }
//
//            ScrollView {
//                VStack(alignment: .leading, spacing: 10) {
//                    ForEach(events, id: \.self) { eventLine in
//                        HStack(alignment: .top, spacing: 10) {
//                            let components = eventLine.components(separatedBy: " @ ")
//                            let eventName = components.first?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "• ", with: "") ?? ""
//                            let dateTimeLocation = components.count > 1 ? components[1] : ""
//
//                            let iconName: String
//                            if eventName.contains("Meeting") {
//                                iconName = "person.2"
//                            } else if eventName.contains("EECS") || eventName.contains("CMPLXSYS") || eventName.contains("PSYCH") {
//                                iconName = "book"
//                            } else if eventName.contains("Ljungman") {
//                                iconName = "building.2"
//                            } else if eventName.contains("Patrick") || eventName.contains("Paddy") {
//                                iconName = "party.popper"
//                            } else {
//                                iconName = "calendar.badge.clock"
//                            }
//
//                            Image(systemName: iconName)
//                                .frame(width: 24, height: 24)
//                                .foregroundColor(.blue)
//                                .padding(6)
//                                .background(Color.blue.opacity(0.1))
//                                .cornerRadius(8)
//
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(eventName)
//                                    .font(.system(size: 14, weight: .medium))
//                                    .foregroundColor(.primary)
//
//                                if !dateTimeLocation.isEmpty {
//                                    HStack(spacing: 4) {
//                                        Image(systemName: "clock")
//                                            .font(.system(size: 10))
//                                            .foregroundColor(.gray)
//                                        Text(dateTimeLocation)
//                                            .font(.system(size: 12))
//                                            .foregroundColor(.gray)
//                                    }
//                                }
//                            }
//
//                            Spacer()
//                        }
//                        .padding(8)
//                        .background(Color.gray.opacity(0.05))
//                        .cornerRadius(8)
//                    }
//                }
//            }
//            .frame(maxHeight: 400)
//        }
//        .padding(.vertical, 10)
//        .padding(.horizontal, 14)
//        .background(RoundedRectangle(cornerRadius: 12).fill(bubbleColor))
//        .contextMenu {
//            Button(action: {
//                NSPasteboard.general.clearContents()
//                NSPasteboard.general.setString(message.message, forType: .string)
//            }) {
//                Label("Copy", systemImage: "doc.on.doc")
//            }
//        }
//    }
//}

private struct GenericToolMessageView: View {
    let message: ChatMessage
    let bubbleColor: Color
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
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .foregroundColor(.primary)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(BubbleShape(isUser: message.participant == .user).fill(bubbleColor))
        .contextMenu {
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.message, forType: .string)
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }
}



// MARK: - Supporting Views

struct BubbleShape: Shape {
    var isUser: Bool

    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 12
        let minX = rect.minX
        let minY = rect.minY
        let maxX = rect.maxX
        let maxY = rect.maxY

        let path = Path { p in
            if isUser {
                // User message (right corner)
                p.move(to: CGPoint(x: minX + cornerRadius, y: minY))
                p.addLine(to: CGPoint(x: maxX - cornerRadius - 4, y: minY))
                p.addCurve(
                    to: CGPoint(x: maxX, y: minY + cornerRadius),
                    control1: CGPoint(x: maxX - 4, y: minY),
                    control2: CGPoint(x: maxX, y: minY + 4)
                )
                p.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
                p.addCurve(
                    to: CGPoint(x: maxX - cornerRadius, y: maxY),
                    control1: CGPoint(x: maxX, y: maxY - 4),
                    control2: CGPoint(x: maxX - 4, y: maxY)
                )
                p.addLine(to: CGPoint(x: minX + cornerRadius, y: maxY))
                p.addCurve(
                    to: CGPoint(x: minX, y: maxY - cornerRadius),
                    control1: CGPoint(x: minX + 4, y: maxY),
                    control2: CGPoint(x: minX, y: maxY - 4)
                )
                p.addLine(to: CGPoint(x: minX, y: minY + cornerRadius))
                p.addCurve(
                    to: CGPoint(x: minX + cornerRadius, y: minY),
                    control1: CGPoint(x: minX, y: minY + 4),
                    control2: CGPoint(x: minX + 4, y: minY)
                )
            } else {
                // AI message (left corner)
                p.move(to: CGPoint(x: minX + cornerRadius, y: minY))
                p.addLine(to: CGPoint(x: maxX - cornerRadius, y: minY))
                p.addCurve(
                    to: CGPoint(x: maxX, y: minY + cornerRadius),
                    control1: CGPoint(x: maxX - 4, y: minY),
                    control2: CGPoint(x: maxX, y: minY + 4)
                )
                p.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
                p.addCurve(
                    to: CGPoint(x: maxX - cornerRadius, y: maxY),
                    control1: CGPoint(x: maxX, y: maxY - 4),
                    control2: CGPoint(x: maxX - 4, y: maxY)
                )
                p.addLine(to: CGPoint(x: minX + cornerRadius + 4, y: maxY))
                p.addCurve(
                    to: CGPoint(x: minX, y: maxY - cornerRadius),
                    control1: CGPoint(x: minX + 4, y: maxY),
                    control2: CGPoint(x: minX, y: maxY - 4)
                )
                p.addLine(to: CGPoint(x: minX, y: minY + cornerRadius))
                p.addCurve(
                    to: CGPoint(x: minX + cornerRadius, y: minY),
                    control1: CGPoint(x: minX, y: minY + 4),
                    control2: CGPoint(x: minX + 4, y: minY)
                )
            }
            p.closeSubpath()
        }
        return path
    }
}

struct Avatar: View {
    let participant: ChatMessage.Participant
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    participant == .user
                        ? Color(hex: "5E5CE6")
                        : (colorScheme == .dark ? Color(hex: "5A5A5A") : Color(hex: "D8D8D8"))
                )
                .frame(width: 28, height: 28)

            if participant == .user {
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationOffset = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .opacity(0.7)
                    .offset(y: animationOffset * (index == 1 ? 1.5 : 1))
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                animationOffset = -5
            }
        }
    }
}
