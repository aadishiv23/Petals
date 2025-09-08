//
//  TelemetryManager.swift
//  PetalCore
//
//  Created by AI Assistant on 4/3/25.
//

import Foundation

@MainActor
public final class TelemetryManager: ObservableObject {
    public static let shared = TelemetryManager()

    @Published public private(set) var sessions: [UUID: TelemetryChatSession] = [:]

    private let settings = TelemetrySettings.shared
    private let persistenceKey = "telemetry.sessions"

    private init() {
        load()
    }

    // MARK: Session lifecycle

    public func ensureSession(for chatId: UUID) {
        guard settings.telemetryEnabled else { return }
        if sessions[chatId] == nil {
            sessions[chatId] = TelemetryChatSession(id: chatId)
            persist()
        }
    }

    public func clearAll() {
        sessions.removeAll()
        persist()
    }

    // MARK: Message metrics

    public func startMessage(chatId: UUID, messageId: UUID, userText: String, modelName: String) {
        guard settings.telemetryEnabled else { return }
        ensureSession(for: chatId)
        var session = sessions[chatId] ?? TelemetryChatSession(id: chatId)
        let metrics = TelemetryMessageMetrics(messageId: messageId, userText: userText, modelName: modelName, startedAt: Date())
        session.messages.append(metrics)
        session.updatedAt = Date()
        sessions[chatId] = session
        persist()
    }

    public func markFirstToken(chatId: UUID, messageId: UUID) {
        guard settings.telemetryEnabled else { return }
        guard var session = sessions[chatId], let idx = session.messages.firstIndex(where: { $0.messageId == messageId }) else { return }
        session.messages[idx].firstTokenAt = session.messages[idx].firstTokenAt ?? Date()
        session.updatedAt = Date()
        sessions[chatId] = session
        persist()
    }

    public func appendGeneratedChunk(chatId: UUID, messageId: UUID, chunk: String) {
        guard settings.telemetryEnabled else { return }
        guard var session = sessions[chatId], let idx = session.messages.firstIndex(where: { $0.messageId == messageId }) else { return }
        session.messages[idx].responseLengthChars += chunk.count
        // Rough token estimate: 4 chars per token (heuristic)
        session.messages[idx].estimatedTokens = max(session.messages[idx].estimatedTokens, session.messages[idx].responseLengthChars / 4)
        session.updatedAt = Date()
        sessions[chatId] = session
        persist()
    }

    public func completeMessage(chatId: UUID, messageId: UUID) {
        guard settings.telemetryEnabled else { return }
        guard var session = sessions[chatId], let idx = session.messages.firstIndex(where: { $0.messageId == messageId }) else { return }
        session.messages[idx].completedAt = Date()
        session.updatedAt = Date()
        sessions[chatId] = session
        persist()
    }

    public func setFinalResponse(chatId: UUID, messageId: UUID, text: String) {
        guard settings.telemetryEnabled else { return }
        guard var session = sessions[chatId], let idx = session.messages.firstIndex(where: { $0.messageId == messageId }) else { return }
        session.messages[idx].finalResponse = text
        session.updatedAt = Date()
        sessions[chatId] = session
        persist()
    }

    public func setModelInitialOutput(chatId: UUID, messageId: UUID, text: String) {
        guard settings.telemetryEnabled else { return }
        guard var session = sessions[chatId], let idx = session.messages.firstIndex(where: { $0.messageId == messageId }) else { return }
        session.messages[idx].modelInitialOutput = text
        session.updatedAt = Date()
        sessions[chatId] = session
        persist()
    }

    public func setChosenTool(chatId: UUID, messageId: UUID, name: String?) {
        guard settings.telemetryEnabled else { return }
        guard var session = sessions[chatId], let idx = session.messages.firstIndex(where: { $0.messageId == messageId }) else { return }
        session.messages[idx].chosenToolName = name
        session.updatedAt = Date()
        sessions[chatId] = session
        persist()
    }

    public func setToolRawOutput(chatId: UUID, messageId: UUID, text: String) {
        guard settings.telemetryEnabled else { return }
        guard var session = sessions[chatId], let idx = session.messages.firstIndex(where: { $0.messageId == messageId }) else { return }
        session.messages[idx].toolRawOutput = text
        session.updatedAt = Date()
        sessions[chatId] = session
        persist()
    }

    public func setToolCallJson(chatId: UUID, messageId: UUID, raw: String?, normalized: String?) {
        guard settings.telemetryEnabled else { return }
        guard var session = sessions[chatId], let idx = session.messages.firstIndex(where: { $0.messageId == messageId }) else { return }
        if let raw { session.messages[idx].toolCallJsonRaw = raw }
        if let normalized { session.messages[idx].toolCallJsonNormalized = normalized }
        session.updatedAt = Date()
        sessions[chatId] = session
        persist()
    }

    public func failMessage(chatId: UUID, messageId: UUID, errorDescription: String) {
        guard settings.telemetryEnabled else { return }
        guard var session = sessions[chatId], let idx = session.messages.firstIndex(where: { $0.messageId == messageId }) else { return }
        session.messages[idx].errorDescription = errorDescription
        session.messages[idx].completedAt = Date()
        session.updatedAt = Date()
        sessions[chatId] = session
        persist()
    }

    // MARK: Tool tracking

    public func startTool(chatId: UUID, messageId: UUID, name: String) {
        guard settings.telemetryEnabled else { return }
        guard var session = sessions[chatId], let idx = session.messages.firstIndex(where: { $0.messageId == messageId }) else { return }
        session.messages[idx].toolInvocations.append(TelemetryToolInvocation(name: name, startAt: Date(), endAt: nil, success: nil, errorDescription: nil))
        session.updatedAt = Date()
        sessions[chatId] = session
        persist()
    }

    public func endTool(chatId: UUID, messageId: UUID, name: String, success: Bool, errorDescription: String? = nil) {
        guard settings.telemetryEnabled else { return }
        guard var session = sessions[chatId], let idx = session.messages.firstIndex(where: { $0.messageId == messageId }) else { return }
        if let toolIdx = session.messages[idx].toolInvocations.lastIndex(where: { $0.name == name && $0.endAt == nil }) {
            var tool = session.messages[idx].toolInvocations[toolIdx]
            tool = TelemetryToolInvocation(name: tool.name, startAt: tool.startAt, endAt: Date(), success: success, errorDescription: errorDescription)
            session.messages[idx].toolInvocations[toolIdx] = tool
            session.updatedAt = Date()
            sessions[chatId] = session
            persist()
        }
    }

    // MARK: Persistence

    private func persist() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            // Swallow persistence errors for now
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
        if let decoded = try? JSONDecoder().decode([UUID: TelemetryChatSession].self, from: data) {
            sessions = decoded
        }
    }
}


