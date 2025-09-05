//
//  MobileUnifiedHomeView.swift
//  PetalsiOS
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import SwiftUI
import PetalCore
import PetalMLX

struct MobileUnifiedHomeView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    @State private var searchQuery = ""
    @State private var showingChat = false
    @State private var chatToShow: UUID?
    @State private var showingSettings = false
    @State private var isQuickActionsCollapsed = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quick Actions (collapsible)
                if !isQuickActionsCollapsed {
                    quickActionsSection
                }
                
                // Chat History
                if conversationVM.chatHistory.isEmpty {
                    emptyStateView
                } else {
                    chatHistorySection
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Petals")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchQuery, prompt: "Search conversations...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .font(.system(size: 18))
                    }
                    
                    Button(action: startNewChat) {
                        Image(systemName: "plus")
                            .font(.system(size: 18))
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showingChat) {
            if chatToShow != nil {
                MobileGeminiChatView(conversationVM: conversationVM)
            }
        }
        .sheet(isPresented: $showingSettings) {
            MobileSettingsView(conversationVM: conversationVM)
        }
        .onChange(of: searchQuery) { _ in
            // Collapse quick actions when searching
            isQuickActionsCollapsed = !searchQuery.isEmpty
        }
    }
    

    

    
    /// Quick actions section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MobileActionCard(
                    icon: "plus.bubble",
                    title: "New Chat",
                    description: "Start fresh conversation",
                    color: Color(hex: "5E5CE6"),
                    action: startNewChat
                )
                
                MobileActionCard(
                    icon: "brain",
                    title: "AI Assistant",
                    description: "Get help with tasks",
                    color: .purple,
                    action: startNewChat
                )
                
                MobileActionCard(
                    icon: "doc.text.magnifyingglass",
                    title: "Research",
                    description: "Find information",
                    color: .indigo,
                    action: startNewChat
                )
                
                MobileActionCard(
                    icon: "lightbulb",
                    title: "Creative Help",
                    description: "Ideas & brainstorming",
                    color: .orange,
                    action: startNewChat
                )
            }
        }
    }
    
    /// Empty state when no chats exist
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Welcome to Petals")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start your first conversation with AI")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: startNewChat) {
                HStack {
                    Image(systemName: "plus.bubble")
                    Text("Start First Chat")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "5E5CE6"))
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    /// Chat history section
    private var chatHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Conversations")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                if conversationVM.chatHistory.count > 5 {
                    NavigationLink(destination: MobileChatListView(
                        chatHistory: conversationVM.chatHistory,
                        conversationVM: conversationVM,
                        onSelectChat: { id in
                            chatToShow = id
                            showingChat = true
                        },
                        onNewChat: startNewChat,
                        onDelete: conversationVM.deleteChats
                    )) {
                        Text("View All")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "5E5CE6"))
                    }
                }
            }
            
            LazyVStack(spacing: 12) {
                ForEach(filteredChatHistory.prefix(5), id: \.id) { chat in
                    MobileChatHistoryCard(
                        chat: chat,
                        onTap: { navigateToChat(chat.id) },
                        onDelete: { conversationVM.deleteChat(chat.id) }
                    )
                }
            }
        }
    }
    
    /// Filtered chat history based on search
    private var filteredChatHistory: [ChatHistory] {
        if searchQuery.isEmpty {
            return conversationVM.chatHistory
        } else {
            return conversationVM.chatHistory.filter { chat in
                chat.title.localizedCaseInsensitiveContains(searchQuery) ||
                chat.lastMessage?.localizedCaseInsensitiveContains(searchQuery) == true
            }
        }
    }
    
    /// Actions
    private func startNewChat() {
        let newChatId = conversationVM.createNewChat()
        chatToShow = newChatId
        showingChat = true
    }
    
    private func navigateToChat(_ chatId: UUID) {
        // Immediate state update for faster response
        chatToShow = chatId
        showingChat = true
        
        // Ensure the chat loads immediately
        Task { @MainActor in
            conversationVM.loadChat(chatId)
        }
    }
}

// MARK: - Supporting Views

/// Mobile action card component
struct MobileActionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(color)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .frame(height: 100, alignment: .top)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Mobile chat history card
struct MobileChatHistoryCard: View {
    let chat: ChatHistory
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Chat icon
                Image(systemName: "message")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "5E5CE6"))
                    .frame(width: 32, height: 32)
                    .background(Color(hex: "5E5CE6").opacity(0.1))
                    .clipShape(Circle())
                
                // Chat info
                VStack(alignment: .leading, spacing: 2) {
                    Text(chat.title)
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    if let lastMessage = chat.lastMessage {
                        Text(lastMessage)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let lastActivity = chat.lastActivityDate {
                        Text(formatDate(lastActivity))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete Chat", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Are you sure you want to delete this chat?")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// Mobile settings view
struct MobileSettingsView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle(isOn: $conversationVM.useMLX) {
                        HStack {
                            Image(systemName: conversationVM.useMLX ? "desktopcomputer" : "cloud")
                                .foregroundColor(Color(hex: "5E5CE6"))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(conversationVM.useMLX ? "MLX (Local)" : "Gemini API (Cloud)")
                                
                                if conversationVM.useMLX {
                                    Text(conversationVM.selectedMLXModel.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "5E5CE6")))
                    
                    if conversationVM.useMLX {
                        NavigationLink("MLX Model Settings") {
                            MLXModelSettingsView()
                        }
                        .foregroundColor(Color(hex: "5E5CE6"))
                    }
                } header: {
                    Text("AI Model")
                }

                // Telemetry section
                Section {
                    Toggle("Enable Telemetry", isOn: Binding(
                        get: { TelemetrySettings.shared.telemetryEnabled },
                        set: { TelemetrySettings.shared.telemetryEnabled = $0 }
                    ))
                    Toggle("Verbose Logging", isOn: Binding(
                        get: { TelemetrySettings.shared.verboseLoggingEnabled },
                        set: { TelemetrySettings.shared.verboseLoggingEnabled = $0 }
                    ))

                    NavigationLink("View Telemetry Sessions") {
                        TelemetrySessionsMobileView()
                    }
                } header: {
                    Text("Telemetry")
                } footer: {
                    Text("Collects per-chat metrics like latencies, token speeds, and tool timings. Stored locally.")
                }
                
                Section {
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
                } header: {
                    Text("About")
                }
                
                Section {
                    Button("Clear All Chat History") {
                        conversationVM.clearAllChatHistory()
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Data")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MobileUnifiedHomeView(conversationVM: ConversationViewModel())
}
