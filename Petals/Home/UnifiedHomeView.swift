//
//  UnifiedHomeView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import SwiftUI

struct UnifiedHomeView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    @State private var searchQuery = ""
    @State private var selectedCategory: AgentCategory = .all
    @State private var showingChat = false
    @State private var chatToShow: UUID?
    @State private var showingSettings = false
    @State private var isQuickActionsCollapsed = false
    
    var body: some View {
        VStack(spacing: 0) {
            categoryLinksView
            mainContentScrollView
        }
        .background(backgroundColor)
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
                GeminiChatView(conversationVM: conversationVM)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(conversationVM: conversationVM)
        }
        .frame(
            minWidth: 800,
            idealWidth: 1000,
            maxWidth: .infinity,
            minHeight: 600,
            idealHeight: 700,
            maxHeight: .infinity
        )
        .onChange(of: searchQuery) { _ in
            // Collapse quick actions when searching
            isQuickActionsCollapsed = !searchQuery.isEmpty
        }
    }
    
    /// Platform-agnostic background color
    private var backgroundColor: Color {
        #if os(macOS)
        return Color(.windowBackgroundColor)
        #else
        return Color(.systemGroupedBackground)
        #endif
    }
    

    
    /// Category links section (placeholders for future views)
    private var categoryLinksView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AgentCategory.allCases) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }
    
    /// Main content area
    private var mainContentScrollView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if conversationVM.chatHistory.isEmpty {
                    emptyStateView
                } else {
                    chatHistorySection
                }
                
                if !isQuickActionsCollapsed {
                    quickActionsSection
                }
            }
            .padding(24)
        }
    }
    
    /// Empty state when no chats exist
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Welcome to Petals")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start your first conversation with AI")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button(action: startNewChat) {
                HStack {
                    Image(systemName: "plus.bubble")
                    Text("Start First Chat")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(plainOrBorderlessButtonStyle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    /// Chat history section
    private var chatHistorySection: some View {
        SectionView(title: "Recent Conversations", icon: "clock") {
            LazyVStack(spacing: 12) {
                ForEach(filteredChatHistory) { chat in
                    ChatHistoryCard(
                        chat: chat,
                        onTap: { navigateToChat(chat.id) },
                        onDelete: { conversationVM.deleteChat(chat.id) }
                    )
                }
            }
        }
    }
    
    /// Quick actions section
    private var quickActionsSection: some View {
        SectionView(title: "Quick Actions", icon: "bolt") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                ActionButton(
                    icon: "plus.bubble", text: "New Chat", color: .blue,
                    description: "Start a fresh conversation",
                    action: startNewChat
                )
                ActionButton(
                    icon: "brain", text: "AI Assistant", color: .purple,
                    description: "Get help with complex tasks",
                    action: startNewChat
                )
                ActionButton(
                    icon: "doc.text.magnifyingglass", text: "Research", color: .indigo,
                    description: "Find information on any topic",
                    action: startNewChat
                )
                ActionButton(
                    icon: "lightbulb", text: "Creative Help", color: .orange,
                    description: "Brainstorming and ideas",
                    action: startNewChat
                )
            }
        }
    }
    
    /// Filtered chat history based on search
    private var filteredChatHistory: [ChatHistory] {
        if searchQuery.isEmpty {
            return Array(conversationVM.chatHistory.prefix(10))
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
    
    // Platform-agnostic styles
    private var plainOrBorderlessButtonStyle: some PrimitiveButtonStyle {
        #if os(macOS)
        return PlainButtonStyle()
        #else
        return BorderlessButtonStyle()
        #endif
    }
    

    
    /// Categories for different sections
    enum AgentCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case recent = "Recent"
        case favorites = "Favorites"
        case archived = "Archived"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .recent: return "clock"
            case .favorites: return "heart"
            case .archived: return "archivebox"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .recent: return .green
            case .favorites: return .pink
            case .archived: return .gray
            }
        }
    }
}

// MARK: - Supporting Views

/// Chat history card component
struct ChatHistoryCard: View {
    let chat: ChatHistory
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Chat icon
                Image(systemName: "message")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                // Chat info
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let lastMessage = chat.lastMessage {
                        Text(lastMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    if let lastActivity = chat.lastActivityDate {
                        Text(formatDate(lastActivity))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 8) {
                    Menu {
                        Button("Delete", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onTapGesture { } // Prevent propagation to card button
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Delete Chat", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Are you sure you want to delete this chat? This action cannot be undone.")
        }
    }
    
    private var cardBackground: some View {
        #if os(macOS)
        return RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        #else
        return RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        #endif
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// Enhanced action button with tap functionality
struct ActionButton: View {
    let icon: String
    let text: String
    let color: Color
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(color)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Spacer()
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(color.opacity(0.7))
                }
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(height: 30, alignment: .top)
            }
            .padding(16)
            .frame(minHeight: 140, alignment: .top)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        #if os(macOS)
        return RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        #else
        return RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        #endif
    }
}

#Preview {
    UnifiedHomeView(conversationVM: ConversationViewModel())
}
