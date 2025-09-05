//
//  AppToolCallHandler.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 3/26/25.
//

import Foundation
import MLXLMCommon
import os
import PetalCore
import PetalTools

public enum ToolCallError: Error {
    case invalidJSON(Error? = nil)
    case invalidArguments(String? = nil)
    case unknownTool(String)
    case toolExecutionFailed(String, Error)
    case formatError(String)
}

/// Handles processing of LLM output for tool calls and dispatches to the correct tool.
@MainActor
public class AppToolCallHandler {
    public static let shared = AppToolCallHandler()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.Petal.MLX",
        category: "AppToolCallHandler"
    )
    private let decoder = JSONDecoder()

    private init() {}

    /// Processes the LLM output to detect and execute a tool call.
    public func processLLMOutput(
        _ result: GenerateResult
    ) async throws -> (processedOutput: String, toolCalled: Bool, toolName: String?) {
        logger.debug("Processing LLM output: \(result.output.prefix(100))...")
        let text = result.output

        // FIRST: Try Llama-style format (<|python_tag|> ... <|eom_id|>)
        do {
            logger.debug("Attempting to handle Llama format...")
            let (executionResult, toolName) = try await handleLlamaFormat(text)
            logger.info("Llama format tool call '\(toolName)' processed successfully.")
            return (processedOutput: executionResult, toolCalled: true, toolName: toolName)
        } catch let error as ToolCallError where error == .formatError("Llama tags not found") {
            logger.debug("Llama format not detected - continuing to other formats.")
        } catch {
            logger.error("Error processing Llama format: \(error)")

            // If the error occurs in JSON processing but we're sure it's a tool call format,
            // log more details and return a user-friendly error
            if text.contains("<|python_tag|>"), text.contains("<|eom_id|>") {
                logger.error("This appears to be a Llama tool call format but failed to process: \(error)")
                return (
                    processedOutput: "I tried to use a tool, but encountered an error: \(error.localizedDescription)",

                    toolCalled: false,

                    toolName: nil
                )
            }

            // Otherwise continue to next format
        }

        // SECOND: Try generic format (e.g. <tool_call>...</tool_call>)
        if text.contains("<tool_call>") {
            logger.debug("Attempting to handle generic tool_call format...")
            if let startRange = text.range(of: "<tool_call>"),
               let endRange = text.range(of: "</tool_call>"),
               endRange.lowerBound > startRange.upperBound
            {
                let jsonString = String(text[startRange.upperBound..<endRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                logger.debug("Extracted generic JSON: \(jsonString)")
                do {
                    let (executionResult, toolName) = try await handleGenericToolCall(jsonString)
                    logger.info("Generic tool call '\(toolName)' processed successfully.")
                    return (processedOutput: executionResult, toolCalled: true, toolName: toolName)
                } catch {
                    logger.error("Failed to handle generic tool call: \(error.localizedDescription)")
                    return (
                        processedOutput: "I tried to use a tool, but encountered an error: \(error.localizedDescription)",

                        toolCalled: false,

                        toolName: nil
                    )
                }
            } else {
                logger.warning("Found <tool_call> but not a complete tag pair; treating as regular text.")
            }
        }

        // THIRD: Try to detect JSON directly at the beginning of the text
        // THIRD: Try to detect JSON directly at the beginning of the text
        if text.trimmingCharacters(in: .whitespacesAndNewlines).starts(with: "{") {
            logger.debug("Text starts with '{', attempting raw JSON parse...")

            // First, check for any common completion markers
            var jsonEndIndex: String.Index?

            if let eomRange = text.range(of: "<|eom_id|>") {
                jsonEndIndex = eomRange.lowerBound
                logger.debug("Found <|eom_id|> marker to delimit JSON")
            } else if let startHeaderRange = text.range(of: "<|start_header_id|>") {
                jsonEndIndex = startHeaderRange.lowerBound
                logger.debug("Found <|start_header_id|> marker to delimit JSON")
            } else {
                // If no marker found, use balanced brace approach as fallback
                var braceBalance = 0
                for (index, char) in text.enumerated() {
                    if char == "{" {
                        braceBalance += 1
                    } else if char == "}" {
                        braceBalance -= 1
                        if braceBalance == 0 {
                            // Found the end of the top-level JSON object
                            jsonEndIndex = text.index(text.startIndex, offsetBy: index + 1) // Include the closing brace
                            break
                        }
                    }
                }
            }

            if let endIndex = jsonEndIndex, endIndex > text.startIndex {
                let potentialJson = String(text[text.startIndex..<endIndex])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                logger.debug("Potential raw JSON found: \(potentialJson)")

                // Look for key patterns that indicate a tool call
                if potentialJson.contains("\"name\":") ||
                    potentialJson.contains("\"function\":") ||
                    (potentialJson.contains("\"type\":") && potentialJson.contains("\"function\""))
                {
                    do {
                        // Try to sanitize the JSON if needed
                        var sanitizedJson = potentialJson
                        if !sanitizedJson.hasSuffix("}") {
                            // Add closing brace if missing
                            let openBraces = sanitizedJson.filter { $0 == "{" }.count
                            let closeBraces = sanitizedJson.filter { $0 == "}" }.count
                            if openBraces > closeBraces {
                                for _ in 0..<(openBraces - closeBraces) {
                                    sanitizedJson += "}"
                                }
                                logger.debug("Added missing closing braces to JSON")
                            }
                        }

                        logger.debug("Attempting to process sanitized JSON: \(sanitizedJson)")
                        let (executionResult, toolName) = try await handleGenericToolCall(sanitizedJson)
                        logger.info("Raw JSON tool call '\(toolName)' processed successfully.")
                        return (processedOutput: executionResult, toolCalled: true, toolName: toolName)
                    } catch {
                        logger.error("Failed to handle potential raw JSON: \(error)")
                        // Fall through to treat as regular text
                    }
                } else {
                    logger.debug("Potential raw JSON does not contain tool call indicators.")
                }
            } else {
                logger.debug("Could not find proper JSON ending.")
            }
        }
        // Original Regex check removed as the procedural check above is more robust for start-of-string JSON
//        catch {
//            logger.debug("No valid JSON object found in output.")
//            // Continue to treat as regular text
//        }

        // No tool call detected; return the original text.
        logger.debug("No tool call format detected - returning original text.")
        return (processedOutput: text, toolCalled: false, toolName: nil)
    }

    /// Handles Llama-style tool call format.
    private func handleLlamaFormat(_ text: String) async throws -> (executionResult: String, toolName: String) {
        logger.debug("Checking for Llama format tags...")
        guard let startRange = text.range(of: "<|python_tag|>"),
              let endRange = text.range(of: "<|eom_id|>"),
              endRange.lowerBound > startRange.upperBound
        else {
            throw ToolCallError.formatError("Llama tags not found")
        }

        let jsonString = String(text[startRange.upperBound..<endRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        logger.debug("Extracted JSON from Llama format: '\(jsonString)'")

        guard !jsonString.isEmpty else {
            logger.error("Empty JSON in Llama format")
            throw ToolCallError.invalidJSON()
        }

        // Validate and sanitize the JSON string
        var sanitizedJson = jsonString

        // Check if the JSON is potentially missing a closing brace
        let openBraces = sanitizedJson.filter { $0 == "{" }.count
        let closeBraces = sanitizedJson.filter { $0 == "}" }.count

        if openBraces > closeBraces {
            logger
                .debug("Detected missing closing braces, attempting to fix: \(openBraces) open vs \(closeBraces) close")
            for _ in 0..<(openBraces - closeBraces) {
                sanitizedJson += "}"
            }
        }

        // Parse the JSON to handle Llama format which may have nested structure
        guard let data = sanitizedJson.data(using: .utf8) else {
            logger.error("Failed to convert JSON string to data.")
            throw ToolCallError.invalidJSON()
        }

        do {
            // Try to parse the JSON to ensure it's valid
            guard let jsonObj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                logger.error("JSON is not a dictionary after sanitization")
                throw ToolCallError.invalidJSON()
            }

            // Extract tool name and parameters based on the JSON structure
            var toolName: String
            var parametersDict: [String: Any] = [:]

            // Case 1: Simple format { "type": "function", "function": "toolName", "parameters": {...} }
            if let functionName = jsonObj["function"] as? String {
                toolName = functionName
                if let params = jsonObj["parameters"] as? [String: Any] {
                    parametersDict = params
                }
            }
            // Case 2: Nested format { "type": "function", "function": { "name": "toolName", "parameters": {...} } }
            else if let functionObj = jsonObj["function"] as? [String: Any],
                    let functionName = functionObj["name"] as? String
            {
                toolName = functionName
                if let params = functionObj["parameters"] as? [String: Any] {
                    parametersDict = params
                }
            }
            // Case 3: Standard format { "name": "toolName", "arguments": {...} }
            else if let name = jsonObj["name"] as? String {
                toolName = name
                if let args = jsonObj["arguments"] as? [String: Any] {
                    parametersDict = args
                } else if let params = jsonObj["parameters"] as? [String: Any] {
                    parametersDict = params
                }
            } else {
                logger.error("Could not find tool name in JSON structure")
                throw ToolCallError.invalidJSON()
            }

            // Check for nested "properties" within parameters/arguments
            if parametersDict.count == 1, let nestedProperties = parametersDict["properties"] as? [String: Any] {
                logger.debug("Found nested 'properties' key inside arguments, flattening...")
                parametersDict = nestedProperties
            }

            // Normalize to the standard format expected by decodeAndExecuteToolCall
            let normalizedDict: [String: Any] = [
                "name": toolName,
                "arguments": parametersDict
            ]

            // Convert normalized dictionary back to JSON
            let normalizedData = try JSONSerialization.data(withJSONObject: normalizedDict)
            let normalizedJson = String(data: normalizedData, encoding: .utf8) ?? ""

            logger.debug("Normalized JSON: \(normalizedJson)")

            return try await decodeAndExecuteToolCall(normalizedJson)
        } catch {
            logger.error("JSON processing or decoding error: \(error.localizedDescription)")
            throw ToolCallError.invalidJSON(error)
        }
    }

    /// Handles generic tool call format.
    private func handleGenericToolCall(_ jsonString: String) async throws
        -> (executionResult: String, toolName: String)
    {
        logger.debug("Handling generic tool call with JSON: \(jsonString)")
        guard !jsonString.isEmpty else {
            logger.error("Empty JSON string for generic tool call.")
            throw ToolCallError.invalidJSON()
        }

        // Validate and sanitize JSON
        var sanitizedJson = jsonString

        // Check if JSON might be missing closing braces
        let openBraces = sanitizedJson.filter { $0 == "{" }.count
        let closeBraces = sanitizedJson.filter { $0 == "}" }.count

        if openBraces > closeBraces {
            logger
                .debug("Detected missing closing braces, attempting to fix: \(openBraces) open vs \(closeBraces) close")
            for _ in 0..<(openBraces - closeBraces) {
                sanitizedJson += "}"
            }
        }

        // Parse JSON to normalize format
        guard let data = sanitizedJson.data(using: .utf8) else {
            logger.error("Failed to convert JSON string to data.")
            throw ToolCallError.invalidJSON()
        }

        do {
            // Try to parse the JSON to ensure it's valid
            guard let jsonObj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                logger.error("JSON is not a dictionary after sanitization")
                throw ToolCallError.invalidJSON()
            }

            // Extract tool name and parameters based on the JSON structure
            var toolName: String
            var parametersDict: [String: Any] = [:]

            // Case 1: Simple format { "type": "function", "function": "toolName", "parameters": {...} }
            if let functionName = jsonObj["function"] as? String {
                toolName = functionName
                if let params = jsonObj["parameters"] as? [String: Any] {
                    parametersDict = params
                }
            }
            // Case 2: Nested format { "type": "function", "function": { "name": "toolName", "parameters": {...} } }
            else if let functionObj = jsonObj["function"] as? [String: Any],
                    let functionName = functionObj["name"] as? String
            {
                toolName = functionName
                if let params = functionObj["parameters"] as? [String: Any] {
                    parametersDict = params
                }
            }
            // Case 3: Standard format { "name": "toolName", "arguments": {...} }
            else if let name = jsonObj["name"] as? String {
                toolName = name
                if let args = jsonObj["arguments"] as? [String: Any] {
                    parametersDict = args
                } else if let params = jsonObj["parameters"] as? [String: Any] {
                    parametersDict = params
                }
            } else {
                logger.error("Could not find tool name in JSON structure")
                throw ToolCallError.invalidJSON()
            }

            // Check for nested "properties" within parameters/arguments
            if parametersDict.count == 1, let nestedProperties = parametersDict["properties"] as? [String: Any] {
                logger.debug("Found nested 'properties' key inside arguments, flattening...")
                parametersDict = nestedProperties
            }

            // Convert string "true"/"false" values to booleans
            for (key, value) in parametersDict {
                if let stringValue = value as? String,
                   stringValue.lowercased() == "true" || stringValue.lowercased() == "false"
                {
                    parametersDict[key] = stringValue.lowercased() == "true"
                }
            }

            // Normalize to the standard format expected by decodeAndExecuteToolCall
            let normalizedDict: [String: Any] = [
                "name": toolName,
                "arguments": parametersDict
            ]

            // Convert normalized dictionary back to JSON
            let normalizedData = try JSONSerialization.data(withJSONObject: normalizedDict)
            let normalizedJson = String(data: normalizedData, encoding: .utf8) ?? ""

            logger.debug("Normalized JSON: \(normalizedJson)")

            return try await decodeAndExecuteToolCall(normalizedJson)
        } catch {
            logger.error("JSON processing error: \(error.localizedDescription)")
            throw ToolCallError.invalidJSON(error)
        }
    }

    /// Decodes the JSON into a MLXToolCall and dispatches execution.
    private func decodeAndExecuteToolCall(_ jsonString: String) async throws
        -> (executionResult: String, toolName: String)
    {
        guard let data = jsonString.data(using: .utf8) else {
            logger.error("Failed to convert JSON string to data.")
            throw ToolCallError.invalidJSON()
        }

        do {
            // At this point, the JSON should be normalized to the standard format expected by MLXToolCall
            let decodedCall = try decoder.decode(MLXToolCall.self, from: data)

            let toolName = decodedCall.name.rawValue
            logger.info("Decoded tool call for tool: \(toolName)")

            let result = try await processToolCallArgument(with: decodedCall.name, argument: decodedCall.parameters)
            return (executionResult: result, toolName: toolName)
        } catch {
            // If there's an issue with decoding, log the contents for debugging
            logger.error("Error decoding tool call: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                logger.error("Problem JSON content: \(jsonString)")
            }
            throw ToolCallError.invalidJSON(error)
        }
    }

    /// Dispatches to the correct tool based on the decoded tool call.
    private func processToolCallArgument(
        with name: MLXToolCallType,
        argument: MLXToolCallArguments
    ) async throws -> String {
        logger.info("Executing tool: \(name.rawValue)")

        let tools = await PetalMLXToolRegistry.mlxTools()

        guard let matchingTool = tools.first(where: {
            guard let mlxTool = $0 as? MLXCompatibleTool else {
                return false
            }
            return mlxTool.asMLXToolDefinition().function.name == name.rawValue
        }) else {
            logger.error("Unknown tool: \(name.rawValue)")
            throw ToolCallError.unknownTool(name.rawValue)
        }

        guard let mlxMatchingTool = matchingTool as? MLXCompatibleTool else {
            logger.error("Tool \(matchingTool.name) does not conform to MLXCompatibleTool.")
            throw ToolCallError.unknownTool(name.rawValue)
        }

        logger.debug("Matched tool: \(mlxMatchingTool.name)")
        
        // Telemetry capture
        let chatId = TelemetryContext.shared.currentChatId
        let messageId = TelemetryContext.shared.currentMessageId
        if let chatId, let messageId {
            TelemetryManager.shared.startTool(chatId: chatId, messageId: messageId, name: name.rawValue)
        }

        switch (mlxMatchingTool, argument) {
        case let (tool as PetalGenericFetchCanvasCoursesTool, .canvasCourses(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalGenericFetchCanvasCoursesTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: true)
                }
                return output.courses
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: false, errorDescription: error.localizedDescription)
                }
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }

        case let (tool as PetalFetchCanvasAssignmentsTool, .canvasAssignments(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalFetchCanvasAssignmentsTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                print(output.assignments)
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: true)
                }
                return output.assignments
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: false, errorDescription: error.localizedDescription)
                }
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }

        case let (tool as PetalFetchCanvasGradesTool, .canvasGrades(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalFetchCanvasGradesTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: true)
                }
                return output.grades
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: false, errorDescription: error.localizedDescription)
                }
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }

        case let (tool as PetalCalendarCreateEventTool, .calendarCreateEvent(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalCalendarCreateEventTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: true)
                }
                return output.event
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: false, errorDescription: error.localizedDescription)
                }
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }

        case let (tool as PetalCalendarFetchEventsTool, .calendarFetchEvents(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalCalendarFetchEventsTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: true)
                }
                return output.events
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: false, errorDescription: error.localizedDescription)
                }
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }

        #if os(iOS)
        case let (tool as PetalContactsTool, .contacts(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                var input = try JSONDecoder().decode(PetalContactsTool.Input.self, from: jsonData)

                // Heuristic: if a query is present but action says listContacts, treat as searchContacts
                if input.action == "listContacts",
                   let q = input.query?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !q.isEmpty
                {
                    input = PetalContactsTool.Input(
                        action: "searchContacts",
                        query: input.query,
                        limit: input.limit,
                        includePhones: input.includePhones,
                        includeEmails: input.includeEmails
                    )
                }

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: true)
                }
                // Return a human-readable list
                let text = output.contacts.isEmpty ? "No contacts found." : output.contacts.map { c in
                    var line = c.displayName
                    if !c.phoneNumbers.isEmpty { line += " • " + c.phoneNumbers.joined(separator: ", ") }
                    if !c.emails.isEmpty { line += " • " + c.emails.joined(separator: ", ") }
                    return line
                }.joined(separator: "\n")
                return text
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: false, errorDescription: error.localizedDescription)
                }
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }
        #endif

