//
//  MobileCanvasAssignmentsView.swift
//  PetalsiOS
//
//  Created for iOS
//

import SwiftUI
import PetalCore

struct MobileCanvasAssignmentsView: View {
    let message: ChatMessage
    @State private var selectedAssignment: CanvasAssignment? = nil
    @State private var selectedFilter: FilterOption = .all

    struct CanvasAssignment: Identifiable {
        let id = UUID()
        let title: String
        let course: String
        let dueDate: String
        let status: AssignmentStatus
        let details: String?

        enum AssignmentStatus: String {
            case upcoming = "Upcoming"
            case pending = "Pending"
            case submitted = "Submitted"
            case graded = "Graded"
            case overdue = "Overdue"

            var color: Color {
                switch self {
                case .upcoming: return .blue
                case .pending: return .orange
                case .submitted: return .green
                case .graded: return .purple
                case .overdue: return .red
                }
            }

            var icon: String {
                switch self {
                case .upcoming: return "calendar"
                case .pending: return "exclamationmark.circle"
                case .submitted: return "checkmark.circle"
                case .graded: return "star.fill"
                case .overdue: return "clock"
                }
            }
        }
    }

    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case upcoming = "Upcoming"
        case pending = "Pending"
        case submitted = "Submitted"
        case graded = "Graded"
        case overdue = "Overdue"

        var id: String { rawValue }
    }

    private func parseAssignments() -> [CanvasAssignment] {
        let lines = message.message.components(separatedBy: .newlines)
        var assignments: [CanvasAssignment] = []

        var currentCourse: String = ""
        var currentTitle: String = ""
        var currentDue: String = "No due date"
        var currentStatus: CanvasAssignment.AssignmentStatus = .upcoming
        var currentDetails: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("• ") {
                // Save previous assignment
                if !currentTitle.isEmpty {
                    assignments.append(CanvasAssignment(
                        title: currentTitle,
                        course: currentCourse,
                        dueDate: currentDue,
                        status: currentStatus,
                        details: currentDetails.joined(separator: "\n")
                    ))
                }

                // Reset for new assignment
                currentDue = "No due date"
                currentStatus = .upcoming
                currentDetails = []

                let content = trimmed.replacingOccurrences(of: "• ", with: "")
                let parts = content.components(separatedBy: " — ")
                currentCourse = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                currentTitle = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            } else if trimmed.hasPrefix("- ") {
                let detail = trimmed.replacingOccurrences(of: "- ", with: "")

                if detail.lowercased().starts(with: "due:") {
                    currentDue = detail.replacingOccurrences(of: "Due:", with: "").trimmingCharacters(in: .whitespaces)
                } else if detail.lowercased().starts(with: "status:") {
                    let statusString = detail.replacingOccurrences(of: "Status:", with: "").trimmingCharacters(in: .whitespaces).lowercased()
                    if statusString.contains("pending") {
                        currentStatus = .pending
                    } else if statusString.contains("submitted") {
                        currentStatus = .submitted
                    } else if statusString.contains("graded") {
                        currentStatus = .graded
                    } else if statusString.contains("overdue") {
                        currentStatus = .overdue
                    } else {
                        currentStatus = .upcoming
                    }
                } else {
                    currentDetails.append(detail)
                }
            }
        }

        // Append last one if needed
        if !currentTitle.isEmpty {
            assignments.append(CanvasAssignment(
                title: currentTitle,
                course: currentCourse,
                dueDate: currentDue,
                status: currentStatus,
                details: currentDetails.joined(separator: "\n")
            ))
        }

        return assignments
    }

    private var filteredAssignments: [CanvasAssignment] {
        let assignments = parseAssignments()

        if selectedFilter == .all {
            return assignments
        } else {
            return assignments.filter { $0.status.rawValue == selectedFilter.rawValue }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "list.clipboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Canvas Assignments")
                    .font(.headline)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FilterOption.allCases) { option in
                        Button {
                            selectedFilter = option
                        } label: {
                            Text(option.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedFilter == option ? Color.blue.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                                )
                                .foregroundColor(selectedFilter == option ? .blue : .primary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()

            let assignments = filteredAssignments

            if assignments.isEmpty {
                Text("No assignments found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(assignments) { assignment in
                        Button {
                            selectedAssignment = assignment
                        } label: {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(assignment.status.color.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: assignment.status.icon)
                                        .foregroundColor(assignment.status.color)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(assignment.title)
                                        .font(.system(size: 16, weight: .medium))
                                        .lineLimit(1)

                                    Text(assignment.course)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    HStack {
                                        Text(assignment.dueDate)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(assignment.status.rawValue)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(assignment.status.color.opacity(0.1))
                                            .foregroundColor(assignment.status.color)
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.leading, 8)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
        .sheet(item: $selectedAssignment) { assignment in
            NavigationView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(assignment.course)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))

                            Spacer()

                            Text(assignment.status.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }

                        Text(assignment.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Due: \(assignment.dueDate)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(assignment.status.color)

                    List {
                        if let details = assignment.details, !details.isEmpty {
                            Section(header: Text("Assignment Details")) {
                                Text(details)
                                    .font(.body)
                            }
                        }

                        Section {
                            Button {
                                // Open in Canvas
                            } label: {
                                Label("Open in Canvas", systemImage: "safari")
                            }

                            Button {
                                // Set reminder
                            } label: {
                                Label("Set Reminder", systemImage: "bell.badge")
                            }

                            if assignment.status != .submitted && assignment.status != .graded {
                                Button {
                                    // Submit assignment
                                } label: {
                                    Label("Submit Assignment", systemImage: "paperplane")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            selectedAssignment = nil
                        }
                    }
                }
            }
        }
    }
}
