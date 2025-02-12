//
//  PetalsApp.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import SwiftUI

@main
struct PetalsApp: App {

    /// The user’s selection in the sidebar
    @State private var selectedSidebarItem: SidebarItem? = .home

    /// FIXME:
    /// Temp, eval in future
    @StateObject private var conversationVM = ConversationViewModel()

    /// For demonstration, keep track of an array of saved chats for the sidebar
    @State private var chatHistory: [ChatHistory] = []

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                SidebarView(
                    selectedItem: $selectedSidebarItem,
                    chatHistory: $chatHistory,
                    conversationalVM: conversationVM
                )
            } detail: {
                switch selectedSidebarItem {
                case .home:
                    HomeView {
                        // On that "Start Chat" click, start new chat + switch to LLM Chat
                        conversationVM.startNewChat()
                        let newSession = ChatHistory(title: "Chat #\(chatHistory.count + 1)")
                        chatHistory.append(newSession)
                        selectedSidebarItem = .chat(id: newSession.id)
                    }
                case let .chat(id):
                    // Find the matching ChatHistory item if we want to display a unique name, etc.
                    // For simplicity, we just show LLMChatView
                    GeminiChatView(conversationVM: conversationVM)
                case .none:
                    Text("Select a tab from the sidebar.")
                        .font(.title)
                }
            }
        }
    }
}
