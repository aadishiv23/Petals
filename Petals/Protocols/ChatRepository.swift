//
//  ChatRepository.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/24/25.
//

import Foundation

protocol ChatRepository {
    // Conversations
    func createConversation(title: String) -> Conversation
    func fetchAllConversations() -> [Conversation]
    func deleteConversation(_ conversation: Conversation)

    // Messages
    func addMessage(_ message: ChatMessage, to conversation: Conversation)
    func fetchMessages(for conversation: Conversation) -> [ChatMessage]
}
