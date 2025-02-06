//
//  ChatMessage.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import Foundation

/// A simple model for a single chat message
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()

    var message: String
    var participant: Participant
    var pending: Bool = false

    enum Participant {
        case user
        case system
    }

    /// Utility to create a "pending" message
    static func pending(participant: Participant) -> ChatMessage {
        return ChatMessage(message: "", participant: participant, pending: true)
    }
}
