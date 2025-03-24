//
//  CDConversation+CoreDataProperties.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/24/25.
//
//

import Foundation
import CoreData


extension CDConversation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDConversation> {
        return NSFetchRequest<CDConversation>(entityName: "CDConversation")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var cdMessages: NSSet?

}

// MARK: Generated accessors for cdMessages
extension CDConversation {

    @objc(addCdMessagesObject:)
    @NSManaged public func addToCdMessages(_ value: CDChatMessage)

    @objc(removeCdMessagesObject:)
    @NSManaged public func removeFromCdMessages(_ value: CDChatMessage)

    @objc(addCdMessages:)
    @NSManaged public func addToCdMessages(_ values: NSSet)

    @objc(removeCdMessages:)
    @NSManaged public func removeFromCdMessages(_ values: NSSet)

}

extension CDConversation : Identifiable {

}
