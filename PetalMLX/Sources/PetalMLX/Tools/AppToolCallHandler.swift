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
        logger.debug("Processing LLM output: \(result.output.prefix(500))...")
        let text = result.output

        // FIRST: Try Llama-style format (<|python_tag|> ... <|eom_id|>)
        do {
            let (executionResult, toolName) = try await handleLlamaFormat(text)
            logger.info("Llama format tool call '\(toolName)' processed successfully.")
            return (processedOutput: executionResult, toolCalled: true, toolName: toolName)
        } catch let error as ToolCallError where error == .formatError("Llama tags not found") {
            logger.debug("Llama format not detected.")
        } catch {
            logger.error("Error processing Llama format: \(error)")
            throw error
        }

        // SECOND: Try generic format (e.g. <tool_call>...</tool_call>)
        if text.contains("<tool_call>") {
            logger.debug("Attempting to handle generic tool_call format")
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
                    throw error
                }
            } else {
                logger.warning("Found <tool_call> but not a complete tag pair; treating as regular text.")
            }
        }

        // No tool call detected; return the original text.
        logger.debug("No tool call format detected.")
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

        return try await decodeAndExecuteToolCall(jsonString)
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
        return try await decodeAndExecuteToolCall(jsonString)
    }

    /// Decodes the JSON into a MLXToolCall and dispatches execution.
    private func decodeAndExecuteToolCall(_ jsonString: String) async throws
        -> (executionResult: String, toolName: String)
    {
        guard let data = jsonString.data(using: .utf8) else {
            logger.error("Failed to convert JSON string to data.")
            throw ToolCallError.invalidJSON()
        }

        // Try to parse JSON to dictionary first
        do {
            let jsonObj = try JSONSerialization.jsonObject(with: data)
            guard var dict = jsonObj as? [String: Any] else {
                logger.error("JSON is not a dictionary")
                throw ToolCallError.invalidJSON()
            }

            // Extract the tool name
            guard let name = dict["name"] as? String else {
                logger.error("Missing 'name' field in tool call JSON")
                throw ToolCallError.invalidJSON()
            }

            // Check if parameters exists and rename to arguments
            var parametersDict: [String: Any] = [:]
            if let params = dict["parameters"] as? [String: Any] {
                parametersDict = params
            } else if let args = dict["arguments"] as? [String: Any] {
                parametersDict = args
            }

            // Convert string "true"/"false" to boolean values if needed
            for (key, value) in parametersDict {
                if let stringValue = value as? String,
                   stringValue.lowercased() == "true" || stringValue.lowercased() == "false"
                {
                    parametersDict[key] = stringValue.lowercased() == "true"
                }
            }

            // Create a properly formatted dictionary with the proper types
            dict["arguments"] = parametersDict
            if dict["parameters"] != nil {
                dict.removeValue(forKey: "parameters")
            }

            // Convert back to JSON data with the correct key and proper boolean values
            let correctedData = try JSONSerialization.data(withJSONObject: dict)

            let decodedCall = try decoder.decode(MLXToolCall.self, from: correctedData)

            let toolName = decodedCall.name.rawValue
            logger.info("Decoded tool call for tool: \(toolName)")

            let result = try await processToolCallArgument(with: decodedCall.name, argument: decodedCall.parameters)
            return (executionResult: result, toolName: toolName)
        } catch {
            logger.error("JSON processing or decoding error: \(error.localizedDescription)")
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

        switch (mlxMatchingTool, argument) {
        case let (tool as PetalGenericFetchCanvasCoursesTool, .canvasCourses(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalGenericFetchCanvasCoursesTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                return output.courses
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }
            
        case let (tool as PetalFetchCanvasAssignmentsTool, .canvasAssignments(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalFetchCanvasAssignmentsTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                return output.assignments
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }
            
        case let (tool as PetalFetchCanvasGradesTool, .canvasGrades(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalFetchCanvasGradesTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                return output.grades
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }
            
        case let (tool as PetalCalendarCreateEventTool, .calendarCreateEvent(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalCalendarCreateEventTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                return output.event
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }
            
        case let (tool as PetalCalendarFetchEventsTool, .calendarFetchEvents(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalCalendarFetchEventsTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                return output.events
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }
            
        case let (tool as PetalFetchRemindersTool, .reminders(args)):
            do {
                let jsonData = try JSONEncoder().encode(args)
                let input = try JSONDecoder().decode(PetalFetchRemindersTool.Input.self, from: jsonData)

                let output = try await tool.execute(input)
                logger.info("Tool \(name.rawValue) executed successfully.")
                
                // Convert the array of reminders to a formatted string
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                
                let reminderStrings = output.reminders.map { reminder in
                    let status = reminder.completed ? "[✓]" : "[ ]"
                    let dueString = reminder.dueDate != nil ? " (Due: \(reminder.dueDate!))" : ""
                    return "\(status) \(reminder.title)\(dueString)"
                }
                
                let result = reminderStrings.isEmpty ? 
                    "No reminders found." : 
                    reminderStrings.joined(separator: "\n")
                
                return result
            } catch {
                logger.error("Error executing tool \(name.rawValue): \(error)")
                throw ToolCallError.toolExecutionFailed(name.rawValue, error)
            }
            
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
