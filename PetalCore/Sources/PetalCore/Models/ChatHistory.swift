//
//  File.swift
//  PetalCore
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import Foundation
/// Represents a single saved chat in the sidebar
public struct ChatHistory: Identifiable {
    public let id: UUID
    public var title: String
    public var lastMessage: String?
    public var lastActivityDate: Date?
    
    public init(id: UUID = UUID(), title: String, lastMessage: String? = nil, lastActivityDate: Date? = Date()) {
        self.id = id
        self.title = title
        self.lastMessage = lastMessage
        self.lastActivityDate = lastActivityDate
    }
}
