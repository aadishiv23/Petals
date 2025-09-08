//
//  TelemetryContext.swift
//  PetalCore
//
//  Created by AI Assistant on 4/3/25.
//

import Foundation

@MainActor
public final class TelemetryContext: ObservableObject {
    public static let shared = TelemetryContext()

    @Published public var currentChatId: UUID?
    @Published public var currentMessageId: UUID?

    private init() {}

    public func set(chatId: UUID?, messageId: UUID?) {
        currentChatId = chatId
        currentMessageId = messageId
    }

    public func clear() {
        currentChatId = nil
        currentMessageId = nil
    }
}



