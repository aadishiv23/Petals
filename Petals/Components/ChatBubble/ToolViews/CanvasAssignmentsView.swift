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
                        let title = courseParts.count > 1
                            ? courseParts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            : ""

                        let dueDateText = components.count > 1
                            ? components[1].replacingOccurrences(of: ")", with: "")
                            : "No due date"

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
                                                Image(
                                                    systemName: isPastDue
                                                        ? "calendar.badge.exclamationmark"
                                                        : "calendar"
                                                )
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
                            .background(Color(
                                hoveredAssignment == assignmentLine
                                    ? (isPastDue ? .red : isDueSoon ? .orange : .blue)
                                    : .gray
                            ).opacity(hoveredAssignment == assignmentLine ? 0.08 : 0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color(isPastDue ? .red : isDueSoon ? .orange : .blue).opacity(0.3),
                                        lineWidth: isExpanded ? 1 : 0
                                    )
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