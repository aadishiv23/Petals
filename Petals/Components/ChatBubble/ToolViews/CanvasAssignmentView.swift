//
//  CanvasAssignmentsView.swift
//  Petals
//
//  Created for ChatBubbleView
//

import SwiftUI
import PetalCore

struct CanvasAssignmentsView: View {
    let message: ChatMessage
    let bubbleColor: Color
    @State private var expandedAssignment: String? = nil
    @State private var hoveredAssignment: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HeaderView()
            
            Divider()
                .padding(.vertical, 2)
            
            let assignments = parseAssignments(from: message.message)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(assignments, id: \.id) { assignment in
                        AssignmentCardView(
                            assignment: assignment,
                            expandedAssignment: $expandedAssignment,
                            hoveredAssignment: $hoveredAssignment
                        )
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
    
    private func parseAssignments(from message: String) -> [AssignmentData] {
        // Group assignments by parsing the message string
        var assignments: [AssignmentData] = []
        var currentAssignment: AssignmentData?
        var currentDetails: [String] = []
        
        let lines = message.components(separatedBy: .newlines)
            .filter { !$0.isEmpty && !$0.starts(with: "I updated") }
        
        for line in lines {
            if line.starts(with: "• ") {
                // Save previous assignment if it exists
                if let assignment = currentAssignment {
                    assignments.append(assignment)
                }
                
                // Start new assignment
                let titleLine = line.replacingOccurrences(of: "• ", with: "")
                let parts = titleLine.components(separatedBy: " — ")
                let course = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let title = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                
                currentAssignment = AssignmentData(
                    id: UUID().uuidString,
                    title: title,
                    course: course,
                    details: []
                )
                currentDetails = []
            } else if line.starts(with: "  - ") {
                // Add detail to current assignment
                currentDetails.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        
        // Add the last assignment
        if let assignment = currentAssignment {
            assignment.details = currentDetails
            assignments.append(assignment)
        }
        
        return assignments
    }
    
    // MARK: - Subviews
    
    private struct HeaderView: View {
        var body: some View {
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
        }
    }
    
    private struct AssignmentCardView: View {
        let assignment: AssignmentData
        @Binding var expandedAssignment: String?
        @Binding var hoveredAssignment: String?
        
        private var isExpanded: Bool {
            expandedAssignment == assignment.id
        }
        
        private var isHovered: Bool {
            hoveredAssignment == assignment.id
        }
        
        // Get due date from details if available
        private var dueDateInfo: (text: String, isPastDue: Bool, isDueSoon: Bool) {
            for detail in assignment.details {
                if detail.starts(with: "Due:") {
                    let dateText = detail.replacingOccurrences(of: "Due:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let isPastDue = dateText.contains("Feb") || dateText.contains("Jan")
                    let isDueSoon = dateText.contains("Mar 21")
                    return (dateText, isPastDue, isDueSoon)
                }
            }
            return ("No due date", false, false)
        }
        
        var body: some View {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if expandedAssignment == assignment.id {
                        expandedAssignment = nil
                    } else {
                        expandedAssignment = assignment.id
                    }
                }
            }) {
                VStack(alignment: .leading, spacing: 0) {
                    // Main row content - always visible
                    HStack(alignment: .top, spacing: 10) {
                        StatusIconView(
                            isPastDue: dueDateInfo.isPastDue,
                            isDueSoon: dueDateInfo.isDueSoon
                        )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(assignment.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            HStack(spacing: 6) {
                                Text(assignment.course)
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(4)
                                
                                Spacer()
                                
                                if dueDateInfo.text != "No due date" {
                                    HStack(spacing: 4) {
                                        Image(systemName: dueDateInfo.isPastDue ? "calendar.badge.exclamationmark" : "calendar")
                                            .font(.system(size: 11))
                                            .foregroundColor(dueDateInfo.isPastDue ? .red : dueDateInfo.isDueSoon ? .orange : .gray)
                                        
                                        Text(dueDateInfo.text)
                                            .font(.system(size: 12))
                                            .foregroundColor(dueDateInfo.isPastDue ? .red : dueDateInfo.isDueSoon ? .orange : .gray)
                                    }
                                } else {
                                    Text("No due date")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                    }
                    
                    // Expanded details
                    if isExpanded {
                        ExpandedDetailsView(details: assignment.details)
                    }
                }
                .padding(12)
                .background(Color(
                    isHovered
                    ? (dueDateInfo.isPastDue ? .red : dueDateInfo.isDueSoon ? .orange : .blue)
                    : .gray
                ).opacity(isHovered ? 0.08 : 0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color(dueDateInfo.isPastDue ? .red : dueDateInfo.isDueSoon ? .orange : .blue).opacity(0.3),
                            lineWidth: isExpanded ? 1 : 0
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    hoveredAssignment = hovering ? assignment.id : nil
                }
            }
        }
    }
    
    private struct StatusIconView: View {
        let isPastDue: Bool
        let isDueSoon: Bool
        
        var body: some View {
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
        }
    }
    
    private struct ExpandedDetailsView: View {
        let details: [String]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Divider()
                    .padding(.top, 8)
                
                // Display all assignment details
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(details, id: \.self) { detail in
                        let components = detail.components(separatedBy: ":")
                        if components.count > 1 {
                            HStack(alignment: .top) {
                                Text(components[0] + ":")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                
                                Text(components[1...].joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines))
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 2)
                        } else {
                            Text(detail)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                // Action buttons
                HStack(spacing: 12) {
                    ActionButtonView(
                        iconName: "checkmark.circle",
                        text: "Mark Done",
                        color: .green
                    )
                    
                    ActionButtonView(
                        iconName: "bell",
                        text: "Remind Me",
                        color: .blue
                    )
                    
                    ActionButtonView(
                        iconName: "arrow.right.circle",
                        text: "View Details",
                        color: .purple
                    )
                }
            }
            .padding(.top, 8)
        }
    }
    
    private struct ActionButtonView: View {
        let iconName: String
        let text: String
        let color: Color
        
        var body: some View {
            Button(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                    
                    Text(text)
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(color.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Model
    
    private class AssignmentData: Identifiable {
        let id: String
        let title: String
        let course: String
        var details: [String]
        
        init(id: String, title: String, course: String, details: [String]) {
            self.id = id
            self.title = title
            self.course = course
            self.details = details
        }
    }
}
