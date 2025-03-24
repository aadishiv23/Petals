//
//  ConversationalViewModel.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import GoogleGenerativeAI
import SwiftUI

/// A view model for managing conversation interactions in the `Petals` app.
///
/// This class handles sending messages, switching between AI models (Gemini and Ollama),
/// managing system instructions, and processing streaming or single-response messages.
@MainActor
class ConversationViewModel: ObservableObject {

    // MARK: Dependencies

    private let repository: ChatRepository

    // MARK: Published Properties

    /// An array of chat messages in the conversation.
    @Published var messages = [ChatMessage]()

    /// The current conversation?
    @Published var currentConversation: Conversation?

    /// A boolean indicating whether the system is currently processing a request.
    @Published var busy = false
    @Published var isProcessingTool = false

    /// Stores any errors encountered during message processing.
    @Published var error: Error?

    /// A computed property that returns `true` if there is an error.
    var hasError: Bool { error != nil }

    /// The currently selected AI model name.
    /// Changing this value starts a new conversation.
    @Published var selectedModel: String {
        didSet {
            startNewChat()
        }
    }

    /// A boolean indicating whether to use Ollama (local model) instead of Gemini (Google API).
    /// Changing this value switches the active model.
    @Published var useOllama: Bool = false {
        didSet {
            switchModel()
        }
    }

    // MARK: Private Properties

    /// The active AI chat model being used for conversation.
    private var chatModel: AIChatModel

    private let toolEvaluator = ToolTriggerEvaluator()

    // MARK: Initializer

    /// Initializes the view model with a default AI model and sets up the chat session.
    /// Gemini models are initialized in this particular format, changing this will result in errors.
    /// Ollama models are initialized inside their respective ViewModel.
    init(repository: ChatRepository = CoreDataChatRepository()) {
        self.repository = repository
        let initialModel = "gemini-1.5-flash-latest"
        self.selectedModel = initialModel
        self.chatModel = GeminiChatModel(modelName: initialModel)
        startNewChat()
    }

    // MARK: Chat Management

    /// Starts a new chat session by clearing existing messages and adding system instructions.
    ///
    /// This function resets any ongoing conversation and provides the AI with an initial system instruction
    /// to define its behavior, particularly around tool usage.
    func startNewChat() {
        stop()
        error = nil
        messages.removeAll()

//        let systemInstruction = ChatMessage(
//            message: """
//            System: You are a helpful assistant. Only call the function 'fetchCalendarEvents' if the user's request explicitly asks for calendar events (with a date in YYYY-MM-DD format). Otherwise, respond conversationally without invoking any functions.
//            """,
//            participant: .system
//        )
//
//        messages.append(systemInstruction)

        let conversation = repository
            .createConversation(title: "Chat - \(Date().formatted(date: .numeric, time: .shortened))")
        currentConversation = conversation
        switchModel()
    }

    /// Stops any ongoing tasks and clears any errors.
    func stop() {
        error = nil
    }

    /// Switches the active AI model between Gemini and Ollama.
    ///
    /// When switching, this function updates the chat model instance
    /// and optionally resets the conversation history.
    private func switchModel() {
        if useOllama {
            chatModel = OllamaChatModel()
            print("🔵 Now using Ollama (local model)")
        } else {
            chatModel = GeminiChatModel(modelName: selectedModel)
            print("🟢 Now using Gemini (Google API) with model: \(selectedModel)")
        }
    }

    // MARK: Message Handling

