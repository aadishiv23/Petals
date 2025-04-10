//
//  PetalRemindersTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 4/9/25.
//

#if os(macOS)
import AppKit
import Foundation
import PetalCore
import os

/// A tool to interact with Apple Reminders app.
public final class PetalRemindersTool: OllamaCompatibleTool, MLXCompatibleTool {

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.Petal.PetalTools",
        category: "PetalRemindersTool"
    )

    public init() {}

    // MARK: - PetalTool Protocol

    public let uuid: UUID = .init()
    public var id: String { "petalRemindersTool" }
    public var name: String { "Petal Reminders Tool" }
    public var description: String { "Allows interaction with Apple Reminders app (find, create, list, and open reminders)." }
    public var triggerKeywords: [String] { ["reminders", "reminder", "task", "tasks", "todo", "todos"] }
    public var domain: String { "reminders" }
    public var requiredPermission: PetalToolPermission { .basic }

    // MARK: - Parameter Definitions

    public var parameters: [PetalToolParameter] {
        [
            PetalToolParameter(
                name: "action",
                description: "The action to perform: 'getAllLists', 'getAllReminders', 'searchReminders', 'createReminder', or 'openReminder'",
                dataType: .string,
                required: true,
                example: AnyCodable("createReminder")
            ),
            PetalToolParameter(
                name: "listName",
                description: "Name of the reminder list to work with",
                dataType: .string,
                required: false,
                example: AnyCodable("Work")
            ),
            PetalToolParameter(
                name: "searchText",
                description: "Text to search for when using searchReminders or openReminder action",
                dataType: .string,
                required: false,
                example: AnyCodable("Buy milk")
            ),
            PetalToolParameter(
                name: "name",
                description: "Name for the new reminder when using createReminder action",
                dataType: .string,
                required: true,
                example: AnyCodable("Call John")
            ),
            PetalToolParameter(
                name: "notes",
                description: "Notes for the new reminder when using createReminder action",
                dataType: .string,
                required: false,
                example: AnyCodable("Discuss project timeline")
            ),
            PetalToolParameter(
                name: "dueDate",
                description: "Due date for the new reminder when using createReminder action (ISO format)",
                dataType: .string,
                required: false,
                example: AnyCodable("2025-04-15T14:00:00Z")
            )
        ]
    }

    // MARK: - Tool Input/Output

    public struct ReminderList: Codable, Sendable {
        public let name: String
        public let id: String
    }

    public struct Reminder: Codable, Sendable {
        public let name: String
        public let id: String
        public let body: String
        public let completed: Bool
        public let dueDate: String?
        public let listName: String
        public let completionDate: String?
        public let creationDate: String?
        public let modificationDate: String?
        public let remindMeDate: String?
        public let priority: Int?
    }

    public struct OpenReminderResult: Codable, Sendable {
        public let success: Bool
        public let message: String
        public let reminder: Reminder?
    }

    public struct Input: Codable, Sendable {
        public let action: String
        public let listName: String?
        public let searchText: String?
        public let name: String?
        public let notes: String?
        public let dueDate: String?
    }

    public struct Output: Codable, Sendable {
        public let result: String
    }

    // MARK: - Tool Execution

    public func execute(_ input: Input) async throws -> Output {
        logger.debug("Executing Reminders Tool with action: \(input.action)")
        do {
            switch input.action {
            case "getAllLists":
                logger.debug("Calling getAllLists()")
                let lists = try await getAllLists()
                let formattedLists = formatLists(lists)
                logger.debug("getAllLists successful, found \(lists.count) lists.")
                return Output(result: formattedLists)

            case "getAllReminders":
                let listName = input.listName
                logger.debug("Calling getAllReminders(listName: \(listName ?? "nil"))")
                let reminders = try await getAllReminders(listName: listName)
                let formattedReminders = formatReminders(reminders)
                logger.debug("getAllReminders successful, found \(reminders.count) reminders.")
                return Output(result: formattedReminders)

            case "searchReminders":
                guard let searchText = input.searchText, !searchText.isEmpty else {
                    logger.warning("searchText missing for searchReminders action.")
                    return Output(result: "Error: searchText is required for searchReminders action")
                }
                logger.debug("Calling searchReminders(searchText: '\(searchText)'")
                let reminders = try await searchReminders(searchText: searchText)
                if reminders.isEmpty {
                    logger.debug("searchReminders: No reminders found matching '\(searchText)'")
                    return Output(result: "No reminders found matching '\(searchText)'")
                }
                logger.debug("searchReminders successful, found \(reminders.count) reminders.")
                let formattedReminders = formatReminders(reminders)
                return Output(result: formattedReminders)

            case "createReminder":
                guard let name = input.name, !name.isEmpty else {
                    logger.warning("name missing for createReminder action.")
                    return Output(result: "Error: name is required for createReminder action")
                }
                let listName = input.listName ?? "Reminders"
                let notes = input.notes
                let dueDate = input.dueDate
                
                logger.debug("Calling createReminder(name: '\(name)', listName: '\(listName)', notes: \(notes ?? "nil"), dueDate: \(dueDate ?? "nil")")
                let reminder = try await createReminder(name: name, listName: listName, notes: notes, dueDate: dueDate)
                
                let message = "Reminder '\(name)' successfully created in list '\(listName)'"
                logger.debug("createReminder successful: \(message)")
                return Output(result: message)

            case "openReminder":
                guard let searchText = input.searchText, !searchText.isEmpty else {
                    logger.warning("searchText missing for openReminder action.")
                    return Output(result: "Error: searchText is required for openReminder action")
                }
                logger.debug("Calling openReminder(searchText: '\(searchText)'")
                let result = try await openReminder(searchText: searchText)
                logger.debug("openReminder result: \(result.message)")
                return Output(result: result.message)

            default:
                logger.warning("Invalid action requested: \(input.action)")
                return Output(result: "Error: Invalid action '\(input.action)'. Use 'getAllLists', 'getAllReminders', 'searchReminders', 'createReminder', or 'openReminder'")
            }
        } catch let error as NSError {
            logger.error("Error executing Reminders tool: \(error.domain) - Code \(error.code) - \(error.localizedDescription)")
            logger.error("Underlying Error Info: \(error.userInfo)")

            // Handle AppleScript errors specifically
            if error.domain == "AppleScriptError" {
                if error.localizedDescription.contains("Application isn't running") || error.code == -600 {
                    logger.error("Detected specific error: Reminders app not running or inaccessible (-600).")
                    return Output(result: "Error: The Reminders app is not running or could not be accessed. Please ensure it is open and try again.")
                }
                if error.localizedDescription.contains("not authorized") || error.code == -1743 {
                    logger.error("Detected specific error: Automation permission denied (-1743).")
                    return Output(result: "Error: This app doesn't have permission to control Reminders. Please check System Settings > Privacy & Security > Automation and grant permission.")
                }
                let shortError = error.localizedDescription.components(separatedBy: "NSAppleScriptError").first ?? error.localizedDescription
                logger.error("Returning generic AppleScript error message: \(shortError)")
                return Output(result: "Error accessing Reminders: \(shortError)")
            }

            // Generic error
            logger.error("Returning generic NSError message: \(error.localizedDescription)")
            return Output(result: "Error: \(error.localizedDescription)")
        } catch {
            logger.error("Caught non-NSError: \(error.localizedDescription)")
            return Output(result: "An unexpected error occurred: \(error.localizedDescription)")
        }
    }

    // MARK: - AppleScript Functions

    private func getAllLists() async throws -> [ReminderList] {
        let script = """
        tell application "System Events"
            if not (exists process "Reminders") then
                tell application "Reminders" to activate
                delay 2
            end if
        end tell

        tell application "Reminders"
            set allLists to every list
            set listInfo to {}

            repeat with currentList in allLists
                set listData to {name:name of currentList, id:id of currentList}
                set end of listInfo to listData
            end repeat

            return listInfo
        end tell
        """

        let result = try await runAppleScript(script)
        return parseListsResult(result)
    }

    private func getAllReminders(listName: String? = nil) async throws -> [Reminder] {
        let listCondition = listName != nil ? """
            set targetLists to lists whose name is "\(escapeAppleScriptString(listName!))"
            if length of targetLists is 0 then
                return {}
            end if
            set targetList to item 1 of targetLists
            set allReminders to every reminder of targetList
        """ : """
            set allLists to every list
            set allReminders to {}
            repeat with currentList in allLists
                set currentReminders to every reminder of currentList
                set allReminders to allReminders & currentReminders
            end repeat
        """

        let script = """
        tell application "System Events"
            if not (exists process "Reminders") then
                tell application "Reminders" to activate
                delay 2
            end if
        end tell

        tell application "Reminders"
            \(listCondition)
            set reminderInfo to {}

            repeat with currentReminder in allReminders
                set reminderListName to name of container of currentReminder
                set reminderData to {name:name of currentReminder, id:id of currentReminder, body:(body of currentReminder) as string, completed:completed of currentReminder, listName:reminderListName}
                
                -- Add due date if it exists
                try
                    set dueDateValue to due date of currentReminder
                    if dueDateValue is not missing value then
                        set reminderData to reminderData & {dueDate:dueDateValue}
                    else
                        set reminderData to reminderData & {dueDate:missing value}
                    end if
                on error
                    set reminderData to reminderData & {dueDate:missing value}
                end try
                
                set end of reminderInfo to reminderData
            end repeat

            return reminderInfo
        end tell
        """

        let result = try await runAppleScript(script)
        return parseRemindersResult(result)
    }

    private func searchReminders(searchText: String) async throws -> [Reminder] {
        let script = """
        tell application "System Events"
            if not (exists process "Reminders") then
                tell application "Reminders" to activate
                delay 2
            end if
        end tell

        tell application "Reminders"
            set matchingReminders to {}
            set allLists to every list
            
            repeat with currentList in allLists
                set listReminders to (every reminder of currentList whose name contains "\(escapeAppleScriptString(searchText))" or body contains "\(escapeAppleScriptString(searchText))")
                set matchingReminders to matchingReminders & listReminders
            end repeat
            
            if length of matchingReminders is 0 then
                return {}
            end if
            
            set reminderInfo to {}
            repeat with currentReminder in matchingReminders
                set reminderListName to name of container of currentReminder
                set reminderData to {name:name of currentReminder, id:id of currentReminder, body:(body of currentReminder) as string, completed:completed of currentReminder, listName:reminderListName}
                
                -- Add due date if it exists
                try
                    set dueDateValue to due date of currentReminder
                    if dueDateValue is not missing value then
                        set reminderData to reminderData & {dueDate:dueDateValue}
                    else
                        set reminderData to reminderData & {dueDate:missing value}
                    end if
                on error
                    set reminderData to reminderData & {dueDate:missing value}
                end try
                
                set end of reminderInfo to reminderData
            end repeat
            
            return reminderInfo
        end tell
        """

        let result = try await runAppleScript(script)
        return parseRemindersResult(result)
    }

    private func createReminder(
        name: String,
        listName: String = "Reminders",
        notes: String? = nil,
        dueDate: String? = nil
    ) async throws -> Reminder {
        var propertySettings = "name:\"\(escapeAppleScriptString(name))\""
        
        if let notes = notes, !notes.isEmpty {
            propertySettings += ", body:\"\(escapeAppleScriptString(notes))\""
        }
        
        let dueDateBlock = if let dueDate = dueDate, !dueDate.isEmpty {
            """
            set dueDateObj to current date
            set dueDateObj's year to \(extractYear(from: dueDate))
            set dueDateObj's month to \(extractMonth(from: dueDate))
            set dueDateObj's day to \(extractDay(from: dueDate))
            set dueDateObj's hours to \(extractHour(from: dueDate))
            set dueDateObj's minutes to \(extractMinute(from: dueDate))
            set dueDateObj's seconds to \(extractSecond(from: dueDate))
            set newReminderProperties to {name:"\(escapeAppleScriptString(name))"
            """
            + (notes != nil ? ", body:\"\(escapeAppleScriptString(notes!))\"" : "")
            + ", due date:dueDateObj}"
        } else {
            "set newReminderProperties to {" + propertySettings + "}"
        }
        
        let script = """
        tell application "System Events"
            if not (exists process "Reminders") then
                tell application "Reminders" to activate
                delay 2
            end if
        end tell
        
        tell application "Reminders"
            -- Find or create the list
            set targetList to null
            set existingLists to (every list whose name is "\(escapeAppleScriptString(listName))")
            
            if length of existingLists > 0 then
                set targetList to item 1 of existingLists
            else
                -- Create a new list if it doesn't exist
                set targetList to make new list with properties {name:"\(escapeAppleScriptString(listName))"}
            end if
            
            -- Set up reminder properties
            \(dueDateBlock)
            
            -- Create the reminder
            set newReminder to make new reminder at targetList with properties newReminderProperties
            
            -- Get reminder details to return
            set reminderData to {name:name of newReminder, id:id of newReminder, body:(body of newReminder) as string, completed:completed of newReminder, listName:"\(escapeAppleScriptString(listName))"}
            
            -- Add due date if it exists
            try
                set dueDateValue to due date of newReminder
                if dueDateValue is not missing value then
                    set reminderData to reminderData & {dueDate:dueDateValue}
                else
                    set reminderData to reminderData & {dueDate:missing value}
                end if
            on error
                set reminderData to reminderData & {dueDate:missing value}
            end try
            
            return reminderData
        end tell
        """
        
        let result = try await runAppleScript(script)
        let reminders = parseRemindersResult(result)
        return reminders.first ?? Reminder(
            name: name,
            id: UUID().uuidString,
            body: notes ?? "",
            completed: false,
            dueDate: dueDate,
            listName: listName,
            completionDate: nil,
            creationDate: nil,
            modificationDate: nil,
            remindMeDate: nil,
            priority: nil
        )
    }

    private func openReminder(searchText: String) async throws -> OpenReminderResult {
        // First search for the reminder
        let matchingReminders = try await searchReminders(searchText: searchText)
        
        if matchingReminders.isEmpty {
            return OpenReminderResult(
                success: false,
                message: "No reminders found matching '\(searchText)'",
                reminder: nil
            )
        }
        
        // Get the first matching reminder
        let reminder = matchingReminders[0]
        
        // Script to open the Reminders app
        let script = """
        tell application "Reminders"
            activate
        end tell
        """
        
        _ = try await runAppleScript(script)
        
        return OpenReminderResult(
            success: true,
            message: "Reminders app opened. Found reminder: '\(reminder.name)'",
            reminder: reminder
        )
    }

    // MARK: - Helper Functions

    private func formatLists(_ lists: [ReminderList]) -> String {
        if lists.isEmpty {
            return "No reminder lists found."
        }

        var result = "Found \(lists.count) reminder list(s):\n\n"

        for (index, list) in lists.enumerated() {
            result += "[\(index + 1)] \(list.name)\n"
        }

        return result
    }

    private func formatReminders(_ reminders: [Reminder]) -> String {
        if reminders.isEmpty {
            return "No reminders found."
        }

        var result = "Found \(reminders.count) reminder(s):\n\n"

        for (index, reminder) in reminders.enumerated() {
            result += "[\(index + 1)] \(reminder.name)\n"
            result += "  List: \(reminder.listName)\n"
            
            if !reminder.body.isEmpty {
                result += "  Notes: \(reminder.body)\n"
            }
            
            if let dueDate = reminder.dueDate {
                result += "  Due: \(formatDate(dueDate))\n"
            }
            
            result += "  Completed: \(reminder.completed ? "Yes" : "No")\n\n"
        }

        return result
    }

    private func formatDate(_ dateString: String) -> String {
        if dateString == "missing value" {
            return "Not set"
        }
        
        // Use a date formatter if it's a valid date string
        if let date = ISO8601DateFormatter().date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        return dateString
    }

    private func escapeAppleScriptString(_ str: String) -> String {
        str.replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    private func extractYear(from isoDate: String) -> Int {
        let dateFormatter = ISO8601DateFormatter()
        if let date = dateFormatter.date(from: isoDate) {
            let calendar = Calendar.current
            return calendar.component(.year, from: date)
        }
        return Calendar.current.component(.year, from: Date())
    }
    
    private func extractMonth(from isoDate: String) -> Int {
        let dateFormatter = ISO8601DateFormatter()
        if let date = dateFormatter.date(from: isoDate) {
            let calendar = Calendar.current
            return calendar.component(.month, from: date)
        }
        return Calendar.current.component(.month, from: Date())
    }
    
    private func extractDay(from isoDate: String) -> Int {
        let dateFormatter = ISO8601DateFormatter()
        if let date = dateFormatter.date(from: isoDate) {
            let calendar = Calendar.current
            return calendar.component(.day, from: date)
        }
        return Calendar.current.component(.day, from: Date())
    }
    
    private func extractHour(from isoDate: String) -> Int {
        let dateFormatter = ISO8601DateFormatter()
        if let date = dateFormatter.date(from: isoDate) {
            let calendar = Calendar.current
            return calendar.component(.hour, from: date)
        }
        return 0
    }
    
    private func extractMinute(from isoDate: String) -> Int {
        let dateFormatter = ISO8601DateFormatter()
        if let date = dateFormatter.date(from: isoDate) {
            let calendar = Calendar.current
            return calendar.component(.minute, from: date)
        }
        return 0
    }
    
    private func extractSecond(from isoDate: String) -> Int {
        let dateFormatter = ISO8601DateFormatter()
        if let date = dateFormatter.date(from: isoDate) {
            let calendar = Calendar.current
            return calendar.component(.second, from: date)
        }
        return 0
    }

    private func runAppleScript(_ script: String) async throws -> String {
        logger.debug("Attempting to run AppleScript:\n--- SCRIPT START ---\n\(script)\n--- SCRIPT END ---\n")

        // Run the script
        return try await withCheckedThrowingContinuation { continuation in
            var errorDict: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                // Execute on the main thread for UI-related scripting
                DispatchQueue.main.async {
                    let output = scriptObject.executeAndReturnError(&errorDict)

                    if let error = errorDict {
                        self.logger.error("AppleScript execution failed. Error dictionary: \(error)")
                        continuation.resume(throwing: NSError(
                            domain: "AppleScriptError",
                            code: (error[NSAppleScript.errorNumber] as? Int) ?? 1,
                            userInfo: error as? [String: Any] ?? [NSLocalizedDescriptionKey: "AppleScript execution failed with unknown details."]
                        ))
                    } else {
                        let resultString = output.stringValue ?? ""
                        self.logger.debug("AppleScript executed successfully. Result: \(resultString.prefix(100))...")
                        continuation.resume(returning: resultString)
                    }
                }
            } else {
                self.logger.error("Failed to create NSAppleScript object.")
                continuation.resume(throwing: NSError(
                    domain: "AppleScriptError",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to initialize AppleScript object."]
                ))
            }
        }
    }

    private func parseListsResult(_ result: String) -> [ReminderList] {
        let lines = result.split(separator: "\n")
        var lists: [ReminderList] = []
        var currentList: (name: String, id: String)?

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.starts(with: "name:") {
                // If we were building a list, add it to our lists
                if let list = currentList {
                    lists.append(ReminderList(name: list.name, id: list.id))
                }

                // Start a new list
                let nameValue = String(trimmedLine.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentList = (name: nameValue, id: "")
            } else if trimmedLine.starts(with: "id:"), let list = currentList {
                let idValue = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentList = (name: list.name, id: idValue)

                // Add this list to our lists
                lists.append(ReminderList(name: list.name, id: idValue))
                currentList = nil
            }
        }

        // Add the last list if we have one
        if let list = currentList, !list.id.isEmpty {
            lists.append(ReminderList(name: list.name, id: list.id))
        }

        return lists
    }

    private func parseRemindersResult(_ result: String) -> [Reminder] {
        let lines = result.split(separator: "\n")
        var reminders: [Reminder] = []
        var currentReminder: [String: String] = [:]

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for a new reminder starting
            if trimmedLine.starts(with: "name:") {
                // If we were building a reminder, add it to our list
                if !currentReminder.isEmpty, let name = currentReminder["name"], let id = currentReminder["id"] {
                    let reminder = createReminderFromDict(currentReminder)
                    reminders.append(reminder)
                }

                // Start a new reminder
                currentReminder = [:]
                let nameValue = String(trimmedLine.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentReminder["name"] = nameValue
            }
            // Parse other properties
            else if let colonIndex = trimmedLine.firstIndex(of: ":") {
                let key = String(trimmedLine[..<colonIndex])
                let value = String(trimmedLine[trimmedLine.index(after: colonIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                currentReminder[key] = value
            }
        }

        // Add the last reminder if we have one
        if !currentReminder.isEmpty, let name = currentReminder["name"], let id = currentReminder["id"] {
            let reminder = createReminderFromDict(currentReminder)
            reminders.append(reminder)
        }

        return reminders
    }
    
    private func createReminderFromDict(_ dict: [String: String]) -> Reminder {
        return Reminder(
            name: dict["name"] ?? "",
            id: dict["id"] ?? UUID().uuidString,
            body: dict["body"] ?? "",
            completed: (dict["completed"] ?? "false") == "true",
            dueDate: dict["dueDate"],
            listName: dict["listName"] ?? "Unknown",
            completionDate: dict["completionDate"],
            creationDate: dict["creationDate"],
            modificationDate: dict["modificationDate"],
            remindMeDate: dict["remindMeDate"],
            priority: Int(dict["priority"] ?? "0")
        )
    }

    // MARK: - Ollama Tool Definition

    public func asOllamaTool() -> OllamaTool {
        OllamaTool(
            type: "function",
            function: OllamaFunction(
                name: id,
                description: description,
                parameters: OllamaFunctionParameters(
                    type: "object",
                    properties: [
                        "action": OllamaFunctionProperty(
                            type: "string",
                            description: "The action to perform: 'getAllLists', 'getAllReminders', 'searchReminders', 'createReminder', or 'openReminder'"
                        ),
                        "listName": OllamaFunctionProperty(
                            type: "string",
                            description: "Name of the reminder list to work with"
                        ),
                        "searchText": OllamaFunctionProperty(
                            type: "string",
                            description: "Text to search for when using searchReminders or openReminder action"
                        ),
                        "name": OllamaFunctionProperty(
                            type: "string",
                            description: "Name for the new reminder when using createReminder action"
                        ),
                        "notes": OllamaFunctionProperty(
                            type: "string",
                            description: "Notes for the new reminder when using createReminder action"
                        ),
                        "dueDate": OllamaFunctionProperty(
                            type: "string",
                            description: "Due date for the new reminder when using createReminder action (ISO format)"
                        )
                    ],
                    required: ["action"]
                )
            )
        )
    }

    // MARK: - MLX Tool Definition

    public func asMLXToolDefinition() -> MLXToolDefinition {
        MLXToolDefinition(
            type: "function",
            function: MLXFunctionDefinition(
                name: "petalRemindersTool",
                description: "Allows interaction with Apple Reminders app (find, create, list, and open reminders).",
                parameters: MLXParametersDefinition(
                    type: "object",
                    properties: [
                        "action": MLXParameterProperty(
                            type: "string",
                            description: "The action to perform: 'getAllLists', 'getAllReminders', 'searchReminders', 'createReminder', or 'openReminder'"
                        ),
                        "listName": MLXParameterProperty(
                            type: "string",
                            description: "Name of the reminder list to work with"
                        ),
                        "searchText": MLXParameterProperty(
                            type: "string",
                            description: "Text to search for when using searchReminders or openReminder action"
                        ),
                        "name": MLXParameterProperty(
                            type: "string",
                            description: "Name for the new reminder when using createReminder action"
                        ),
                        "notes": MLXParameterProperty(
                            type: "string",
                            description: "Notes for the new reminder when using createReminder action"
                        ),
                        "dueDate": MLXParameterProperty(
                            type: "string",
                            description: "Due date for the new reminder when using createReminder action (ISO format)"
                        )
                    ],
                    required: ["action"]
                )
            )
        )
    }
}
#endif
/*
 Sample usage:
 Show all my reminder lists
 Show all my reminders
 Show all reminders in my Work list
 Find reminders about groceries
 Create a reminder to call John tomorrow
*/
