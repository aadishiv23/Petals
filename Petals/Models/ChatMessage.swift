//
//  ChatMessage.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/12/25.
//

import Foundation

struct ChatMessage: Identifiable, Equatable, Hashable {
    let id = UUID()
    let date = Date()

    var message: String
    var pending: Bool = false
    var participant: Participant
    var toolCallName: String? = nil

    enum Participant {
        case user
        case system
        case llm
    }

    /// Utility to create a pending messsage.
    static func pending(participant: Participant) -> ChatMessage {
        ChatMessage(message: "", pending: true, participant: participant)
    }
}

extension ChatMessage {
    init(from cdMessage: CDChatMessage) {
        // Safely unwrap required values
        guard
            let id = cdMessage.id,
            let message = cdMessage.message,
            let date = cdMessage.date
        else {
            // If data is corrupted, use fallback or crash (your call)
            fatalError("CDChatMessage is missing required fields")
        }

        self.message = message
        self.pending = cdMessage.pending
        self.toolCallName = nil // Core Data model doesn’t store this (yet)

        // Convert participant string → enum
        switch cdMessage.participant {
        case "user": self.participant = .user
        case "llm": self.participant = .llm
        case "system": self.participant = .system
        default: self.participant = .llm // Fallback if invalid
        }
    }
}
