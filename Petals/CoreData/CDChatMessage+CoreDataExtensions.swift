//
//  CDChatMessage+CoreDataExtensions.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/24/25.
//

import CoreData
import Foundation

extension CDChatMessage {
    func populate(from message: ChatMessage, in conversation: CDConversation) {
        id = message.id
        self.message = message.message
        date = message.date
        pending = message.pending
        participant = "\(message.participant)"
        cdConversation = conversation
    }
}
