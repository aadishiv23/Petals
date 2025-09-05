//
//  PetalRemindersTool_iOS.swift
//  PetalTools
//
//  Created for iOS using EventKit
//

#if os(iOS)
import Foundation
import EventKit
import UIKit
import PetalCore

/// iOS implementation of Reminders tool using EventKit
public final class PetalRemindersTool: OllamaCompatibleTool, MLXCompatibleTool {
    public init() {}

    // MARK: PetalTool metadata
    public let uuid: UUID = .init()
    public var id: String { "petalRemindersTool" }
    public var name: String { "Petal Reminders Tool" }
    public var description: String { "Interact with Reminders on iOS (lists, search, create, open)." }
    public var triggerKeywords: [String] { ["reminder", "reminders", "task", "todo"] }
    public var domain: String { "reminders" }
    public var requiredPermission: PetalToolPermission { .basic }

    public var parameters: [PetalToolParameter] {
        [
            .init(name: "action", description: "getAllLists|getAllReminders|searchReminders|createReminder|openReminder", dataType: .string, required: true, example: AnyCodable("searchReminders")),
            .init(name: "listName", description: "List to use for getAllReminders/createReminder", dataType: .string, required: false, example: AnyCodable("Personal")),
            .init(name: "searchText", description: "Query for search/open", dataType: .string, required: false, example: AnyCodable("groceries")),
            .init(name: "name", description: "Reminder title for create", dataType: .string, required: false, example: AnyCodable("Call Mom")),
            .init(name: "notes", description: "Notes for create", dataType: .string, required: false, example: AnyCodable("Discuss travel")),
            .init(name: "dueDate", description: "ISO date for create", dataType: .string, required: false, example: AnyCodable("2025-04-15T14:00:00Z"))
        ]
    }

    // MARK: IO Types
    public struct Input: Codable, Sendable {
        public let action: String
        public let listName: String?
        public let searchText: String?
        public let name: String?
        public let notes: String?
        public let dueDate: String?
    }

    public struct Output: Codable, Sendable { public let result: String }

    // MARK: Execute
    public func execute(_ input: Input) async throws -> Output {
        let store = EKEventStore()
        try await requestAccess(store)

        switch input.action {
        case "getAllLists":
            let calendars = store.calendars(for: .reminder)
            let names = calendars.map { $0.title }.sorted()
            if names.isEmpty { return Output(result: "No reminder lists found.") }
            return Output(result: names.enumerated().map { "[\($0.offset+1)] \($0.element)" }.joined(separator: "\n"))

        case "getAllReminders":
            let cals = calendars(for: store, listName: input.listName)
            let items = try await fetchReminders(store: store, calendars: cals)
            return Output(result: format(reminders: items))

        case "searchReminders":
            guard let q = input.searchText?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty else {
                return Output(result: "Error: searchText is required for searchReminders")
            }
            let items = try await fetchReminders(store: store, calendars: calendars(for: store, listName: nil))
            let filtered = items.filter { ($0.title?.localizedCaseInsensitiveContains(q) ?? false) || ($0.notes?.localizedCaseInsensitiveContains(q) ?? false) }
            return Output(result: format(reminders: filtered))

        case "createReminder":
            guard let title = input.name?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
                return Output(result: "Error: name is required for createReminder")
            }
            let reminder = EKReminder(eventStore: store)
            reminder.title = title
            if let notes = input.notes, !notes.isEmpty { reminder.notes = notes }
            let calendar = calendars(for: store, listName: input.listName).first ?? store.defaultCalendarForNewReminders()
            reminder.calendar = calendar
            if let dueISO = input.dueDate, let dueDate = ISO8601DateFormatter().date(from: dueISO) {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            }
            try store.save(reminder, commit: true)
            return Output(result: "Created reminder ‘\(title)’ in ‘\(calendar?.title ?? "Reminders")’.")

        case "openReminder":
            // Best-effort: open Reminders app
            await MainActor.run {
                if let url = URL(string: "x-apple-reminderkit://"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            return Output(result: "Opened Reminders app.")

        default:
            return Output(result: "Error: Unsupported action \(input.action)")
        }
    }

    // MARK: Helpers
    private func requestAccess(_ store: EKEventStore) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            store.requestAccess(to: .reminder) { granted, error in
                if let error { cont.resume(throwing: error); return }
                if !granted { cont.resume(throwing: NSError(domain: "Reminders", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied for Reminders"])) ; return }
                cont.resume()
            }
        }
    }

    private func calendars(for store: EKEventStore, listName: String?) -> [EKCalendar] {
        let all = store.calendars(for: .reminder)
        guard let listName, !listName.isEmpty else { return all }
        return all.filter { $0.title.caseInsensitiveCompare(listName) == .orderedSame }
    }

    // Lightweight, Sendable projection of EKReminder
    private struct ReminderInfo: Sendable {
        let title: String?
        let notes: String?
        let isCompleted: Bool
        let calendarTitle: String?
        let dueDateComponents: DateComponents?
    }

    private func fetchReminders(store: EKEventStore, calendars: [EKCalendar]) async throws -> [ReminderInfo] {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[ReminderInfo], Error>) in
            let predicate = store.predicateForReminders(in: calendars)
            store.fetchReminders(matching: predicate) { reminders in
                let infos: [ReminderInfo] = (reminders ?? []).map { r in
                    ReminderInfo(
                        title: r.title,
                        notes: r.notes,
                        isCompleted: r.isCompleted,
                        calendarTitle: r.calendar?.title,
                        dueDateComponents: r.dueDateComponents
                    )
                }
                cont.resume(returning: infos)
            }
        }
    }

