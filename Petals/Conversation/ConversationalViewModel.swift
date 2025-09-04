//
//  ConversationalViewModel.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import GoogleGenerativeAI
import MLXLMCommon
import PetalCore
import PetalMLX
import SwiftUI

/// A view model for managing conversation interactions in the `Petals` app.
///
/// This class handles sending messages, switching between AI models (Gemini and Ollama),
/// managing system instructions, and processing streaming or single-response messages.
@MainActor
class ConversationViewModel: ObservableObject {

    // MARK: Published Properties

    @Published var updateTrigger = UUID()

    /// An array of chat messages in the conversation.
    @Published var messages = [ChatMessage]()

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
    
    /// The currently selected MLX model configuration
    @Published var selectedMLXModel: ModelConfiguration = MLXModelManager.shared.selectedModel {
        didSet {
            if useOllama {
                switchModel()
            }
            // Persist selection into manager
            MLXModelManager.shared.selectedModel = selectedMLXModel
        }
    }
    
    // MARK: Chat History Management
    
    /// Array of all saved chat sessions
    @Published var chatHistory: [ChatHistory] = []
    
    /// ID of the currently active chat
    @Published var currentChatId: UUID?
    
    /// Title of the current chat
    @Published var currentChatTitle: String = "New Chat"

    private let evaluator = ToolTriggerEvaluator()

    // MARK: Private Properties

    /// The active AI chat model being used for conversation.
    private var chatModel: AIChatModel
    private var currentStreamTask: Task<Void, Never>?

    private let toolEvaluator = ToolTriggerEvaluator()
    
    /// UserDefaults key for chat history persistence
    private let chatHistoryKey = "SavedChatHistory"
    
    /// MLX Model Manager for handling model downloads and availability
    private let mlxModelManager = MLXModelManager.shared

    // MARK: Initializer

