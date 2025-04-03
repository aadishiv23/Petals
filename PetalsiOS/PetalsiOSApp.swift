//
//  PetalsiOSApp.swift
//  PetalsiOS
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import SwiftUI

@main
struct PetalsiOSApp: App {

    @StateObject private var conversationVM = ConversationViewModel()

    var body: some Scene {
        WindowGroup {
            MobileHomeView(
                conversationVM: conversationVM
            )
        }
    }
}

//  MobileHomeView.swift
//  Petals
//
//  Created for iOS target

import PetalCore
import SwiftUI

//  MobileHomeView.swift
//  Petals
//
//  Created for iOS target

import PetalCore
import SwiftUI

struct MobileHomeView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home tab
            homeContent
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Chat tab
            MobileGeminiChatView(conversationVM: conversationVM)
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(1)
            
            // Settings tab
            settingsContent
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .accentColor(Color(hex: "5E5CE6"))
    }
    
    // Home content
    var homeContent: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 2) {
                Text("Petals")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "5E5CE6"))
                
                Text("Your AI assistant")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 48)
            
            Spacer(minLength: 20)
            
            // Quick action cards
            VStack(spacing: 16) {
                Text("Quick Actions")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        actionCard(title: "New Chat", icon: "plus.bubble", action: newChat)
                        actionCard(title: "Last Chat", icon: "arrow.uturn.left", action: lastChat)
                        actionCard(title: "Help", icon: "questionmark.circle", action: help)
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer(minLength: 20)
            
            // Recent chats section
            VStack(spacing: 16) {
                Text("Recent Chats")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                if conversationVM.chatHistory.isEmpty {
                    emptyChatsView
                } else {
                    recentChatsListView
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // Settings content
    var settingsContent: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Form {
                Section(header: Text("Model Selection")) {
                    Toggle(isOn: $conversationVM.useOllama) {
                        HStack {
                            Image(systemName: conversationVM.useOllama ? "desktopcomputer" : "cloud")
                            Text(conversationVM.useOllama ? "MLX (Local)" : "Gemini API (Cloud)")
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "5E5CE6")))
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Aadi Shiv Malhotra")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // Action card component
    private func actionCard(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "5E5CE6"))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(width: 100, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
    
    // Empty chats view
    private var emptyChatsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No recent chats")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Button(action: newChat) {
                Text("Start a new chat")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "5E5CE6"))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    // Recent chats list
    private var recentChatsListView: some View {
        VStack(spacing: 12) {
            ForEach(conversationVM.chatHistory.prefix(3)) { chat in
                Button {
                    // Select this chat and switch to chat tab
                    conversationVM.selectChat(chat.id)
                    selectedTab = 1
                } label: {
                    HStack {
                        Image(systemName: "message")
                            .foregroundColor(Color(hex: "5E5CE6"))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chat.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            if let lastMessage = chat.lastMessage {
                                Text(lastMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        if let lastActivity = chat.lastActivityDate {
                            Text(formatDate(lastActivity))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if conversationVM.chatHistory.count > 3 {
                NavigationLink(destination: MobileChatListView(
                    chatHistory: conversationVM.chatHistory,
                    conversationVM: conversationVM,
                    onSelectChat: { id in
                        conversationVM.selectChat(id)
                        selectedTab = 1
                    },
                    onNewChat: newChat,
                    onDelete: conversationVM.deleteChats
                )) {
                    Text("View all chats")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "5E5CE6"))
                        .padding(.top, 8)
                }
            }
        }
    }
    
    // Helper functions
    private func newChat() {
        conversationVM.startNewChat()
        selectedTab = 1
    }
    
    private func lastChat() {
        if let firstChat = conversationVM.chatHistory.first {
            conversationVM.selectChat(firstChat.id)
            selectedTab = 1
        } else {
            newChat()
        }
    }
    
    private func help() {
        // Implement help functionality
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

//  MobileHomeContent.swift
//  Petals
//
//  Created for iOS target

import SwiftUI

struct MobileHomeContent: View {
    var newChatAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "5E5CE6"))

            Text("Petals")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            Text("Your personal AI assistant powered by Gemini and MLX")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()

            Button(action: newChatAction) {
                HStack {
                    Image(systemName: "plus")
                    Text("New Chat")
                }
                .frame(minWidth: 200, minHeight: 44)
                .background(Color(hex: "5E5CE6"))
                .foregroundColor(.white)
                .cornerRadius(22)
                .padding()
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .padding()
    }
}

//
//  ChatHistory.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation



//  MobileChatListView.swift
//  Petals
//
//  Created for iOS target

import PetalCore
import SwiftUI

//
//  MobileChatListView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 4/1/25.
//

import Foundation
import PetalCore
import SwiftUI

struct MobileChatListView: View {
    // Using a regular array reference
    let chatHistory: [ChatHistory]
    @ObservedObject var conversationVM: ConversationViewModel
    let onSelectChat: (UUID) -> Void
    let onNewChat: () -> Void
    let onDelete: (IndexSet) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(chatHistory) { chat in
                    Button {
                        onSelectChat(chat.id)
                    } label: {
                        HStack {
                            Image(systemName: "message")
                                .foregroundColor(Color(hex: "5E5CE6"))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(chat.title)
                                    .font(.headline)

                                if let lastMessage = chat.lastMessage {
                                    Text(lastMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            if let lastActivity = chat.lastActivityDate {
                                Text(formatDate(lastActivity))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onDelete(perform: onDelete)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onNewChat) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

//  MobileGeminiChatView.swift
//  Petals
//
//  Created for iOS target

import PetalCore
import SwiftUI

//  MobileGeminiChatView.swift
//  Petals
//
//  Created for iOS target

import SwiftUI
import PetalCore

struct MobileGeminiChatView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    @State private var userInput: String = ""
    @FocusState private var inputIsFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(conversationVM.currentChatTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                
                Spacer()
                
                MobileModelToggle(isOn: $conversationVM.useOllama)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))
            .shadow(color: Color.black.opacity(0.1), radius: 1, y: 1)
            
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(conversationVM.messages, id: \.self) { msg in
                            if msg.pending, conversationVM.isProcessingTool {
                                withAnimation {
                                    toolLoadingView(for: msg)
                                }
                            } else {
                                withAnimation {
                                    MobileChatBubbleView(message: msg)
                                        .id(msg)
                                }
                            }
                        }
                        
                        // Invisible spacer for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottomScrollAnchor")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
                // Scroll when message count changes
                .onChange(of: conversationVM.messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                // Also scroll when the content of the last message changes (for streaming)
                .onChange(of: conversationVM.messages.last?.message) { _ in
                    scrollToBottom(proxy: proxy)
                }
                // Initial scroll when view appears
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // Input bar
            MobileChatInputBar(userInput: $userInput, isFocused: _inputIsFocused) { message in
                Task {
                    await conversationVM.sendMessage(message, streaming: true)
                }
            }
        }
    }
    
    private func toolLoadingView(for msg: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            MobileAvatar(participant: .llm)
                .offset(y: 2)
            MobileToolProcessingView()
                .id(msg)
            Spacer()
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.smooth(duration: 0.3)) {
            proxy.scrollTo("bottomScrollAnchor", anchor: .bottom)
        }
    }
}


/// Mobile-friendly toggle for model selection
struct MobileModelToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "desktopcomputer" : "cloud")
                    .font(.system(size: 12))
                Text(isOn ? "MLX" : "Gemini API")
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "5E5CE6")))
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

//  MobileChatInputBar.swift
//  Petals
//
//  Created for iOS target

import SwiftUI

struct MobileChatInputBar: View {
    @Binding var userInput: String
    @FocusState var isFocused: Bool
    var onSend: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom) {
                // Text input field
                TextField("Message", text: $userInput, axis: .vertical)
                    .padding(10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(20)
                    .focused($isFocused)
                    .lineLimit(5)

                // Send button
                Button(action: {
                    if !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend(userInput)
                        userInput = ""
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(
                            userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.gray
                            : Color(hex: "5E5CE6")
                        )
                }
                .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
        }
    }
}

//  MobileChatBubbleView.swift
//  Petals
//
//  Created for iOS target

import PetalCore
import SwiftUI

struct MobileChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            // Avatar
            if message.participant == .llm {
                MobileAvatar(participant: .llm)
                    .padding(.top, 4)
            }

            // Message bubble
            VStack(alignment: message.participant == .user ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.message)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.participant == .user
                        ? Color(hex: "5E5CE6")
                            : Color(UIColor.secondarySystemBackground)
                    )
                    .foregroundColor(
                        message.participant == .user
                            ? .white
                            : Color.primary
                    )
                    .cornerRadius(16)
            }
            .frame(
                maxWidth: UIScreen.main.bounds.width * 0.75,
                alignment: message.participant == .user ? .trailing : .leading
            )

            // User avatar (at the end for user messages)
            if message.participant == .user {
                MobileAvatar(participant: .user)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.participant == .user ? .trailing : .leading)
    }
}

