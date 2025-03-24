//
//  Conversation.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/24/25.
//

import Foundation

struct Conversation: Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
    var createdAt: Date
    var messages: [ChatMessage] = []
}

extension Conversation {
    init(from cdConversation: CDConversation) {
        guard
            let id = cdConversation.id,
            let createdAt = cdConversation.createdAt
        else {
            fatalError("❌ CDConversation is missing required fields")
        }

        self.id = id
        self.title = cdConversation.title ?? "Untitled"
        self.createdAt = createdAt

        if let cdMessages = cdConversation.cdMessages as? Set<CDChatMessage> {
            self.messages = cdMessages
                .compactMap { $0.date != nil ? $0 : nil } // ensure date is not nil
                .sorted(by: { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) })
                .map { ChatMessage(from: $0) }
        } else {
            self.messages = []
        }
    }
}

extension Conversation {
    /// Returns a conversation context string with all past messages, labeled by sender.
    /// If a current message is provided, it is appended with a "Current message:" header.
    func fullContext(withCurrentMessage currentMessage: ChatMessage? = nil) -> String {
        // Sort messages by date (oldest first)
        let sortedMessages = messages.sorted { $0.date < $1.date }

        // Build each line with a sender prefix.
        let contextLines = sortedMessages.map { message -> String in
            let sender = switch message.participant {
            case .user: "User"
            case .llm: "LLM"
            case .system: "System"
            }
            return "\(sender): \(message.message)"
        }

        var fullContext = contextLines.joined(separator: "\n")

        // Append the current message if provided.
        if let current = currentMessage {
            fullContext += "\nCurrent message: \(current.message)"
        }

        return fullContext
    }
}
