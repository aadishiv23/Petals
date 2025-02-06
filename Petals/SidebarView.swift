//
//  SidebarView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import SwiftUI

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?
    @Binding var chatHistory: [ChatHistory]
    @ObservedObject var conversationVM: ConversationViewModel

    // For demonstration, a search query in the sidebar
    @State private var searchQuery: String = ""

    var body: some View {
        VStack {
            // A simple search field
            TextField("Search...", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            List(selection: $selectedItem) {
                // Home
                Label("Home", systemImage: "house")
                    .tag(SidebarItem.home)

                // LLM Chat (just a placeholder if you want to jump right in)
                Label("LLM Chat", systemImage: "ellipsis.bubble")
                    .tag(SidebarItem.chat(id: UUID())) // ephemeral ID if you want direct switch

                Divider()

                // Display the actual chat sessions in the sidebar
                Section("Chats") {
                    ForEach(chatHistory) { chat in
                        Text(chat.title)
                            .tag(SidebarItem.chat(id: chat.id))
                    }
                }
            }

            Divider()

            // A "new chat" button at bottom
            Button {
                // Start a brand new chat
                conversationVM.startNewChat()
                let newSession = ChatHistory(title: "Chat #\(chatHistory.count + 1)")
                chatHistory.append(newSession)
                selectedItem = .chat(id: newSession.id)
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("New Chat")
                }
            }
            .buttonStyle(LinkButtonStyle())
            .padding()
        }
        .listStyle(SidebarListStyle()) // On macOS, you might prefer .sidebar style
    }
}
