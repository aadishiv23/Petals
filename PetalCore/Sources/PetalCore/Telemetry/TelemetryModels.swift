//
//  TelemetryModels.swift
//  PetalCore
//
//  Created by AI Assistant on 4/3/25.
//

import Foundation

public struct TelemetryMessageContext: Codable, Hashable {
    public let chatId: UUID
    public let messageId: UUID
}

public struct TelemetryToolInvocation: Codable, Hashable {
    public let name: String
    public let startAt: Date
    public let endAt: Date?
    public let success: Bool?
    public let errorDescription: String?

    public var durationMs: Double? {
        guard let endAt else { return nil }
        return endAt.timeIntervalSince(startAt) * 1000.0
    }
}

public struct TelemetryMessageMetrics: Codable, Hashable {
    public let messageId: UUID
    public let userText: String
    public let modelName: String
    public let startedAt: Date
    public var firstTokenAt: Date?
    public var completedAt: Date?
    public var finalResponse: String?
    public var modelInitialOutput: String?
    public var chosenToolName: String?
    public var toolRawOutput: String?
    public var toolCallJsonRaw: String?
    public var toolCallJsonNormalized: String?
    public var responseLengthChars: Int
    public var estimatedTokens: Int
    public var toolInvocations: [TelemetryToolInvocation]
    public var errorDescription: String?

    public init(messageId: UUID, userText: String, modelName: String, startedAt: Date) {
        self.messageId = messageId
        self.userText = userText
        self.modelName = modelName
        self.startedAt = startedAt
        self.firstTokenAt = nil
        self.completedAt = nil
        self.responseLengthChars = 0
        self.estimatedTokens = 0
        self.toolInvocations = []
        self.errorDescription = nil
        self.finalResponse = nil
        self.modelInitialOutput = nil
        self.chosenToolName = nil
        self.toolRawOutput = nil
        self.toolCallJsonRaw = nil
        self.toolCallJsonNormalized = nil
    }

    public var timeToFirstTokenMs: Double? {
        guard let firstTokenAt else { return nil }
        return firstTokenAt.timeIntervalSince(startedAt) * 1000.0
    }

    public var totalLatencyMs: Double? {
        guard let completedAt else { return nil }
        return completedAt.timeIntervalSince(startedAt) * 1000.0
    }

    public var generationDurationMs: Double? {
        guard let completedAt, let firstTokenAt else { return nil }
        return completedAt.timeIntervalSince(firstTokenAt) * 1000.0
    }

    public var tokensPerSecond: Double? {
        guard let genMs = generationDurationMs, genMs > 0 else { return nil }
        return Double(estimatedTokens) / (genMs / 1000.0)
    }
}

public struct TelemetryChatSession: Codable, Identifiable {
    public let id: UUID
    public let createdAt: Date
    public var updatedAt: Date
    public var messages: [TelemetryMessageMetrics]

    public init(id: UUID) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
    }
}


