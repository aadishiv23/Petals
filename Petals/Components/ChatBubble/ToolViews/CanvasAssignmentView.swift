//
//  CanvasAssignmentsView.swift
//  Petals
//
//  Created for ChatBubbleView
//

import PetalCore
import SwiftUI

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

            if assignments.isEmpty {
                Text("No assignments found")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding()
            } else {
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
        var assignments: [AssignmentData] = []

        // Clean the input message by removing any potential system markers
        let cleanedMessage = message.replacingOccurrences(
            of: "Raw JSON tool call.*cvm: msg is:",
            with: "",
            options: .regularExpression
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract course name
        var courseName = "EECS 449 001 WN 2025" // Default course name
        if let courseRange = cleanedMessage.range(of: "Course:.*?(?=\\n\\n|$)", options: .regularExpression) {
            courseName = String(cleanedMessage[courseRange])
                .replacingOccurrences(of: "Course:", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Split by assignment (starting with •)
        let assignmentBlocks = cleanedMessage.components(separatedBy: "\n\n• ")
            .flatMap { $0.components(separatedBy: "\n• ") }
            .filter { !$0.isEmpty }

        for (index, blockText) in assignmentBlocks.enumerated() {
            var block = blockText

            // For first item, we may need to handle "Course:" prefix
            if index == 0, block.hasPrefix("Course:") {
                if let range = block.range(of: "\n\n") {
                    block = String(block[range.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if !block.hasPrefix("•") {
                    block = "• " + block
                }
            }

            // Normalize block by ensuring it starts with a bullet
            if !block.hasPrefix("• "), !block.hasPrefix("•") {
                block = "• " + block
            }

            // Extract title (first line after the bullet)
            var title = ""
            var details: [String] = []
            var dueDate = ""
            var points = ""
            var types = ""
            var link = ""
            var description = ""

            let lines = block.components(separatedBy: .newlines)

            if !lines.isEmpty {
                // Extract title (first line after the bullet)
                title = lines[0].replacingOccurrences(of: "^•\\s*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                var inDescription = false
                var descriptionText = ""

                // Process remaining lines for details
                for i in 1..<lines.count {
                    let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)

                    if line.isEmpty {
                        continue
                    }

                    if line.hasPrefix("- ") {
                        let detail = line.replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression)
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        details.append(detail)

                        // Extract specific details
                        if detail.hasPrefix("Due:") {
                            dueDate = detail.replacingOccurrences(of: "Due:", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                        } else if detail.hasPrefix("Points:") {
                            points = detail.replacingOccurrences(of: "Points:", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                        } else if detail.hasPrefix("Types:") {
                            types = detail.replacingOccurrences(of: "Types:", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                        } else if detail.hasPrefix("Link:") {
                            link = detail.replacingOccurrences(of: "Link:", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                        } else if detail.hasPrefix("Description:") {
                            inDescription = true
                            descriptionText = detail.replacingOccurrences(of: "Description:", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    } else if inDescription {
                        // Continue appending to description if we're in a description block
                        descriptionText += "\n" + line
                    }
                }

                description = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)

                // Create assignment data
                let assignment = AssignmentData(
                    id: UUID().uuidString,
                    title: title,
                    course: courseName,
                    details: details,
                    dueDate: dueDate,
                    points: points,
                    link: link,
                    types: types,
                    description: description
                )

                assignments.append(assignment)
            }
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

        /// Get due date from the assignment data
        private var dueDateInfo: (text: String, isPastDue: Bool, isDueSoon: Bool) {
            if !assignment.dueDate.isEmpty {
                let dateText = assignment.dueDate

                // Parse the date from the text
                let dateFormatter = DateFormatter()

                // Try to parse the date with different formats since Canvas might use different formats
                var dueDate: Date?
                let possibleFormats = [
                    "MMM dd, yyyy 'at' h:mm a",
                    "MMM d, yyyy 'at' h:mm a",
                    "MMM dd, yyyy",
                    "MMM d, yyyy"
                ]

                for format in possibleFormats {
                    dateFormatter.dateFormat = format
                    if let parsedDate = dateFormatter.date(from: dateText) {
                        dueDate = parsedDate
                        break
                    }
                }

                if let dueDate {
                    // Get current date
                    let currentDate = Date()

                    // Calculate days difference
                    let calendar = Calendar.current
                    let daysDifference = calendar.dateComponents([.day], from: currentDate, to: dueDate).day ?? 0

                    // Past due if before current date
                    let isPastDue = dueDate < currentDate

                    // Due soon if within next 3 days
                    let isDueSoon = daysDifference >= 0 && daysDifference <= 3

                    return (dateText, isPastDue, isDueSoon)
                } else {
                    // Couldn't parse the date, just use the text
                    return (dateText, false, false)
                }
            }
            return ("No due date", false, false)
        }

        /// Display points directly from assignment data
        private var pointsInfo: String {
            assignment.points.isEmpty ? "No points" : assignment.points
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

                                // Add points info
                                Text(pointsInfo)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)

                                Spacer()

                                if dueDateInfo.text != "No due date" {
                                    HStack(spacing: 4) {
                                        Image(
                                            systemName: dueDateInfo.isPastDue
                                                ? "calendar.badge.exclamationmark"
                                                : "calendar"
                                        )
                                        .font(.system(size: 11))
                                        .foregroundColor(
                                            dueDateInfo.isPastDue
                                                ? .red
                                                : dueDateInfo.isDueSoon ? .orange : .gray
                                        )

                                        Text(dueDateInfo.text)
                                            .font(.system(size: 12))
                                            .foregroundColor(
                                                dueDateInfo.isPastDue
                                                    ? .red
                                                    : dueDateInfo.isDueSoon ? .orange : .gray
                                            )
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

                    // Preview of assignment type even when not expanded
                    if !isExpanded {
                        getAssignmentTypeView()
                            .padding(.top, 6)
                            .padding(.leading, 46)
                    }

                    // Expanded details
                    if isExpanded {
                        ExpandedDetailsView(details: assignment.details, link: assignment.link)
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

        /// Helper to get submission type view
        private func getAssignmentTypeView() -> some View {
            let types = assignment.details.first(where: { $0.starts(with: "Types:") })?
                .replacingOccurrences(of: "Types:", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"

            return HStack(spacing: 6) {
                Text(types)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
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
        let link: String

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Divider()
                    .padding(.top, 8)

                // Display all assignment details
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(details, id: \.self) { detail in
                        let components = detail.components(separatedBy: ":")
                        if components.count > 1, !detail.starts(with: "Description:") {
                            HStack(alignment: .top) {
                                Text(components[0] + ":")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)

                                Text(
                                    components[1...].joined(separator: ":")
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                )
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 2)
                        } else if detail.starts(with: "Description:") {
                            // Special handling for description to give it more space
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Description:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)

                                Text(
                                    detail.replacingOccurrences(of: "Description:", with: "")
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                )
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 2)
                            }
                            .padding(.vertical, 4)
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

                    Spacer()

                    if !link.isEmpty {
                        Link(destination: URL(string: link) ?? URL(string: "https://umich.instructure.com")!) {
                            ActionButtonView(
                                iconName: "arrow.right.circle",
                                text: "View Details",
                                color: .purple
                            )
                        }
                    } else {
                        ActionButtonView(
                            iconName: "arrow.right.circle",
                            text: "View Details",
                            color: .purple
                        )
                    }
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
    }

    // MARK: - Model

    private class AssignmentData: Identifiable {
        let id: String
        let title: String
        let course: String
        var details: [String]
        var dueDate: String
        var points: String
        var link: String
        var types: String
        var description: String

        init(
            id: String,
            title: String,
            course: String,
            details: [String],
            dueDate: String = "",
            points: String = "",
            link: String = "",
            types: String = "",
            description: String = ""
        ) {
            self.id = id
            self.title = title
            self.course = course
            self.details = details
            self.dueDate = dueDate
            self.points = points
            self.link = link
            self.types = types
            self.description = description
        }
    }
}
