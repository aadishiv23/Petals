//
//  CoreDataRepository.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/24/25.
//

import Foundation
import CoreData

final class CoreDataChatRepository: ChatRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
    }

    // MARK: - Conversations

    func createConversation(title: String) -> Conversation {
        let cdConversation = CDConversation(context: context)
        let now = Date()
        cdConversation.id = UUID()
        cdConversation.title = title
        cdConversation.createdAt = now
        CoreDataManager.shared.saveContext()

        return Conversation(
            id: cdConversation.id!,
            title: cdConversation.title ?? "Untitled",
            createdAt: now,
            messages: []
        )
    }

    func fetchAllConversations() -> [Conversation] {
        let request: NSFetchRequest<CDConversation> = CDConversation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let results = try context.fetch(request)
            return results.map { Conversation(from: $0) }
        } catch {
            print("❌ Failed to fetch conversations: \(error)")
            return []
        }
    }

    func deleteConversation(_ conversation: Conversation) {
        let request: NSFetchRequest<CDConversation> = CDConversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", conversation.id as CVarArg)

        do {
            if let cdConversation = try context.fetch(request).first {
                context.delete(cdConversation)
                CoreDataManager.shared.saveContext()
            }
        } catch {
            print("❌ Failed to delete conversation: \(error)")
        }
    }

    // MARK: - Messages

    func addMessage(_ message: ChatMessage, to conversation: Conversation) {
        let request: NSFetchRequest<CDConversation> = CDConversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", conversation.id as CVarArg)

        guard let cdConversation = try? context.fetch(request).first else {
            print("❌ Could not find conversation to add message to.")
            return
        }

        let cdMessage = CDChatMessage(context: context)
        cdMessage.populate(from: message, in: cdConversation)
        cdConversation.addToCdMessages(cdMessage)

        CoreDataManager.shared.saveContext()
    }

    func fetchMessages(for conversation: Conversation) -> [ChatMessage] {
        let request: NSFetchRequest<CDChatMessage> = CDChatMessage.fetchRequest()
        request.predicate = NSPredicate(format: "cdConversation.id == %@", conversation.id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        do {
            return try context.fetch(request).map { ChatMessage(from: $0) }
        } catch {
            print("❌ Failed to fetch messages: \(error)")
            return []
        }
    }
}
