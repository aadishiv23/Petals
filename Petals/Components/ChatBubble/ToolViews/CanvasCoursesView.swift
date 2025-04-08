//
//  CanvasCoursesView.swift
//  Petals
//
//  Created for ChatBubbleView
//

import SwiftUI
import PetalCore

struct CanvasCoursesView: View {
    let message: ChatMessage
    let bubbleColor: Color
    @State private var selectedCourse: String? = nil

    /// 1) Helper method to decide background/icon based on course text
    private func style(for courseText: String) -> (Color, String) {
        if courseText.contains("EECS") || courseText.contains("Engineer") {
            (Color.blue.opacity(0.15), "laptopcomputer")
        } else if courseText.contains("BIO") || courseText.contains("CHEM") {
            (Color.green.opacity(0.15), "flask")
        } else if courseText.contains("PSYCH") {
            (Color.purple.opacity(0.15), "brain")
        } else if courseText.contains("CMPLXSYS") {
            (Color.orange.opacity(0.15), "network")
        } else if courseText.contains("Community") {
            (Color.pink.opacity(0.15), "person.3")
        } else if courseText.contains("XR") || courseText.contains("Visual") {
            (Color.indigo.opacity(0.15), "visionpro")
        } else {
            (Color.gray.opacity(0.15), "book")
        }
    }

    /// Course actions popup
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

    /// Generate actions based on course type
    private func courseActions(for course: String) -> [(title: String, subtitle: String?, icon: String, color: Color)] {
        var actions: [(title: String, subtitle: String?, icon: String, color: Color)] = [
            ("View Assignments", "Due soon: 3", "list.clipboard", .blue),
            ("Course Materials", "12 documents", "folder", .orange),
            ("Set Reminders", nil, "bell.badge", .red)
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