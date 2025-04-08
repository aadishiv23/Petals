//
//  MobileHomeView.swift
//  PetalsiOS
//
//  Created for iOS target
//

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

    /// Home content
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

    /// Settings content
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

    /// Action card component
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

    /// Empty chats view
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

    /// Recent chats list
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

    /// Helper functions
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