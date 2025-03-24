//
//  CDConversation+Extensions.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/24/25.
//

import CoreData
import Foundation

extension CDConversation {

    func fullContext() -> String {
        guard let messagesSet = cdMessages as? Set<CDChatMessage> else {
            return ""
        }
        let sortedMessages = messagesSet.sorted(by: {
            ($0.date ?? .distantPast) < ($1.date ?? .distantPast)
        })
        return sortedMessages.map { "\(($0.participant ?? "unknown").capitalized): \($0.message)" }
            .joined(separator: "\n")
    }
}

// MARK: - Generated populate (struct -> CDconversation model)

extension CDConversation {
    func populate(from conversation: Conversation, context: NSManagedObjectContext) {
        id = conversation.id
        title = conversation.title
        createdAt = conversation.createdAt

        let cdMessages = conversation.messages.map { message -> CDChatMessage in
            let cdMessage = CDChatMessage(context: context)
            cdMessage.populate(from: message, in: self)
            return cdMessage
        }
        addToCdMessages(NSSet(array: cdMessages))
    }
}
