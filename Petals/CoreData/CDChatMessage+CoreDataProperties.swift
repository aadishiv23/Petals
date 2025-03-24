//
//  CDChatMessage+CoreDataProperties.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/24/25.
//
//

import Foundation
import CoreData


extension CDChatMessage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDChatMessage> {
        return NSFetchRequest<CDChatMessage>(entityName: "CDChatMessage")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var message: String?
    @NSManaged public var participant: String?
    @NSManaged public var pending: Bool
    @NSManaged public var cdConversation: CDConversation?

}

extension CDChatMessage : Identifiable {

}
