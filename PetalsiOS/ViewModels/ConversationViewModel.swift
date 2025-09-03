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
    @Published var currentChatId: UUID?
    @Published var currentChatTitle: String = "New Chat"
    
    /// UserDefaults key for chat history persistence
    private let chatHistoryKey = "SavedChatHistory"

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
        loadChatHistory()
        startNewChat()
    }

    // MARK: Chat Management

    /// Starts a new chat session by clearing existing messages
    func startNewChat() {
        stop()
        error = nil
        messages.removeAll()
        currentChatId = UUID()
        currentChatTitle = "New Chat"
        switchModel()
    }
    
    /// Creates a new chat and adds it to history
    func createNewChat() -> UUID {
        // Save current chat if it has messages
        if !messages.isEmpty && currentChatId != nil {
            saveCurrentChatToHistory()
        }
        
        startNewChat()
        return currentChatId!
    }
    
    /// Saves the current chat session to history
    func saveCurrentChatToHistory() {
        guard let chatId = currentChatId, !messages.isEmpty else { return }
        
        // Generate a title from the first user message
        let firstUserMessage = messages.first { $0.participant == .user }
        let title = firstUserMessage?.message.prefix(50).description ?? "New Chat"
        
        // Get the last message for preview
        let lastMessage = messages.last?.message.prefix(100).description
        
        // Check if chat already exists in history
        if let existingIndex = chatHistory.firstIndex(where: { $0.id == chatId }) {
            // Update existing chat
            chatHistory[existingIndex].title = String(title)
            chatHistory[existingIndex].lastMessage = lastMessage
            chatHistory[existingIndex].lastActivityDate = Date()
            chatHistory[existingIndex].messages = messages
        } else {
            // Create new chat entry
            let newChat = ChatHistory(
                id: chatId,
                title: String(title),
                lastMessage: lastMessage,
                lastActivityDate: Date(),
                messages: messages
            )
            chatHistory.insert(newChat, at: 0) // Add to the beginning
        }
        
        saveChatHistory()
    }
    
    /// Loads a specific chat from history
    func loadChat(_ chatId: UUID) {
        // Save current chat first if it has messages
        if !messages.isEmpty && currentChatId != nil {
            saveCurrentChatToHistory()
        }
        
        currentChatId = chatId
        
        if let chat = chatHistory.first(where: { $0.id == chatId }) {
            currentChatTitle = chat.title
            // Load the actual messages from the saved chat
            messages = chat.messages
        }
        
        error = nil
        switchModel()
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
        
        // Auto-save chat to history after receiving a response
        if !messages.isEmpty && currentChatId != nil {
            saveCurrentChatToHistory()
        }
    }

    // MARK: Tool Trigger Evaluation

    private func messageRequiresTool(_ text: String) -> Bool {
        return ExemplarProvider.shared.shouldUseTools(for: text)
    }

    // MARK: Chat History Management
    
    /// Selects a chat from history by ID
    func selectChat(_ id: UUID) {
        loadChat(id)
    }

    /// Deletes chats at the specified indices
    func deleteChats(_ indexSet: IndexSet) {
        chatHistory.remove(atOffsets: indexSet)
        saveChatHistory()
    }
    
    /// Deletes a specific chat by ID
    func deleteChat(_ chatId: UUID) {
        chatHistory.removeAll { $0.id == chatId }
        saveChatHistory()
    }
    
    /// Clears all chat history
    func clearAllChatHistory() {
        chatHistory.removeAll()
        saveChatHistory()
    }
    
    // MARK: Persistence
    
    /// Loads chat history from UserDefaults
    private func loadChatHistory() {
        guard let data = UserDefaults.standard.data(forKey: chatHistoryKey),
              let decodedHistory = try? JSONDecoder().decode([ChatHistory].self, from: data) else {
            return
        }
        chatHistory = decodedHistory
    }
    
    /// Saves chat history to UserDefaults
    private func saveChatHistory() {
        guard let encoded = try? JSONEncoder().encode(chatHistory) else { return }
        UserDefaults.standard.set(encoded, forKey: chatHistoryKey)
    }
} 