/// Mobile avatar view
struct MobileAvatar: View {
    let participant: ChatMessage.Participant

    var body: some View {
        Image(systemName: participant == .user ? "person.circle.fill" : "brain.head.profile")
            .font(.system(size: 24))
            .foregroundColor(participant == .user ? Color.blue : Color(hex: "5E5CE6"))
    }
}

/// Tool processing view for mobile
struct MobileToolProcessingView: View {
    @State private var typingDots = 1

    var body: some View {
        Text(String(repeating: ".", count: typingDots))
            .font(.system(size: 24, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(Color.secondary)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) {
                    typingDots = (typingDots % 3) + 1
                }
            }
    }
}

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

    // MARK: Private Properties

    /// The active AI chat model being used for conversation.
    private var chatModel: AIChatModel

    private let toolEvaluator = ToolTriggerEvaluator()

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
            let modelConfig = ModelConfiguration.defaultModel
            chatModel = PetalMLXChatModel(model: modelConfig)
            print("🔵 Now using PetalML (local model) with \(modelConfig.name)")
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

        messages.append(ChatMessage(message: text, participant: .user))
        messages.append(ChatMessage.pending(participant: .system))

        do {
            if streaming {
                let stream = chatModel.sendMessageStream(text)
                for try await chunk in stream {
                    messages[messages.count - 1].message += chunk.message
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
    
    // Add these properties to ConversationViewModel
    @Published var chatHistory: [ChatHistory] = []
    @Published var currentChatTitle: String = "New Chat"

    // Add these methods to ConversationViewModel
    func selectChat(_ id: UUID) {
        guard let index = chatHistory.firstIndex(where: { $0.id == id }) else { return }
        // Load this chat
        // Implementation details depend on how you store chat content
        currentChatTitle = chatHistory[index].title
    }

    func deleteChats(_ indexSet: IndexSet) {
        chatHistory.remove(atOffsets: indexSet)
    }
}

//
//  ToolTriggerEvaluator.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/17/25.
//

import Foundation
import NaturalLanguage

/// Eveluates whether a tool should be triggered based on semantic similarity.
struct ToolTriggerEvaluator {
    let embedding: NLEmbedding

    init() {
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
            fatalError("English Embedding not availalble")
        }
        self.embedding = embedding
    }

    /// Returns a vector for the given text. First, attempts to retrieve the vector directly.
    /// If that fails, splits the text into words and averages their vectors.
    func vector(for text: String) -> [Double]? {
        // Try the full string first.
        if let fullVector = embedding.vector(for: text.lowercased()) {
            return fullVector
        }

        // Fallback: Tokenize and average the vectors for individual words.
        let tokens = text.lowercased().split(separator: " ").map { String($0) }
        var sumVector: [Double] = []
        var validCount = 0

        for token in tokens {
            if let tokenVector = embedding.vector(for: token) {
                if sumVector.isEmpty {
                    sumVector = tokenVector
                } else {
                    for i in 0..<min(sumVector.count, tokenVector.count) {
                        sumVector[i] += tokenVector[i]
                    }
                }
                validCount += 1
            }
        }

        guard validCount > 0 else {
            return nil
        }
        return sumVector.map { $0 / Double(validCount) }
    }

    /// Computes the centroid (prototype) vector for a set of exemplar phrases.
    /// - Parameter exemplars: An array of exemplar trigger phrases for a tool.
    /// - Returns: A vector representing the averaged (centroid) embedding, or nil if none could be computed.
    func prototype(for exemplars: [String]) -> [Double]? {
        var sum: [Double] = []
        var count = 0

        for exemplar in exemplars {
            if let vector = vector(for: exemplar) {
                if sum.isEmpty {
                    sum = vector
                } else {
                    for i in 0..<min(sum.count, vector.count) {
                        sum[i] += vector[i]
                    }
                }
                count += 1
            }
        }
        guard count > 0 else {
            return nil
        }
        return sum.map { $0 / Double(count) }
    }

    /// Computes the cosine similarity between two vectors.
    func cosineSimilarity(_ vectorA: [Double], _ vectorB: [Double]) -> Double {
        let dotProduct = zip(vectorA, vectorB).reduce(0.0) { $0 + $1.0 * $1.1 }
        let magnitudeA = sqrt(vectorA.reduce(0.0) { $0 + $1 * $1 })
        let magnitudeB = sqrt(vectorB.reduce(0.0) { $0 + $1 * $1 })
        guard magnitudeA != 0, magnitudeB != 0 else {
            return 0
        }
        return dotProduct / (magnitudeA * magnitudeB)
    }

    /// Determines whether the given message should trigger a tool by comparing it to the provided prototype.
    /// - Parameters:
    ///   - message: The incoming user message.
    ///   - exemplarPrototype: The prototype embedding computed from exemplar phrases.
    ///   - threshold: The similarity threshold (0 to 1) for a match.
    /// - Returns: True if the message's similarity to the prototype is at least the threshold.
    func shouldTriggerTool(for message: String, exemplarPrototype: [Double], threshold: Double = 0.75) -> Bool {
        guard let messageVector = vector(for: message) else {
            return false
        }
        let similarity = cosineSimilarity(messageVector, exemplarPrototype)
        return similarity >= threshold
    }

//
//    /// Checks if any keywords in `toolKeywords` is semantically close to the message.
//    /// - Parameters:
//    ///     - `message`: The user's message to the LLM.
//    ///     - `toolKeywords`:  An array of keywords that are trigger words for our given tool.
//    ///     - `threshold`:  A similarity threshold from 0 to 1, where 1 is a perfect match.
//    /// - Returns:
//    ///     - True if tool should be trigger, false if not.
//    func shouldTriggerTool(for message: String, toolKeywords: [String], threshold: Float = 0.6) -> Bool {
//        // Normalize and sanitize the message
//        let lowercasedMessage = message.lowercased()
//
//        for keyword in toolKeywords {
//            if let distance = embedding.distance(between: lowercasedMessage, and: keyword.lowercased()) {
//                if distance < (1.0 - threshold) {
//                    return true
//                }
//            }
//        }
//
//        return false
//    }
}

//
//  GeminiChatModel.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/15/25.
//

import Foundation
import GoogleGenerativeAI
import PetalTools
import PetalCore

class GeminiChatModel: AIChatModel {
    private var model: GenerativeModel
    private var chat: Chat

    init(modelName: String) {
        self.model = GenerativeModel(name: modelName, apiKey: APIKey.default)
        self.chat = model.startChat()
    }

    func sendMessageStream(_ text: String) -> AsyncThrowingStream<PetalMessageStreamChunk, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await response in chat.sendMessageStream(text) {
                        if let textChunk = response.text {
                            continuation.yield(PetalMessageStreamChunk(message: textChunk, toolCallName: nil))
                        }
                    }
                    continuation.finish()
                } catch {
                    print("Gemini streaming error: \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }


    func sendMessage(_ text: String) async throws -> String {
        let response = try await chat.sendMessage(text)
        return response.text ?? ""
    }
}

extension Color {
    /// Initializes a Color using a hexadecimal string.
    /// - Parameter hex: A hex string representing the color (e.g., "5E5CE6").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum APIKey {
  /// Fetch the API key from `GenerativeAI-Info.plist`
  /// This is just *one* way how you can retrieve the API key for your app.
  static var `default`: String {
    guard let filePath = Bundle.main.path(forResource: "Petals-GenerativeAI-Info", ofType: "plist")
    else {
      fatalError("Couldn't find file 'Petals-GenerativeAI-Info.plist'.")
    }
    let plist = NSDictionary(contentsOfFile: filePath)
    guard let value = plist?.object(forKey: "API_KEY") as? String else {
      fatalError("Couldn't find key 'API_KEY' in 'GenerativeAI-Info.plist'.")
    }
    if value.starts(with: "_") || value.isEmpty {
      fatalError(
        "Follow the instructions at https://ai.google.dev/tutorials/setup to get an API key."
      )
    }
    return value
  }
}
