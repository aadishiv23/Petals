//
//  ConversationViewModel.swift
//  PetalsiOS
//
//  Created for iOS target
//

import Foundation
import GoogleGenerativeAI
import MLXLMCommon
import PetalCore
import PetalMLX
import SwiftUI

/// A view model for managing conversation interactions
@MainActor
class ConversationViewModel: ObservableObject {

    // MARK: Published Properties

    /// An array of chat messages in the conversation
    @Published var messages = [ChatMessage]()

    /// A boolean indicating whether the system is currently processing a request
    @Published var busy = false
    @Published var isProcessingTool = false

    /// Stores any errors encountered during message processing
    @Published var error: Error?

    /// The currently selected AI model name
    @Published var selectedModel: String {
        didSet {
            startNewChat()
        }
    }

    /// A boolean indicating whether to use MLX (local model) instead of Gemini (Google API)
    @Published var useMLX: Bool = false {
        didSet {
            switchModel()
        }
    }
    
    // Chat history management
    @Published var chatHistory: [ChatHistory] = []
    @Published var currentChatTitle: String = "New Chat"

    // MARK: Private Properties

    /// The active AI chat model being used for conversation
    private var chatModel: AIChatModel

    private let toolEvaluator = ToolTriggerEvaluator()

    // MARK: Initializer

    /// Initializes the view model with a default AI model and sets up the chat session
    init() {
        let initialModel = "gemini-1.5-flash-latest"
        self.selectedModel = initialModel
        self.chatModel = GeminiChatModel(modelName: initialModel)
        startNewChat()
    }

    // MARK: Chat Management

    /// Starts a new chat session by clearing existing messages
    func startNewChat() {
        stop()
        error = nil
        messages.removeAll()
        switchModel()
        currentChatTitle = "New Chat"
    }

    /// Stops any ongoing tasks and clears any errors
    func stop() {
        error = nil
    }

    /// Switches the active AI model between Gemini and MLX
    private func switchModel() {
        if useMLX {
            let modelConfig = ModelConfiguration.defaultModel
            chatModel = PetalMLXChatModel(model: modelConfig)
            print("🔵 Now using PetalML (local model) with \(modelConfig.name)")
        } else {
            chatModel = GeminiChatModel(modelName: selectedModel)
            print("🟢 Now using Gemini (Google API) with model: \(selectedModel)")
        }
    }

    // MARK: Message Handling

    /// Sends a user message to the AI model and appends the response to the conversation
    func sendMessage(_ text: String, streaming: Bool = true) async {
        error = nil
        busy = true

        let needsTool = messageRequiresTool(text)
        isProcessingTool = needsTool

        messages.append(ChatMessage(message: text, participant: .user))
        // For tool calls, start with an empty message but mark it as pending
        let pendingMessage = ChatMessage.pending(participant: .llm)
        messages.append(pendingMessage)

        do {
            if streaming {
                let stream = chatModel.sendMessageStream(text)
                
                // Process the stream
                for try await chunk in stream {
                    // If this is a tool call, don't update the message content until we have the final result
                    if isProcessingTool {
                        // Only update if we actually get content back (which would be the final processed result)
                        if !chunk.message.isEmpty {
                            messages[messages.count - 1].message = chunk.message
                        }
                        
                        if let toolName = chunk.toolCallName {
                            messages[messages.count - 1].toolCallName = toolName
                        }
                    } else {
                        // For regular messages, append each chunk
                        messages[messages.count - 1].message += chunk.message
                    }
                }
                
                // After stream completes, mark as not pending
                messages[messages.count - 1].pending = false
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

    // MARK: Tool Trigger Evaluation

    private func messageRequiresTool(_ text: String) -> Bool {
        return ExemplarProvider.shared.shouldUseTools(for: text)
    }

    // MARK: Chat History Management
    
    /// Selects a chat from history by ID
    func selectChat(_ id: UUID) {
        guard let index = chatHistory.firstIndex(where: { $0.id == id }) else {
            return
        }
        // Load this chat
        // Implementation details depend on how you store chat content
        currentChatTitle = chatHistory[index].title
    }

    /// Deletes chats at the specified indices
    func deleteChats(_ indexSet: IndexSet) {
        chatHistory.remove(atOffsets: indexSet)
    }
} 