    private func format(reminders: [ReminderInfo]) -> String {
        if reminders.isEmpty { return "No reminders found." }
        let formatter = DateFormatter(); formatter.dateStyle = .medium; formatter.timeStyle = .short
        return reminders.enumerated().map { idx, r in
            var lines: [String] = []
            lines.append("[\(idx+1)] \(r.title ?? "(Untitled)")")
            if let cal = r.calendarTitle { lines.append("  List: \(cal)") }
            if let notes = r.notes, !notes.isEmpty { lines.append("  Notes: \(notes)") }
            if let comps = r.dueDateComponents, let date = Calendar.current.date(from: comps) {
                lines.append("  Due: \(formatter.string(from: date))")
            }
            lines.append("  Completed: \(r.isCompleted ? "Yes" : "No")")
            return lines.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }

    // MARK: Tool definitions
    public func asOllamaTool() -> OllamaTool {
        OllamaTool(
            type: "function",
            function: OllamaFunction(
                name: id,
                description: description,
                parameters: OllamaFunctionParameters(
                    type: "object",
                    properties: [
                        "action": .init(type: "string", description: "getAllLists|getAllReminders|searchReminders|createReminder|openReminder"),
                        "listName": .init(type: "string", description: "List name"),
                        "searchText": .init(type: "string", description: "Query"),
                        "name": .init(type: "string", description: "Title for create"),
                        "notes": .init(type: "string", description: "Notes for create"),
                        "dueDate": .init(type: "string", description: "ISO date for create")
                    ],
                    required: ["action"]
                )
            )
        )
    }

    public func asMLXToolDefinition() -> MLXToolDefinition {
        MLXToolDefinition(
            type: "function",
            function: MLXFunctionDefinition(
                name: id,
                description: description,
                parameters: MLXParametersDefinition(
                    type: "object",
                    properties: [
                        "action": .init(type: "string", description: "getAllLists|getAllReminders|searchReminders|createReminder|openReminder"),
                        "listName": .init(type: "string", description: "List name"),
                        "searchText": .init(type: "string", description: "Query"),
                        "name": .init(type: "string", description: "Title for create"),
                        "notes": .init(type: "string", description: "Notes for create"),
                        "dueDate": .init(type: "string", description: "ISO date for create")
                    ],
                    required: ["action"]
                )
            )
        )
    }
}
#endif


