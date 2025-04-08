//
//  MobileCanvasCoursesView.swift
//  PetalsiOS
//
//  Created for iOS
//

import SwiftUI
import PetalCore

struct IdentifiableCourse: Identifiable, CustomStringConvertible {
    let id = UUID()
    let name: String
    
    var description: String {
        return name
    }
}


struct MobileCanvasCoursesView: View {
    let message: ChatMessage
    
    @State private var selectedCourse: IdentifiableCourse? = nil

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

            LazyVGrid(columns: [GridItem(.flexible())], spacing: 10) {
                ForEach(courses, id: \.self) { course in
                    let courseText = course
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "• ", with: "")

                    let (backgroundColor, iconName) = style(for: courseText)

                    Button(action: {
                        selectedCourse = IdentifiableCourse(name: courseText)
                    }) {
                        HStack(spacing: 12) {
                            // Enhanced icon appearance
                            ZStack {
                                Circle()
                                    .fill(backgroundColor.opacity(1.5))
                                    .frame(width: 36, height: 36)

                                Image(systemName: iconName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(backgroundColor.opacity(5))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(courseText)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                
                                Text("Active")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(backgroundColor.opacity(0.7))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
        .sheet(item: $selectedCourse.animation()) { course in
            NavigationView {
                courseActionsView(for: course.name)
                    .navigationTitle(course.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                selectedCourse = nil
                            }
                        }
                    }
            }
        }
    }
    
    // Course actions view
    private func courseActionsView(for course: String) -> some View {
        let (backgroundColor, _) = style(for: course)
        
        return List {
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
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
} 