    /// Initializes the view model with a default AI model and sets up the chat session.
    /// Gemini models are initialized in this particular format, changing this will result in errors.
    /// Ollama models are initialized inside their respective ViewModel.
    init() {
        let initialModel = "gemini-1.5-flash-latest"
        self.selectedModel = initialModel
        // Initialize MLX model selection from persisted manager value
        self.selectedMLXModel = MLXModelManager.shared.selectedModel
        self.chatModel = GeminiChatModel(modelName: initialModel)
        loadChatHistory()
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
        currentChatId = UUID()
        currentChatTitle = "New Chat"

//        let systemInstruction = ChatMessage(
//            message: """
//            System: You are a helpful assistant. Only call the function 'fetchCalendarEvents' if the user's request explicitly asks for calendar events (with a date in YYYY-MM-DD format). Otherwise, respond conversationally without invoking any functions.
//            """,
//            participant: .system
//        )
//
//        messages.append(systemInstruction)
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
    
    /// Deletes chats at the specified indices
    func deleteChats(at indexSet: IndexSet) {
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

    /// Stops any ongoing tasks and clears any errors.
    func stop() {
        error = nil
        currentStreamTask?.cancel()
        currentStreamTask = nil
        busy = false
        isProcessingTool = false
        if let lastIndex = messages.indices.last {
            messages[lastIndex].pending = false
        }
    }

    /// Switches the active AI model between Gemini and Ollama.
    ///
    /// When switching, this function updates the chat model instance
    /// and optionally resets the conversation history.
    private func switchModel() {
        if useOllama {
            // Check if selected MLX model is available
            if mlxModelManager.isModelAvailable(selectedMLXModel) {
                chatModel = PetalMLXChatModel(model: selectedMLXModel)
                print("🔵 Now using PetalMLX (local model) with \(selectedMLXModel.name)")
            } else {
                // Model not available, show error or fallback
                error = MLXModelManagerError.modelNotDownloaded(selectedMLXModel.name)
                print("❌ MLX model \(selectedMLXModel.name) is not downloaded")
                
                // Fallback to Gemini temporarily
                useOllama = false
                chatModel = GeminiChatModel(modelName: selectedModel)
                print("🔄 Falling back to Gemini due to unavailable MLX model")
            }
        } else {
            chatModel = GeminiChatModel(modelName: selectedModel)
            print("🟢 Now using Gemini (Google API) with model: \(selectedModel)")
        }
    }
    
    // MARK: MLX Model Management
    
    /// Check if the currently selected MLX model is available
    var isSelectedMLXModelAvailable: Bool {
        mlxModelManager.isModelAvailable(selectedMLXModel)
    }
    
    /// Get the status of the currently selected MLX model
    var selectedMLXModelStatus: MLXModelStatus {
        mlxModelManager.getModelStatus(selectedMLXModel)
    }
    
    /// Download the currently selected MLX model
    func downloadSelectedMLXModel() async {
        await mlxModelManager.downloadModel(selectedMLXModel)
    }
    
    /// Cancel download of the currently selected MLX model
    func cancelMLXModelDownload() {
        mlxModelManager.cancelDownload(selectedMLXModel)
    }
    
    /// Get download progress for the currently selected MLX model
    var mlxModelDownloadProgress: MLXModelDownloadProgress? {
        mlxModelManager.activeDownloads[selectedMLXModel.idString]
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

        messages.append(ChatMessage(message: text, participant: .user))
        // For tool calls, start with an empty message but mark it as pending
        let pendingMessage = ChatMessage.pending(participant: .llm)
        messages.append(pendingMessage)

        do {
            if streaming {
                let stream = chatModel.sendMessageStream(text)
                currentStreamTask = Task { [weak self] in
                    guard let self = self else { return }
                    do {
                        for try await chunk in stream {
                            if Task.isCancelled { break }
                            // If this is a tool call, don't update the message content until we have the final result
                            await MainActor.run {
                                if isProcessingTool {
                                    if !chunk.message.isEmpty {
                                        messages[messages.count - 1].message = chunk.message
                                    }
                                    if let toolName = chunk.toolCallName {
                                        messages[messages.count - 1].toolCallName = toolName
                                    }
                                } else {
                                    if messages[messages.count - 1].pending == true {
                                        messages[messages.count - 1].pending = false
                                    }
                                    messages[messages.count - 1].message += chunk.message
                                }
                            }
                        }
                        // After stream completes, mark as not pending
                        await MainActor.run {
                            messages[messages.count - 1].pending = false
                        }
                    } catch {
                        await MainActor.run {
                            self.error = error
                            messages.removeLast()
                        }
                    }
                    await MainActor.run {
                        self.currentStreamTask = nil
                        busy = false
                        isProcessingTool = false
                        if !messages.isEmpty && currentChatId != nil {
                            saveCurrentChatToHistory()
                        }
                    }
                }
                // Detach handling; the outer async function can return while streaming continues
                await currentStreamTask?.value
            } else {
                let response = try await chatModel.sendMessage(text)
                messages[messages.count - 1].message = response
                messages[messages.count - 1].pending = false
            }
        } catch {
            self.error = error
            messages.removeLast()
            busy = false
            isProcessingTool = false
        }
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
        ExemplarProvider.shared.shouldUseTools(for: text)
    }
}

/// Global notification name for streaming updates
extension Notification.Name {
    static let streamingMessageUpdate = Notification.Name("streamingMessageUpdate")
}

//
// extension ConversationViewModel {
//    // Replace your existing sendMessage method with this one
//    func sendMessage(_ text: String, streaming: Bool = true) async {
//        error = nil
//        busy = true
//
//        let needsTool = messageRequiresTool(text)
//        isProcessingTool = needsTool
//
//        // Add user message
//        await MainActor.run {
//            messages.append(ChatMessage(message: text, participant: .user))
//            let pendingMessage = ChatMessage.pending(participant: .llm)
//            messages.append(pendingMessage)
//        }
//
//        // Store index for response message
//        let responseIndex = messages.count - 1
//
//        do {
//            if streaming {
//                let stream = chatModel.sendMessageStream(text)
//
//                // Process the stream
//                for try await chunk in stream {
//                    print("🧩 Got chunk: '\(chunk.message)'")
//                    await MainActor.run {
//                        if isProcessingTool {
//                            // Tool processing - handle as before
//                            if !chunk.message.isEmpty {
//                                messages[responseIndex].message = chunk.message
//                            }
//
//                            if let toolName = chunk.toolCallName {
//                                messages[responseIndex].toolCallName = toolName
//                            }
//                        } else {
//                            // For regular streaming, we need to force SwiftUI updates
//
//                            // 1. First append the chunk
//                            messages[responseIndex].message += chunk.message
//
//                            // 2. Force a UI update by creating a new messages array
//                            let messagesCopy = self.messages
//                            self.messages = messagesCopy
//
//                            DispatchQueue.main.async {
//                                self.objectWillChange.send()
//                            }
//
//                            self.updateTrigger = UUID()
//
//                            // 3. Post a notification for views to react
//                            NotificationCenter.default.post(
//                                name: .streamingMessageUpdate,
//                                object: nil,
//                                userInfo: [
//                                    "index": responseIndex,
//                                    "message": messages[responseIndex].message
//                                ]
//                            )
//
//                        }
//                    }
//
//                    // Small delay to ensure UI can keep up
//                    // Only needed if chunks are coming very rapidly
//                    if !isProcessingTool {
//                        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
//                    }
//                }
//
//                // After stream completes, mark as not pending
//                await MainActor.run {
//                    messages[responseIndex].pending = false
//
//                    // Force final update
//                    let messagesCopy = self.messages
//                    self.messages = messagesCopy
//                }
//            } else {
//                // Non-streaming implementation
//                let response = try await chatModel.sendMessage(text)
//
//                await MainActor.run {
//                    messages[responseIndex].message = response
//                    messages[responseIndex].pending = false
//                }
//            }
//        } catch {
//            await MainActor.run {
//                self.error = error
//                messages.removeLast()
//            }
//        }
//
//        await MainActor.run {
//            busy = false
//            isProcessingTool = false
//        }
//    }
// }