    /// Sends a user message to the AI model and appends the response to the conversation.
    ///
    /// - Parameters:
    ///   - text: The message content to be sent to the AI model.
    ///   - streaming: A boolean indicating whether to use streaming responses.
    ///
    /// This function:
    /// - Appends the user message to the conversation history.
    /// - Sends the message to the AI model.
    /// - Processes the response, either as a single reply or a streaming response.
    /// - Updates the conversation history with the AI's reply.
    ///
    /// If an error occurs, it is stored in `error`, and the pending message is removed.
    func sendMessage(_ text: String, streaming: Bool = true) async {
        error = nil
        busy = true

        let needsTool = messageRequiresTool(text)
        isProcessingTool = needsTool

        let userMessage = ChatMessage(message: text, participant: .user)
        messages.append(userMessage)
        repository.addMessage(userMessage, to: currentConversation!)

        // Also update the in-memory conversation struct:
        currentConversation?.messages.append(userMessage)

        let pendingResponse = ChatMessage.pending(participant: .system)
        messages.append(pendingResponse)
        repository.addMessage(pendingResponse, to: currentConversation!)

        // Update in-memory struct for pending response:
        currentConversation?.messages.append(pendingResponse)

        let contextString = currentConversation?.fullContext(withCurrentMessage: userMessage)
            ?? userMessage.message

        do {
            if streaming {
                // Build the context using the conversation history plus the new user message.
                let stream = chatModel.sendMessageStream(contextString)

                for await chunk in stream {
                    var systemMsg = messages.removeLast()
                    systemMsg.message += chunk.message
                    systemMsg.pending = false
                    messages.append(systemMsg)

                    // Also persist updated message
                    repository.addMessage(systemMsg, to: currentConversation!)

                    if let toolName = chunk.toolCallName {
                        messages[messages.count - 1].toolCallName = toolName
                    }
                    messages[messages.count - 1].pending = false
                }
            } else {
                let response = try await chatModel.sendMessage(text)
                messages[messages.count - 1].message = response
                messages[messages.count - 1].pending = false
            }
        } catch {
            self.error = error
            messages.removeLast()
        }
        busy = false
        isProcessingTool = false
    }

    func loadConversation(_ conversation: Conversation) {
        currentConversation = conversation
        messages = repository.fetchMessages(for: conversation)
    }

    /// Retrieve context (for example, when sending the conversation history to your AI model).
    func conversationContext() -> String {
        currentConversation?.fullContext() ?? ""
    }

//    private func messageRequiresTool(_ text: String) -> Bool {
//        // Define criteria for triggering tools (dates, explicit phrases, etc.)
//        let toolPatterns = [
//            "\\d{4}-\\d{2}-\\d{2}", // Date in YYYY-MM-DD format
//            "(calendar|event|schedule|appointment)", // Explicit calendar keywords
//            "(canvas|courses|course|class|classes)",
//            "(grade|grades|performance|assignment)"
//        ]
//
//        return toolPatterns.contains { pattern in
//            text.range(of: pattern, options: .regularExpression) != nil
//        }
//    }

    // MARK: Tool Trigger Evaluation (Using `ToolTriggerEvaluator`)

    private func messageRequiresTool(_ text: String) -> Bool {
        let toolExemplars: [String: [String]] = [
            "petalCalendarFetchEventsTool": [
                "Fetch calendar events for me",
                "Show calendar events",
                "List my events",
                "Get events from my calendar",
                "Retrieve calendar events"
            ],
            "petalCalendarCreateEventTool": [
                "Create a calendar event on [date]",
                "Schedule a new calendar event",
                "Add a calendar event to my schedule",
                "Book an event on my calendar",
                "Set up a calendar event"
            ],
            "petalFetchRemindersTool": [
                "Show me my reminders",
                "List my tasks for today",
                "Fetch completed reminders",
                "Get all my pending reminders",
                "Find reminders containing 'doctor'"
            ],
            "petalFetchCanvasAssignmentsTool": [
                "Fetch assignments for my course",
                "Show my Canvas assignments",
                "Get assignments for my class",
                "Retrieve course assignments from Canvas",
                "List assignments for my course"
            ],
            "petalFetchCanvasGradesTool": [
                "Show me my grades",
                "Get my Canvas grades",
                "Fetch my course grades",
                "Display grades for my class",
                "Retrieve my grades from Canvas"
            ]
        ]

        for (_, exemplars) in toolExemplars {
            if let prototype = toolEvaluator.prototype(for: exemplars) {
                if toolEvaluator.shouldTriggerTool(for: text, exemplarPrototype: prototype) {
                    return true
                }
            }
        }
        return false
    }
}
