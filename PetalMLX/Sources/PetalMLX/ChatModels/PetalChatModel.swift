//
//  PetalMLXChatModel.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 3/31/25.
//

import Foundation
import MLXLMCommon
import PetalCore
import SwiftUI

/// A concrete chat model that wraps PetalMLXService and conforms to AIChatModel.
@MainActor
public class PetalMLXChatModel: AIChatModel {
    private let service: PetalMLXService
    private let model: ModelConfiguration
    
    /// Conversation history with context window management
    public private(set) var conversationHistory: [ChatMessage] = []
    
    /// Maximum context window size in tokens (estimated)
    private let maxContextTokens: Int
    
    /// Initialize with a model configuration.
    public init(model: ModelConfiguration, maxContextTokens: Int = 2048) {
        self.model = model
        self.maxContextTokens = maxContextTokens
        self.service = PetalMLXService() // Now safe because we're on the MainActor.
    }

    /// Sends a complete message (non-streaming) using PetalMLXService.
    public func sendMessage(_ text: String) async throws -> String {
        // Create a ChatMessage for the user.
        let userMessage = ChatMessage(message: text, participant: .user)
        addToHistory(userMessage)
        
        // Get managed conversation history with context window
        let managedHistory = getManagedHistory()
        
        // Let the service generate a response.
        let response = try await service.sendSingleMessage(model: model, messages: managedHistory)
        
        // Add AI response to history
        let aiMessage = ChatMessage(message: response, participant: .llm)
        addToHistory(aiMessage)
        
        return response
    }

    /// Returns an asynchronous stream of output chunks from PetalMLXService.
    public func sendMessageStream(_ text: String) -> AsyncThrowingStream<PetalMessageStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            let producer = Task {
                do {
                    let userMessage = ChatMessage(message: text, participant: .user)
                    addToHistory(userMessage)
                    
                    // Get managed conversation history with context window
                    let managedHistory = getManagedHistory()
                    
                    let stream = service.streamConversation(model: model, messages: managedHistory)
                    var aiResponse = ""
                    
                    for try await chunk in stream {
                        if Task.isCancelled { break }
                        continuation.yield(chunk)
                        aiResponse += chunk.message
                    }
                    
                    // Add AI response to history after streaming completes
                    if !aiResponse.isEmpty {
                        let aiMessage = ChatMessage(message: aiResponse, participant: .llm)
                        addToHistory(aiMessage)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                producer.cancel()
            }
        }
    }
    
    // MARK: - Context Management
    
    /// Adds a message to conversation history
    private func addToHistory(_ message: ChatMessage) {
        conversationHistory.append(message)
        trimHistoryIfNeeded()
    }
    
    /// Gets conversation history with system prompt and context window management
    private func getManagedHistory() -> [ChatMessage] {
        let systemMessage = ChatMessage(
            message: "You are a helpful assistant with access to tools: Calendar (create/fetch events), Canvas/LMS (courses, assignments, grades), Reminders (create/search/manage), Notes (create/search/manage), and Contacts (search/list). Only use tools when explicitly requested. You will be passed in a set of tools for a query IF it is deemed to require tools. Current date is \(Date()).",
            participant: .system
        )
        
        return [systemMessage] + conversationHistory
    }
    
    /// Trims conversation history to stay within context window
    private func trimHistoryIfNeeded() {
        let estimatedTokens = estimateTokenCount(conversationHistory)
        
        if estimatedTokens > maxContextTokens {
            // Remove oldest messages while keeping recent context
            // Always keep the last few messages and try to maintain conversation flow
            let minMessagesToKeep = 6 // Keep at least 3 user-assistant pairs
            
            while conversationHistory.count > minMessagesToKeep && 
                  estimateTokenCount(conversationHistory) > Int(Double(maxContextTokens) * 0.8) {
                conversationHistory.removeFirst()
            }
        }
    }
    
    /// Simple token estimation (roughly 4 characters per token)
    private func estimateTokenCount(_ messages: [ChatMessage]) -> Int {
        let totalCharacters = messages.reduce(0) { count, message in
            count + message.message.count
        }
        return totalCharacters / 4 // Rough approximation
    }
    
    /// Gets current token usage for UI display
    public func getCurrentTokenUsage() -> (used: Int, max: Int) {
        let managedHistory = getManagedHistory()
        let currentTokens = estimateTokenCount(managedHistory)
        return (used: currentTokens, max: maxContextTokens)
    }
    
    /// Clears conversation history
    public func clearHistory() {
        conversationHistory.removeAll()
    }
}
