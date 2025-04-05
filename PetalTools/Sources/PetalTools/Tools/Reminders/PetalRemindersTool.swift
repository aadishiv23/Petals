//
//  PetalRemindersTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra
//

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
    public var description: String { "Allows interaction with Apple Reminders app (find, create, and manage reminders)." }
    public var triggerKeywords: [String] { ["reminders", "reminder", "task", "tasks", "to-do", "todo"] }
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
                name: "searchText",
                description: "Text to search for when using searchReminders or openReminder",
                dataType: .string,
                required: false,
                example: AnyCodable("Doctor appointment")
            ),
            PetalToolParameter(
                name: "listId",
                description: "ID of the list to get reminders from when using getRemindersFromListById",
                dataType: .string,
                required: false,
                example: AnyCodable("12345")
            ),
            PetalToolParameter(
                name: "listName",
                description: "Name of the list to get reminders from or create a reminder in",
                dataType: .string,
                required: false,
                example: AnyCodable("Personal")
            ),
            PetalToolParameter(
                name: "name",
                description: "Name for the new reminder when using createReminder",
                dataType: .string,
                required: false,
                example: AnyCodable("Buy milk")
            ),
            PetalToolParameter(
                name: "notes",
                description: "Notes for the new reminder when using createReminder",
                dataType: .string,
                required: false,
                example: AnyCodable("Get full-fat organic milk")
            ),
            PetalToolParameter(
                name: "dueDate",
                description: "Due date for the new reminder when using createReminder (ISO string)",
                dataType: .string,
                required: false,
                example: AnyCodable("2023-12-10T10:00:00Z")
            )
        ]
    }
    
    // MARK: - Tool Input/Output
    
    public struct ReminderInfo: Codable, Sendable {
        public let name: String
        public let id: String
        public let body: String
        public let completed: Bool
        public let dueDate: String?
        public let listName: String
    }
    
    public struct ReminderListInfo: Codable, Sendable {
        public let name: String
        public let id: String
    }
    
    public struct OpenReminderResult: Codable, Sendable {
        public let success: Bool
        public let message: String
        public let reminder: ReminderInfo?
    }
    
    public struct Input: Codable, Sendable {
        public let action: String
        public let searchText: String?
        public let listId: String?
        public let listName: String?
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
                logger.debug("Calling getAllReminders() with listName: \(input.listName ?? "all")")
                let reminders = try await getAllReminders(listName: input.listName)
                let formattedReminders = formatReminders(reminders)
                logger.debug("getAllReminders successful, found \(reminders.count) reminders.")
                return Output(result: formattedReminders)
                
            case "getRemindersFromListById":
                guard let listId = input.listId, !listId.isEmpty else {
                    logger.warning("listId missing for getRemindersFromListById action.")
                    return Output(result: "Error: listId is required for getRemindersFromListById action")
                }
                logger.debug("Calling getRemindersFromListById(listId: '\(listId)')")
                let reminders = try await getRemindersFromListById(listId: listId)
                let formattedReminders = formatReminders(reminders)
                logger.debug("getRemindersFromListById successful, found \(reminders.count) reminders.")
                return Output(result: formattedReminders)
                
            case "searchReminders":
                guard let searchText = input.searchText, !searchText.isEmpty else {
                    logger.warning("searchText missing for searchReminders action.")
                    return Output(result: "Error: searchText is required for searchReminders action")
                }
                logger.debug("Calling searchReminders(searchText: '\(searchText)')")
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
                logger.debug("Calling createReminder(name: '\(name)', listName: '\(listName)')")
                let reminder = try await createReminder(
                    name: name,
                    listName: listName,
                    notes: input.notes,
                    dueDate: input.dueDate
                )
                logger.debug("createReminder successful, created '\(reminder.name)' in list '\(reminder.listName)'")
                return Output(result: "Reminder '\(reminder.name)' successfully created in list '\(reminder.listName)'")
                
            case "openReminder":
                guard let searchText = input.searchText, !searchText.isEmpty else {
                    logger.warning("searchText missing for openReminder action.")
                    return Output(result: "Error: searchText is required for openReminder action")
                }
                logger.debug("Calling openReminder(searchText: '\(searchText)')")
                let result = try await openReminder(searchText: searchText)
                logger.debug("openReminder \(result.success ? "successful" : "failed"): \(result.message)")
                return Output(result: result.message)
                
            default:
                logger.warning("Invalid action requested: \(input.action)")
                return Output(result: "Error: Invalid action '\(input.action)'. Use 'getAllLists', 'getAllReminders', 'getRemindersFromListById', 'searchReminders', 'createReminder', or 'openReminder'")
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
    
    private func getAllLists() async throws -> [ReminderListInfo] {
        let script = """
        tell application "System Events"
            if not (exists process "Reminders") then
                tell application "Reminders" to activate
                delay 2
            end if
        end tell
        
        tell application "Reminders"
            set allLists to every list
            set listInfos to {}
            
            repeat with currentList in allLists
                set listInfo to {name:name of currentList, id:id of currentList}
                set end of listInfos to listInfo
            end repeat
            
            return listInfos
        end tell
        """
        
        let result = try await runAppleScript(script)
        return parseListsResult(result)
    }
    
    private func getRemindersFromListById(listId: String) async throws -> [ReminderInfo] {
        let script = """
        tell application "System Events"
            if not (exists process "Reminders") then
                tell application "Reminders" to activate
                delay 2
            end if
        end tell
        
        tell application "Reminders"
            set targetList to list id "\(escapeAppleScriptString(listId))"
            set listName to name of targetList
            set allReminders to every reminder of targetList
            set reminderInfos to {}
            
            repeat with currentReminder in allReminders
                set reminderDueDate to missing value
                if due date of currentReminder is not missing value then
                    set reminderDueDate to ((due date of currentReminder) as string)
                end if
                
                set reminderInfo to {name:name of currentReminder, id:id of currentReminder, body:body of currentReminder, completed:completed of currentReminder, dueDate:reminderDueDate, listName:listName}
                set end of reminderInfos to reminderInfo
            end repeat
            
            return reminderInfos
        end tell
        """
        
        let result = try await runAppleScript(script)
        return parseRemindersResult(result)
    }
    
    private func getAllReminders(listName: String? = nil) async throws -> [ReminderInfo] {
        let script: String
        
        if let listName = listName {
            script = """
            tell application "System Events"
                if not (exists process "Reminders") then
                    tell application "Reminders" to activate
                    delay 2
                end if
            end tell
            
            tell application "Reminders"
                set targetLists to lists whose name is "\(escapeAppleScriptString(listName))"
                if length of targetLists is 0 then
                    return {}
                end if
                
                set targetList to item 1 of targetLists
                set allReminders to every reminder of targetList
                set reminderInfos to {}
                
                repeat with currentReminder in allReminders
                    set reminderDueDate to missing value
                    if due date of currentReminder is not missing value then
                        set reminderDueDate to ((due date of currentReminder) as string)
                    end if
                    
                    set reminderInfo to {name:name of currentReminder, id:id of currentReminder, body:body of currentReminder, completed:completed of currentReminder, dueDate:reminderDueDate, listName:name of targetList}
                    set end of reminderInfos to reminderInfo
                end repeat
                
                return reminderInfos
            end tell
            """
        } else {
            script = """
            tell application "System Events"
                if not (exists process "Reminders") then
                    tell application "Reminders" to activate
                    delay 2
                end if
            end tell
            
            tell application "Reminders"
                set allLists to every list
                set reminderInfos to {}
                
                repeat with currentList in allLists
                    set listName to name of currentList
                    set allReminders to every reminder of currentList
                    
                    repeat with currentReminder in allReminders
                        set reminderDueDate to missing value
                        if due date of currentReminder is not missing value then
                            set reminderDueDate to ((due date of currentReminder) as string)
                        end if
                        
                        set reminderInfo to {name:name of currentReminder, id:id of currentReminder, body:body of currentReminder, completed:completed of currentReminder, dueDate:reminderDueDate, listName:listName}
                        set end of reminderInfos to reminderInfo
                    end repeat
                end repeat
                
                return reminderInfos
            end tell
            """
        }
        
        let result = try await runAppleScript(script)
        return parseRemindersResult(result)
    }
    
    private func searchReminders(searchText: String) async throws -> [ReminderInfo] {
        let script = """
        tell application "System Events"
            if not (exists process "Reminders") then
                tell application "Reminders" to activate
                delay 2
            end if
        end tell
        
        tell application "Reminders"
            set allLists to every list
            set matchingReminders to {}
            
            repeat with currentList in allLists
                set listName to name of currentList
                set searchString to "\(escapeAppleScriptString(searchText))"
                
                set foundReminders to (every reminder of currentList whose name contains searchString or body contains searchString)
                
                repeat with currentReminder in foundReminders
                    set reminderDueDate to missing value
                    if due date of currentReminder is not missing value then
                        set reminderDueDate to ((due date of currentReminder) as string)
                    end if
                    
                    set reminderInfo to {name:name of currentReminder, id:id of currentReminder, body:body of currentReminder, completed:completed of currentReminder, dueDate:reminderDueDate, listName:listName}
                    set end of matchingReminders to reminderInfo
                end repeat
            end repeat
            
            return matchingReminders
        end tell
        """
        
        let result = try await runAppleScript(script)
        return parseRemindersResult(result)
    }
    
    private func createReminder(name: String, listName: String = "Reminders", notes: String? = nil, dueDate: String? = nil) async throws -> ReminderInfo {
        // Prepare properties for the reminder
        var reminderProps = ""
        
        if let notes = notes, !notes.isEmpty {
            reminderProps += " with properties {body:\"\(escapeAppleScriptString(notes))\"}"
        }
        
        var dueDateScript = ""
        if let dueDate = dueDate, !dueDate.isEmpty {
            dueDateScript = """
            set dueDateValue to (current date)
            set dueDateValue's year to \(getYear(from: dueDate))
            set dueDateValue's month to \(getMonth(from: dueDate))
            set dueDateValue's day to \(getDay(from: dueDate))
            set dueDateValue's hours to \(getHour(from: dueDate))
            set dueDateValue's minutes to \(getMinute(from: dueDate))
            set dueDateValue's seconds to \(getSecond(from: dueDate))
            set dueDate of newReminder to dueDateValue
            """
        }
        
        let script = """
        tell application "System Events"
            if not (exists process "Reminders") then
                tell application "Reminders" to activate
                delay 2
            end if
        end tell
        
        tell application "Reminders"
            set targetListName to "\(escapeAppleScriptString(listName))"
            set targetLists to lists whose name is targetListName
            
            set targetList to {}
            
            if length of targetLists is 0 then
                -- Create list if it doesn't exist
                set targetList to make new list with properties {name:targetListName}
            else
                set targetList to first item of targetLists
            end if
            
            set newReminder to make new reminder with properties {name:"\(escapeAppleScriptString(name))"} at targetList
            
            \(notes != nil && !notes!.isEmpty ? "set body of newReminder to \"\(escapeAppleScriptString(notes!))\"" : "")
            \(dueDateScript)
            
            set reminderDueDate to missing value
            if due date of newReminder is not missing value then
                set reminderDueDate to ((due date of newReminder) as string)
            end if
            
            set reminderInfo to {name:name of newReminder, id:id of newReminder, body:body of newReminder, completed:completed of newReminder, dueDate:reminderDueDate, listName:name of targetList}
            return reminderInfo
        end tell
        """
        
        let result = try await runAppleScript(script)
        return parseSingleReminderResult(result)
    }
    
    private func openReminder(searchText: String) async throws -> OpenReminderResult {
        // First search for matching reminders
        let matchingReminders = try await searchReminders(searchText: searchText)
        
        if matchingReminders.isEmpty {
            return OpenReminderResult(
                success: false,
                message: "No matching reminders found",
                reminder: nil
            )
        }
        
        // Use the first matching reminder
        let reminder = matchingReminders[0]
        
        // Activate Reminders app (this is the best we can do, as there's no direct way to show a specific reminder)
        let script = """
        tell application "Reminders"
            activate
        end tell
        """
        
        _ = try await runAppleScript(script)
        
        return OpenReminderResult(
            success: true,
            message: "Reminders app opened. Found reminder '\(reminder.name)' in list '\(reminder.listName)'",
            reminder: reminder
        )
    }
    
    // MARK: - Helper Functions
    
    private func runAppleScript(_ script: String) async throws -> String {
        // Execute the script
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                // Create script object and error dictionary on the main thread
                let scriptObject = NSAppleScript(source: script)
                var error: NSDictionary?
                
                guard let scriptResult = scriptObject?.executeAndReturnError(&error) else {
                    if let error = error {
                        continuation.resume(throwing: NSError(
                            domain: "AppleScriptError",
                            code: (error["NSAppleScriptErrorNumber"] as? Int) ?? -1,
                            userInfo: error as? [String: Any]
                        ))
                    } else {
                        continuation.resume(throwing: NSError(
                            domain: "AppleScriptError",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Unknown AppleScript error"]
                        ))
                    }
                    return
                }
                
                continuation.resume(returning: scriptResult.stringValue ?? "")
            }
        }
    }
    
    private func formatLists(_ lists: [ReminderListInfo]) -> String {
        if lists.isEmpty {
            return "No reminder lists found."
        }
        
        var result = "Found \(lists.count) reminder list(s):\n\n"
        
        for (index, list) in lists.enumerated() {
            result += "[\(index + 1)] \(list.name) (ID: \(list.id))\n"
        }
        
        return result
    }
    
    private func formatReminders(_ reminders: [ReminderInfo]) -> String {
        if reminders.isEmpty {
            return "No reminders found."
        }
        
        var result = "Found \(reminders.count) reminder(s):\n\n"
        
        let remindersByList = Dictionary(grouping: reminders, by: { $0.listName })
        
        for (listName, listReminders) in remindersByList.sorted(by: { $0.key < $1.key }) {
            result += "List: \(listName)\n"
            
            for (index, reminder) in listReminders.enumerated() {
                let status = reminder.completed ? "[✓]" : "[ ]"
                let dueString = reminder.dueDate != nil ? " (Due: \(formatDueDate(reminder.dueDate!)))" : ""
                
                result += "\(status) \(reminder.name)\(dueString)\n"
                
                if !reminder.body.isEmpty {
                    let bodyPreview = reminder.body.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !bodyPreview.isEmpty {
                        result += "   \(bodyPreview)\n"
                    }
                }
                
                if index < listReminders.count - 1 {
                    result += "\n"
                }
            }
            
            result += "\n"
        }
        
        return result
    }
    
    private func formatDueDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        if let date = parseDate(dateString) {
            return dateFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        
        // Try multiple formats
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",      // ISO 8601
            "yyyy-MM-dd HH:mm:ss Z",       // Common format
            "yyyy-MM-dd",                  // Date only
            "EEE MMM dd HH:mm:ss yyyy"     // AppleScript date format
        ]
        
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func escapeAppleScriptString(_ str: String) -> String {
        str.replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    private func parseListsResult(_ result: String) -> [ReminderListInfo] {
        let lines = result.split(separator: "\n")
        var lists: [ReminderListInfo] = []
        
        var currentList: (name: String, id: String)?
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.starts(with: "name:") {
                // If we were building a list, add it to the lists array
                if let list = currentList {
                    lists.append(ReminderListInfo(name: list.name, id: list.id))
                }
                
                // Start a new list
                let nameValue = String(trimmedLine.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentList = (name: nameValue, id: "")
            } else if trimmedLine.starts(with: "id:"), let list = currentList {
                let idValue = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentList = (name: list.name, id: idValue)
                
                // Add this list to our lists array
                lists.append(ReminderListInfo(name: list.name, id: idValue))
                currentList = nil
            }
        }
        
        // Add the last list if we have one
        if let list = currentList {
            lists.append(ReminderListInfo(name: list.name, id: list.id))
        }
        
        return lists
    }
    
    private func parseRemindersResult(_ result: String) -> [ReminderInfo] {
        let lines = result.split(separator: "\n")
        var reminders: [ReminderInfo] = []
        
        var currentReminder: (name: String, id: String, body: String, completed: Bool, dueDate: String?, listName: String)?
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.starts(with: "name:") {
                // If we were building a reminder, add it to the reminders array
                if let reminder = currentReminder {
                    reminders.append(ReminderInfo(
                        name: reminder.name,
                        id: reminder.id,
                        body: reminder.body,
                        completed: reminder.completed,
                        dueDate: reminder.dueDate,
                        listName: reminder.listName
                    ))
                }
                
                // Start a new reminder
                let nameValue = String(trimmedLine.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentReminder = (
                    name: nameValue,
                    id: "",
                    body: "",
                    completed: false,
                    dueDate: nil,
                    listName: ""
                )
            } else if trimmedLine.starts(with: "id:"), let reminder = currentReminder {
                let idValue = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentReminder?.id = idValue
            } else if trimmedLine.starts(with: "body:"), let reminder = currentReminder {
                let bodyValue = String(trimmedLine.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentReminder?.body = bodyValue
            } else if trimmedLine.starts(with: "completed:"), let reminder = currentReminder {
                let completedValue = String(trimmedLine.dropFirst(10)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentReminder?.completed = completedValue.lowercased() == "true"
            } else if trimmedLine.starts(with: "dueDate:"), let reminder = currentReminder {
                let dueDateValue = String(trimmedLine.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentReminder?.dueDate = dueDateValue != "missing value" ? dueDateValue : nil
            } else if trimmedLine.starts(with: "listName:"), let reminder = currentReminder {
                let listNameValue = String(trimmedLine.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentReminder?.listName = listNameValue
                
                // Add this reminder to our reminders array if it has all required fields
                if let completeReminder = currentReminder, !completeReminder.name.isEmpty && !completeReminder.id.isEmpty && !completeReminder.listName.isEmpty {
                    reminders.append(ReminderInfo(
                        name: completeReminder.name,
                        id: completeReminder.id,
                        body: completeReminder.body,
                        completed: completeReminder.completed,
                        dueDate: completeReminder.dueDate,
                        listName: completeReminder.listName
                    ))
                    currentReminder = nil
                }
            }
        }
        
        // Add the last reminder if we have one
        if let reminder = currentReminder, !reminder.name.isEmpty && !reminder.id.isEmpty && !reminder.listName.isEmpty {
            reminders.append(ReminderInfo(
                name: reminder.name,
                id: reminder.id,
                body: reminder.body,
                completed: reminder.completed,
                dueDate: reminder.dueDate,
                listName: reminder.listName
            ))
        }
        
        return reminders
    }
    
    private func parseSingleReminderResult(_ result: String) -> ReminderInfo {
        let reminderArray = parseRemindersResult(result)
        if let reminder = reminderArray.first {
            return reminder
        }
        
        // If parsing failed, create a minimal reminder with the info we have
        return ReminderInfo(
            name: extractValue(from: result, key: "name") ?? "Unknown",
            id: extractValue(from: result, key: "id") ?? "Unknown",
            body: extractValue(from: result, key: "body") ?? "",
            completed: false,
            dueDate: extractValue(from: result, key: "dueDate"),
            listName: extractValue(from: result, key: "listName") ?? "Unknown"
        )
    }
    
    private func extractValue(from result: String, key: String) -> String? {
        let pattern = "\(key):([^,\\}]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        if let match = regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) {
            if let range = Range(match.range(at: 1), in: result) {
                return String(result[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
    
    // Date helpers for AppleScript
    private func getYear(from isoDate: String) -> Int {
        guard let date = ISO8601DateFormatter().date(from: isoDate) else {
            return Calendar.current.component(.year, from: Date())
        }
        return Calendar.current.component(.year, from: date)
    }
    
    private func getMonth(from isoDate: String) -> Int {
        guard let date = ISO8601DateFormatter().date(from: isoDate) else {
            return Calendar.current.component(.month, from: Date())
        }
        return Calendar.current.component(.month, from: date)
    }
    
    private func getDay(from isoDate: String) -> Int {
        guard let date = ISO8601DateFormatter().date(from: isoDate) else {
            return Calendar.current.component(.day, from: Date())
        }
        return Calendar.current.component(.day, from: date)
    }
    
    private func getHour(from isoDate: String) -> Int {
        guard let date = ISO8601DateFormatter().date(from: isoDate) else {
            return Calendar.current.component(.hour, from: Date())
        }
        return Calendar.current.component(.hour, from: date)
    }
    
    private func getMinute(from isoDate: String) -> Int {
        guard let date = ISO8601DateFormatter().date(from: isoDate) else {
            return Calendar.current.component(.minute, from: Date())
        }
        return Calendar.current.component(.minute, from: date)
    }
    
    private func getSecond(from isoDate: String) -> Int {
        guard let date = ISO8601DateFormatter().date(from: isoDate) else {
            return Calendar.current.component(.second, from: Date())
        }
        return Calendar.current.component(.second, from: date)
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
                        "searchText": OllamaFunctionProperty(
                            type: "string",
                            description: "Text to search for when using searchReminders or openReminder"
                        ),
                        "listId": OllamaFunctionProperty(
                            type: "string",
                            description: "ID of the list to get reminders from when using getRemindersFromListById"
                        ),
                        "listName": OllamaFunctionProperty(
                            type: "string",
                            description: "Name of the list to get reminders from or create a reminder in"
                        ),
                        "name": OllamaFunctionProperty(
                            type: "string",
                            description: "Name for the new reminder when using createReminder"
                        ),
                        "notes": OllamaFunctionProperty(
                            type: "string",
                            description: "Notes for the new reminder when using createReminder"
                        ),
                        "dueDate": OllamaFunctionProperty(
                            type: "string",
                            description: "Due date for the new reminder when using createReminder (ISO string)"
                        )
                    ],
                    required: ["action"]
                )
            )
        )
    }
    
    // MARK: - MLX-Compatible
    
    public func asMLXToolDefinition() -> MLXToolDefinition {
        MLXToolDefinition(
            type: "function",
            function: MLXFunctionDefinition(
                name: "petalRemindersTool",
                description: "Allows interaction with Apple Reminders app (find, create, and manage reminders).",
                parameters: MLXParametersDefinition(
                    type: "object",
                    properties: [
                        "action": MLXParameterProperty(
                            type: "string",
                            description: "The action to perform: 'getAllLists', 'getAllReminders', 'searchReminders', 'createReminder', or 'openReminder'"
                        ),
                        "searchText": MLXParameterProperty(
                            type: "string",
                            description: "Text to search for when using searchReminders or openReminder"
                        ),
                        "listId": MLXParameterProperty(
                            type: "string",
                            description: "ID of the list to get reminders from when using getRemindersFromListById"
                        ),
                        "listName": MLXParameterProperty(
                            type: "string",
                            description: "Name of the list to get reminders from or create a reminder in"
                        ),
                        "name": MLXParameterProperty(
                            type: "string",
                            description: "Name for the new reminder when using createReminder"
                        ),
                        "notes": MLXParameterProperty(
                            type: "string",
                            description: "Notes for the new reminder when using createReminder"
                        ),
                        "dueDate": MLXParameterProperty(
                            type: "string",
                            description: "Due date for the new reminder when using createReminder (ISO string)"
                        )
                    ],
                    required: ["action"]
                )
            )
        )
    }
} 
