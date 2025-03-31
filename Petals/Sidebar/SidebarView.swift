//
//  SidebarView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/12/25.
//

import Foundation
import SwiftUI

struct SidebarView: View {

    /// The search query for the search bar.
    @State private var searchQuery: String = ""

    /// The binding to the selected sidebar item.
    @Binding var selectedItem: SidebarItem?

    @Binding var chatHistory: [ChatHistory]

    // FIXME: Temp
    @ObservedObject var conversationalVM: ConversationViewModel

    var body: some View {
        VStack {
            TextField("Search", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding()

            List(selection: $selectedItem) {
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
            .listStyle(.sidebar)

            // A "new chat" button at bottom
            Button {
                // Start a brand new chat
                conversationalVM.startNewChat()
                let newSession = ChatHistory(title: "Chat #\(chatHistory.count + 1)")
                chatHistory.append(newSession)
                selectedItem = .chat(id: newSession.id)
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("New Chat")
                }
            }
            #if os(macOS)
            // Use LinkButtonStyle only on macOS
            .buttonStyle(LinkButtonStyle())
            #else
            // On iOS (and other platforms), use the default style
            // or choose another iOS-appropriate style like .bordered
            .buttonStyle(.bordered) // Example: uncomment if you want bordered
            #endif
            // --- End Conditional Style ---
            .padding()
        }
        .listStyle(.sidebar)
    }
}
