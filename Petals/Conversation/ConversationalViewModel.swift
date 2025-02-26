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
    
    // MARK: Published Properties
    
    /// An array of chat messages in the conversation.
    @Published var messages = [ChatMessage]()
    
    /// A boolean indicating whether the system is currently processing a request.
    @Published var busy = false
    
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

    // MARK: Initializer
    
    /// Initializes the view model with a default AI model and sets up the chat session.
    /// Gemini models are initialized in this particular format, changing this will result in errors.
    /// Ollama models are initialized inside their respective ViewModel.
    init() {
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
        
        let systemInstruction = ChatMessage(
            message: """
            System: You are a helpful assistant. Only call the function 'fetchCalendarEvents' if the user's request explicitly asks for calendar events (with a date in YYYY-MM-DD format). Otherwise, respond conversationally without invoking any functions.
            """,
            participant: .system
        )
        
        messages.append(systemInstruction)
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

        // Append the user's message.
        messages.append(ChatMessage(message: text, participant: .user))

        // Append a pending system response.
        messages.append(ChatMessage.pending(participant: .system))

        do {
            if streaming {
                let stream = chatModel.sendMessageStream(text)
                for await chunk in stream {
                    messages[messages.count - 1].message += chunk
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
    }
}
