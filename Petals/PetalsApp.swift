//
//  PetalsApp.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import SwiftUI

@main
struct PetalsApp: App {

    // We can hold our ConversationViewModel at the top level,
    // or you can store it in an environment object
    @StateObject private var conversationVM = ConversationViewModel()

    // For demonstration, keep track of an array of saved chats for the sidebar
    @State private var chatHistory: [ChatHistory] = []

    // The user’s selection in the sidebar
    @State private var selectedSidebarItem: SidebarItem? = .home

    var body: some Scene {
        WindowGroup {
            // On macOS 13+ we can use NavigationSplitView
            NavigationSplitView {
                SidebarView(
                    selectedItem: $selectedSidebarItem,
                    chatHistory: $chatHistory,
                    conversationVM: conversationVM
                )
            } detail: {
                // Show either HomeView or LLMChatView, depending on the sidebar selection
                switch selectedSidebarItem {
                case .home:
                    HomeView {
                        // On that "Start Chat" click, start new chat + switch to LLM Chat
                        conversationVM.startNewChat()
                        let newSession = ChatHistory(title: "Chat #\(chatHistory.count + 1)")
                        chatHistory.append(newSession)
                        selectedSidebarItem = .chat(id: newSession.id)
                    }

                case .chat(let id):
                    // Find the matching ChatHistory item if we want to display a unique name, etc.
                    // For simplicity, we just show LLMChatView
                    LLMChatView(conversationVM: conversationVM)

                case .none:
                    Text("Select an item from the sidebar.")
                        .font(.title)
                }
            }
            .frame(minWidth: 900, minHeight: 600)
        }
    }
}

// We define an enum for what the user selected in the sidebar
enum SidebarItem: Hashable {
    case home
    case chat(id: UUID)
}
