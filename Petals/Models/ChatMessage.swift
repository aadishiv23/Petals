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
    
    enum Participant {
        case user
        case system
        case llm
    }
    
    /// Utility to create a pending messsage.
    static func pending(participant: Participant) -> ChatMessage {
        return ChatMessage(message: "", pending: true, participant: participant)
    }
}
