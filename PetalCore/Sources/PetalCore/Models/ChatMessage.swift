//
//  File.swift
//  PetalCore
//
//  Created by Aadi Shiv Malhotra on 3/27/25.
//

import Foundation

public struct ChatMessage: Identifiable, Equatable, Hashable, Codable {
    public let id = UUID()
    public let date = Date()

    public var message: String
    public var pending: Bool = false
    public var participant: Participant
    public var toolCallName: String? = nil

    public enum Participant: String, Codable, CaseIterable {
        case user = "user"
        case system = "system"
        case llm = "llm"

        public var stringValue: String {
            switch self {
            case .user:
                "User"
            case .system:
                "System"
            case .llm:
                "LLM"
            }
        }
    }

    /// Public initializer for creating messages from outside the module.
    public init(
        message: String,
        pending: Bool = false,
        participant: Participant,
        toolCallName: String? = nil
    ) {
        self.message = message
        self.pending = pending
        self.participant = participant
        self.toolCallName = toolCallName
    }

    /// Utility to create a pending messsage.
    public static func pending(participant: Participant) -> ChatMessage {
        ChatMessage(message: "", pending: true, participant: participant)
    }
}
