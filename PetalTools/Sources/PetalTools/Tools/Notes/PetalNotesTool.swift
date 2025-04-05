//
//  PetalNotesTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra
//

import AppKit
import Foundation
import PetalCore
import os

/// A tool to interact with Apple Notes app.
public final class PetalNotesTool: OllamaCompatibleTool, MLXCompatibleTool {

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.Petal.PetalTools",
        category: "PetalNotesTool"
    )

    public init() {}

    // MARK: - PetalTool Protocol

    public let uuid: UUID = .init()
    public var id: String { "petalNotesTool" }
    public var name: String { "Petal Notes Tool" }
    public var description: String { "Allows interaction with Apple Notes app (find, create, and list notes)." }
    public var triggerKeywords: [String] { ["notes", "note", "memo", "memos"] }
    public var domain: String { "notes" }
    public var requiredPermission: PetalToolPermission { .basic }

    // MARK: - Parameter Definitions

    public var parameters: [PetalToolParameter] {
        [
            PetalToolParameter(
                name: "action",
                description: "The action to perform: 'getAllNotes', 'findNote', or 'createNote'",
                dataType: .string,
                required: true,
                example: AnyCodable("createNote")
            ),
            PetalToolParameter(
                name: "searchText",
                description: "Text to search for when using findNote action",
                dataType: .string,
                required: false,
                example: AnyCodable("Project ideas")
            ),
            PetalToolParameter(
                name: "title",
                description: "Title for the new note when using createNote action",
                dataType: .string,
                required: false,
                example: AnyCodable("Meeting notes")
            ),
            PetalToolParameter(
                name: "body",
                description: "Content for the new note when using createNote action",
                dataType: .string,
                required: false,
                example: AnyCodable("# Meeting Notes\n\n- Discuss project timeline\n- Review budget")
            ),
            PetalToolParameter(
                name: "folderName",
                description: "Folder for storing the note when using createNote action (defaults to 'Claude')",
                dataType: .string,
                required: false,
                example: AnyCodable("Work")
            )
        ]
    }

    // MARK: - Tool Input/Output

    public struct NoteInfo: Codable, Sendable {
        public let name: String
        public let content: String
    }

    public struct CreateNoteResult: Codable, Sendable {
        public let success: Bool
        public let note: NoteInfo?
        public let message: String?
        public let folderName: String?
        public let usedDefaultFolder: Bool?
    }

    public struct Input: Codable, Sendable {
        public let action: String
        public let searchText: String?
        public let title: String?
        public let body: String?
        public let folderName: String?
    }

    public struct Output: Codable, Sendable {
        public let result: String
    }

    // MARK: - Tool Execution

    public func execute(_ input: Input) async throws -> Output {
        logger.debug("Executing Notes Tool with action: \(input.action)")
        do {
            switch input.action {
            case "getAllNotes":
                logger.debug("Calling getAllNotes()")
                let notes = try await getAllNotes()
                let formattedNotes = formatNotes(notes)
                logger.debug("getAllNotes successful, found \(notes.count) notes.")
                return Output(result: formattedNotes)

            case "findNote":
                guard let searchText = input.searchText, !searchText.isEmpty else {
                    logger.warning("searchText missing for findNote action.")
                    return Output(result: "Error: searchText is required for findNote action")
                }
                logger.debug("Calling findNote(searchText: '\(searchText)'")
                let notes = try await findNote(searchText: searchText)
                if notes.isEmpty {
                    logger.debug("findNote: No notes found matching '\(searchText)'")
                    return Output(result: "No notes found matching '\(searchText)'")
                }
                logger.debug("findNote successful, found \(notes.count) notes.")
                let formattedNotes = formatNotes(notes)
                return Output(result: formattedNotes)

            case "createNote":
                guard let title = input.title, !title.isEmpty else {
                    logger.warning("title missing for createNote action.")
                    return Output(result: "Error: title is required for createNote action")
                }
                guard let body = input.body, !body.isEmpty else {
                    logger.warning("body missing for createNote action.")
                    return Output(result: "Error: body is required for createNote action")
                }
                let folderName = input.folderName ?? "Claude"
                logger.debug("Calling createNote(title: '\(title)', folder: '\(folderName)'")
                let result = try await createNote(title: title, body: body, folderName: folderName)

                if result.success {
                    let message = "Note '\(title)' successfully created in folder '\(result.folderName ?? folderName)' " +
                                  (result.usedDefaultFolder == true ? " (default folder was used)" : "")
                    logger.debug("createNote successful: \(message)")
                    return Output(result: message)
                } else {
                    logger.error("createNote failed: \(result.message ?? "Unknown reason")")
                    return Output(result: result.message ?? "Failed to create note for unknown reason")
                }

            default:
                logger.warning("Invalid action requested: \(input.action)")
                return Output(result: "Error: Invalid action '\(input.action)'. Use 'getAllNotes', 'findNote', or 'createNote'")
            }
        } catch let error as NSError {
            logger.error("Error executing Notes tool: \(error.domain) - Code \(error.code) - \(error.localizedDescription)")
            logger.error("Underlying Error Info: \(error.userInfo)")

            // Handle AppleScript errors specifically
            if error.domain == "AppleScriptError" {
                if error.localizedDescription.contains("Application isn't running") || error.code == -600 {
                    logger.error("Detected specific error: Notes app not running or inaccessible (-600).")
                    return Output(result: "Error: The Notes app is not running or could not be accessed. Please ensure it is open and try again.")
                }
                if error.localizedDescription.contains("not authorized") || error.code == -1743 {
                    logger.error("Detected specific error: Automation permission denied (-1743).")
                    return Output(result: "Error: This app doesn't have permission to control Notes. Please check System Settings > Privacy & Security > Automation and grant permission.")
                }
                let shortError = error.localizedDescription.components(separatedBy: "NSAppleScriptError").first ?? error.localizedDescription
                logger.error("Returning generic AppleScript error message: \(shortError)")
                return Output(result: "Error accessing Notes: \(shortError)")
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

    private func getAllNotes() async throws -> [NoteInfo] {
        // Create an AppleScript task to get all notes
        let script = """
        tell application "System Events"
            if not (exists process "Notes") then
                tell application "Notes" to activate
                delay 2
            end if
        end tell

        tell application "Notes"
            set allNotes to every note
            set noteList to {}

            repeat with currentNote in allNotes
                set noteInfo to {name:name of currentNote, content:plaintext of currentNote}
                set end of noteList to noteInfo
            end repeat

            return noteList
        end tell
        """

        let result = try await runAppleScript(script)
        return parseNotesResult(result)
    }

    private func findNote(searchText: String) async throws -> [NoteInfo] {
        // Create an AppleScript task to find notes matching search text
        let script = """
        tell application "System Events"
            if not (exists process "Notes") then
                tell application "Notes" to activate
                delay 2
            end if
        end tell

        tell application "Notes"
            set matchingNotes to notes where name contains "\(
                escapeAppleScriptString(searchText)
            )" or plaintext contains "\(escapeAppleScriptString(searchText))"

            if length of matchingNotes is 0 then
                return {}
            end if

            set noteList to {}
            repeat with currentNote in matchingNotes
                set noteInfo to {name:name of currentNote, content:plaintext of currentNote}
                set end of noteList to noteInfo
            end repeat

            return noteList
        end tell
        """

        let result = try await runAppleScript(script)
        let notes = parseNotesResult(result)

        if notes.isEmpty {
            // Try to find a close match from all notes
            let allNotes = try await getAllNotes()
            let lowerSearchText = searchText.lowercased()
            if let closestMatch = allNotes.first(where: { $0.name.lowercased().contains(lowerSearchText) }) {
                return [closestMatch]
            }
        }

        return notes
    }

    private func createNote(
        title: String,
        body: String,
        folderName: String = "Claude"
    ) async throws -> CreateNoteResult {
        // Format the body for display/storage
        let formattedBody = formatNoteBody(body)
        // Format the body specifically for embedding in AppleScript (use \r)
        let appleScriptBody = formattedBody.replacingOccurrences(of: "\n", with: "\r")
        
        logger.debug("Creating note. Title: '\(title)', Folder: '\(folderName)', Body for AppleScript: \(appleScriptBody.prefix(50))...")

        // Create an AppleScript task to create a note
        let script = """
        tell application "System Events"
            if not (exists process "Notes") then
                tell application "Notes" to activate
                delay 2
            end if
        end tell
        
        tell application "Notes"
            -- No need to activate again here
            
            -- Try to find the specified folder
            set targetFolder to null
            set folderFound to false
            set usedDefaultFolder to false
            set actualFolderName to "\(escapeAppleScriptString(folderName))"
            
            set allFolders to every folder
            repeat with currentFolder in allFolders
                if name of currentFolder is "\(escapeAppleScriptString(folderName))" then
                    set targetFolder to currentFolder
                    set folderFound to true
                    exit repeat
                end if
            end repeat
            
            -- If the specified folder doesn't exist
            if not folderFound then
                if "\(escapeAppleScriptString(folderName))" is "Claude" then
                    -- Try to create the Claude folder
                    try
                        make new folder with properties {name:"Claude"}
                        set usedDefaultFolder to true
                        
                        -- Find it again after creation
                        set allFolders to every folder
                        repeat with currentFolder in allFolders
                            if name of currentFolder is "Claude" then
                                set targetFolder to currentFolder
                                set folderFound to true
                                exit repeat
                            end if
                        end repeat
                    on error
                        set folderFound to false
                    end try
                end if
            end if
            
            -- Create the note
            if folderFound then
                set newNote to make new note with properties {name:"\(escapeAppleScriptString(title))", body:"\(escapeAppleScriptString(appleScriptBody))"} at targetFolder
                return {success:true, folderName:actualFolderName, usedDefaultFolder:usedDefaultFolder}
            else
                -- Fall back to default folder
                set newNote to make new note with properties {name:"\(escapeAppleScriptString(title))", body:"\(escapeAppleScriptString(appleScriptBody))"}
                return {success:true, folderName:"Default", usedDefaultFolder:true}
            end if
        end tell
        """
        
        let resultString = try await runAppleScript(script)
        // Pass the original formattedBody (with \n) for the result struct
        return parseCreateNoteResult(resultString, title: title, body: formattedBody) 
    }

    // MARK: - Helper Functions

    private func formatNotes(_ notes: [NoteInfo]) -> String {
        if notes.isEmpty {
            return "No notes found."
        }

        var result = "Found \(notes.count) note(s):\n\n"

        for (index, note) in notes.enumerated() {
            result += "[\(index + 1)] \(note.name)\n"

            // Add the first few lines of the note content
            let contentPreview = previewContent(note.content)
            result += "\(contentPreview)\n\n"
        }

        return result
    }

    private func previewContent(_ content: String) -> String {
        let maxLines = 3
        let maxCharsPerLine = 80

        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        var preview = ""

        for (index, line) in lines.prefix(maxLines).enumerated() {
            let trimmedLine = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
            let truncatedLine = trimmedLine.count > maxCharsPerLine
                ? trimmedLine.prefix(maxCharsPerLine) + "..."
                : trimmedLine

            preview += "  \(truncatedLine)\n"
        }

        if lines.count > maxLines {
            preview += "  ...\n"
        }

        return preview
    }

    private func formatNoteBody(_ body: String) -> String {
        body
            .replacingOccurrences(of: #"^(#+)\s+(.+)$"#, with: "$1 $2\n", options: .regularExpression)
            .replacingOccurrences(of: #"^-\s+(.+)$"#, with: "\n- $1", options: .regularExpression)
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func escapeAppleScriptString(_ str: String) -> String {
        str.replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func runAppleScript(_ script: String) async throws -> String {
        logger.debug("Attempting to run AppleScript:\n--- SCRIPT START ---\n\(script)\n--- SCRIPT END ---\n")

        // Now run the actual script
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

    private func parseNotesResult(_ result: String) -> [NoteInfo] {
        // Simple parsing logic - this is a simplification and may need enhancements
        // In a real implementation, you'd need more robust parsing of AppleScript results
        let lines = result.split(separator: "\n")
        var notes: [NoteInfo] = []

        var currentNote: (name: String, content: String)?

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.starts(with: "name:") {
                // If we were building a note, add it to the list
                if let note = currentNote {
                    notes.append(NoteInfo(name: note.name, content: note.content))
                }

                // Start a new note
                let nameValue = String(trimmedLine.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentNote = (name: nameValue, content: "")
            } else if trimmedLine.starts(with: "content:"), let note = currentNote {
                let contentValue = String(trimmedLine.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentNote = (name: note.name, content: contentValue)

                // Add this note to our list
                notes.append(NoteInfo(name: note.name, content: contentValue))
                currentNote = nil
            }
        }

        // Add the last note if we have one
        if let note = currentNote {
            notes.append(NoteInfo(name: note.name, content: note.content))
        }

        return notes
    }

    private func parseCreateNoteResult(_ result: String, title: String, body: String) -> CreateNoteResult {
        // Simple parsing logic - this is a simplification
        if result.contains("success:true") {
            let folderName = extractValue(from: result, key: "folderName")
            let usedDefaultFolder = result.contains("usedDefaultFolder:true")

            return CreateNoteResult(
                success: true,
                note: NoteInfo(name: title, content: body),
                message: nil,
                folderName: folderName,
                usedDefaultFolder: usedDefaultFolder
            )
        } else if result == "" {
            return CreateNoteResult(
                success: true,
                note: NoteInfo(name: title, content: body),
                message: "Created message with title: \(title) and body: \(body).",
                folderName: nil,
                usedDefaultFolder: nil
            )
        } else {
            return CreateNoteResult(
                success: false,
                note: nil,
                message: "Failed to create note: \(result)",
                folderName: nil,
                usedDefaultFolder: nil
            )
        }
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
                            description: "The action to perform: 'getAllNotes', 'findNote', or 'createNote'"
                        ),
                        "searchText": OllamaFunctionProperty(
                            type: "string",
                            description: "Text to search for when using findNote action"
                        ),
                        "title": OllamaFunctionProperty(
                            type: "string",
                            description: "Title for the new note when using createNote action"
                        ),
                        "body": OllamaFunctionProperty(
                            type: "string",
                            description: "Content for the new note when using createNote action"
                        ),
                        "folderName": OllamaFunctionProperty(
                            type: "string",
                            description: "Folder for storing the note when using createNote action (defaults to 'Claude')"
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
                name: "petalNotesTool",
                description: "Allows interaction with Apple Notes app (find, create, and list notes).",
                parameters: MLXParametersDefinition(
                    type: "object",
                    properties: [
                        "action": MLXParameterProperty(
                            type: "string",
                            description: "The action to perform: 'getAllNotes', 'findNote', or 'createNote'"
                        ),
                        "searchText": MLXParameterProperty(
                            type: "string",
                            description: "Text to search for when using findNote action"
                        ),
                        "title": MLXParameterProperty(
                            type: "string",
                            description: "Title for the new note when using createNote action"
                        ),
                        "body": MLXParameterProperty(
                            type: "string",
                            description: "Content for the new note when using createNote action"
                        ),
                        "folderName": MLXParameterProperty(
                            type: "string",
                            description: "Folder for storing the note when using createNote action (defaults to 'Claude')"
                        )
                    ],
                    required: ["action"]
                )
            )
        )
    }
}

/*
 Show me all my notes
 Find my notes about project ideas
 Create a new note titled "Meeting with Sam" with content "# Discussion Points
 
 - Project timeline
 - Budget concerns
 - Next steps"
 */
