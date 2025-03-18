//
//  PetalFetchRemindersTool.swift
//  PetalTools
//
// Created by Aadi Shiv Malhotra on 3/11/25.
//

import Foundation
import EventKit

public final class PetalFetchRemindersTool: OllamaCompatibleTool {
    
    public init() {}
    
    // MARK: - Ollama Tool Definition
    
    public func asOllamaTool() -> OllamaTool {
        return OllamaTool(
            type: "function",
            function: OllamaFunction(
                name: id,
                description: description,
                parameters: OllamaFunctionParameters(
                    type: "object",
                    properties: [
                        "completed": OllamaFunctionProperty(
                            type: "boolean",
                            description: "If true, fetch completed reminders. If false, fetch incomplete reminders. If omitted, fetch all reminders."
                        ),
                        "startDate": OllamaFunctionProperty(
                            type: "string",
                            description: "ISO date string for filtering reminders from a specific start date."
                        ),
                        "endDate": OllamaFunctionProperty(
                            type: "string",
                            description: "ISO date string for filtering reminders up to a specific end date."
                        ),
                        "listNames": OllamaFunctionProperty(
                            type: "array",
                            description: "Optional list of reminder lists to fetch from."
                        ),
                        "searchText": OllamaFunctionProperty(
                            type: "string",
                            description: "Optional search query to match reminders by title."
                        )
                    ],
                    required: [] // No required fields in this case
                )
            )
        )
    }

    
    // MARK: - OllamaCompatibleTool Protocol
    
    public let uuid: UUID = .init()
    public var id: String { "petalFetchRemindersTool" }
    public var name: String { "Petal Fetch Reminders Tool" }
    public var description: String { "Fetches reminders from the Reminders app with optional filtering." }
    public var triggerKeywords: [String] { ["reminders", "tasks", "list reminders"] }
    public var domain: String { "reminders" }
    public var requiredPermission: PetalToolPermission { .basic }
    
    // MARK: - Parameter Definitions

    public var parameters: [PetalToolParameter] {
        [
            PetalToolParameter(
                name: "completed",
                description: "If true, fetch completed reminders. If false, fetch incomplete reminders. If omitted, fetch all reminders.",
                dataType: .boolean,
                required: false,
                example: AnyCodable(true)
            ),
            PetalToolParameter(
                name: "startDate",
                description: "ISO date string for filtering reminders from a specific start date.",
                dataType: .string,
                required: false,
                example: AnyCodable("2025-03-10T00:00:00Z")
            ),
            PetalToolParameter(
                name: "endDate",
                description: "ISO date string for filtering reminders up to a specific end date.",
                dataType: .string,
                required: false,
                example: AnyCodable("2025-03-20T23:59:59Z")
            ),
            PetalToolParameter(
                name: "listNames",
                description: "Optional list of reminder lists to fetch from.",
                dataType: .array,
                required: false,
                example: AnyCodable(["Work", "Personal"])
            ),
            PetalToolParameter(
                name: "searchText",
                description: "Optional search query to match reminders by title.",
                dataType: .string,
                required: false,
                example: AnyCodable("Doctor appointment")
            )
        ]
    }

    // MARK: - Execution Logic
    
    public struct Input: Codable, Sendable {
        public let completed: Bool?
        public let startDate: String?
        public let endDate: String?
        public let listNames: [String]?
        public let searchText: String?
    }

    public struct ReminderOutput: Codable, Sendable {
        public let title: String
        public let dueDate: String?
        public let completed: Bool
    }

    public struct Output: Codable, Sendable {
        public let reminders: [ReminderOutput]
    }


//    public func execute(_ input: Input) async throws -> Output {
//        let eventStore = EKEventStore()
//        try await eventStore.requestFullAccessToEvents()
//        try await eventStore.requestFullAccessToReminders()
//
//        let reminderLists = eventStore.calendars(for: .reminder)
//        let predicate = eventStore.predicateForReminders(in: reminderLists)
//
//        let reminders = try await withCheckedThrowingContinuation { continuation in
//            eventStore.fetchReminders(matching: predicate) { fetchedReminders in
//                continuation.resume(returning: fetchedReminders ?? [])
//            }
//        }
//
//        let filteredReminders = reminders
//            .filter { input.completed == nil || $0.isCompleted == input.completed }
//            .filter { input.searchText == nil || $0.title.contains(input.searchText!) }
//
//        let outputReminders = filteredReminders.map {
//            ReminderOutput(
//                title: $0.title,
//                dueDate: $0.dueDateComponents?.date?.description,
//                completed: $0.isCompleted
//            )
//        }
//
//        return Output(reminders: outputReminders)
//    }
    
    public func execute(_ input: Input) async throws -> Output {
        let eventStore = EKEventStore()
        try await eventStore.requestFullAccessToEvents()
        try await eventStore.requestFullAccessToReminders()

        // Build your predicate for fetching
        let reminderLists = eventStore.calendars(for: .reminder)
        let predicate = eventStore.predicateForReminders(in: reminderLists)

        // Fetch & filter *inside* the continuation
        let outputReminders = try await withCheckedThrowingContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { fetchedReminders in
                let reminders = fetchedReminders ?? []

                // Filter reminders
//                let filteredReminders = reminders
//                    .filter { input.completed == nil || $0.isCompleted == input.completed }
//                    .filter { input.searchText == nil || $0.title.contains(input.searchText!) }

                // Convert them to `ReminderOutput` so we don't return raw `EKReminder`
                let finalReminders = reminders.map {
                    ReminderOutput(
                        title: $0.title,
                        dueDate: $0.dueDateComponents?.date?.description,
                        completed: $0.isCompleted
                    )
                }

                // Return the plain Swift array
                continuation.resume(returning: finalReminders)
            }
        }

        // Now just wrap in your Output struct
        return Output(reminders: outputReminders)
    }

}