//        case let (tool as PetalFetchRemindersTool, .reminders(args)):
//            do {
//                let jsonData = try JSONEncoder().encode(args)
//                let input = try JSONDecoder().decode(PetalFetchRemindersTool.Input.self, from: jsonData)
//
//                let output = try await tool.execute(input)
//                logger.info("Tool \(name.rawValue) executed successfully.")
//
//                // Convert the array of reminders to a formatted string
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateStyle = .short
//                dateFormatter.timeStyle = .short
//
//                let reminderStrings = output.reminders.map { reminder in
//                    let status = reminder.completed ? "[✓]" : "[ ]"
//                    let dueString = reminder.dueDate != nil ? " (Due: \(reminder.dueDate!))" : ""
//                    return "\(status) \(reminder.title)\(dueString)"
//                }
//
//                let result = reminderStrings.isEmpty ?
//                    "No reminders found." :
//                    reminderStrings.joined(separator: "\n")
//
//                return result
//            } catch {
//                logger.error("Error executing tool \(name.rawValue): \(error)")
//                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
//            }
//
        #if os(macOS)
        case let (tool as PetalNotesTool, .notes(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalNotesTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: true)
                }
                return output.result
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: false, errorDescription: error.localizedDescription)
                }
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }

        case let (tool as PetalRemindersTool, .reminders(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalRemindersTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")

                // Convert the output to a formatted string
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: true)
                }
                return output.result
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                if let chatId, let messageId {
                    TelemetryManager.shared.endTool(chatId: chatId, messageId: messageId, name: name.rawValue, success: false, errorDescription: error.localizedDescription)
                }
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }
        #endif

        default:
            let argumentTypeDescription = String(describing: type(of: argument))
            logger.error("Unhandled argument type for tool \(name.rawValue): \(argumentTypeDescription)")
            throw ToolCallError
                .invalidArguments(
                    "Arguments (\(argumentTypeDescription)) do not match expected for tool \(name.rawValue)"
                )
        }
    }
}

// MARK: - ToolCallError + Equatable

extension ToolCallError: Equatable {
    public static func == (lhs: ToolCallError, rhs: ToolCallError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidJSON, .invalidJSON):
            true
        case let (.invalidArguments(lMsg), .invalidArguments(rMsg)):
            lMsg == rMsg
        case let (.unknownTool(lName), .unknownTool(rName)):
            lName == rName
        case let (.toolExecutionFailed(lName, _), .toolExecutionFailed(rName, _)):
            lName == rName
        case let (.formatError(lMsg), .formatError(rMsg)):
            lMsg == rMsg
        default:
            false
        }
    }
}
