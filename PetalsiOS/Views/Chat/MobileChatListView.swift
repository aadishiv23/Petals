//
//  MobileChatListView.swift
//  PetalsiOS
//
//  Created for iOS target
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