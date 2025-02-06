//
//  ConversationalViewModel.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import GoogleGenerativeAI
import SwiftUI

@MainActor
class ConversationViewModel: ObservableObject {
    @Published var messages = [ChatMessage]()
    @Published var busy = false
    @Published var error: Error?
    var hasError: Bool {
        error != nil
    }

    // Add selectedModel, and initialize it.
    @Published var selectedModel: String {
        didSet {
            // Important: When the model changes, restart the chat.
            startNewChat()
        }
    }
    
    private var initialModel: String = "gemini-1.5-flash-latest"

    private var model: GenerativeModel
    private var chat: Chat
    //private var stopGenerating = false // Removed - unused

    private var chatTask: Task<Void, Never>?

    init() {
        // Use the selectedModel, not a hardcoded string.
        self.model = GenerativeModel(name: initialModel, apiKey: APIKey.default)
        self.chat = model.startChat()
        self.selectedModel = "gemini-1.5-flash-latest"
    }

    func updateModel() {
        self.model = GenerativeModel(name: selectedModel, apiKey: APIKey.default)
        self.chat = model.startChat()
    }


    func sendMessage(_ text: String, streaming: Bool = true) async {
        error = nil
        if streaming {
            await internalSendMessageStreaming(text)
        } else {
            await internalSendMessage(text)
        }
    }

    func startNewChat() {
        stop()
        error = nil
        updateModel() // Re-initialize the model
        messages.removeAll()
    }

    func stop() {
        chatTask?.cancel()
        error = nil
    }

    private func internalSendMessageStreaming(_ text: String) async {
        chatTask?.cancel()

        chatTask = Task {
            busy = true
            defer {
                busy = false
            }

            let userMessage = ChatMessage(message: text, participant: .user)
            messages.append(userMessage)

            let systemMessage = ChatMessage.pending(participant: .system)
            messages.append(systemMessage)

            do {
                let responseStream = chat.sendMessageStream(text)
                for try await chunk in responseStream {
                    messages[messages.count - 1].pending = false
                    if let text = chunk.text {
                        messages[messages.count - 1].message += text
                    }
                }
            } catch {
                self.error = error
                print(error.localizedDescription)
                messages.removeLast()
            }
        }
    }

    private func internalSendMessage(_ text: String) async {
        chatTask?.cancel()

        chatTask = Task {
            busy = true
            defer {
                busy = false
            }

            let userMessage = ChatMessage(message: text, participant: .user)
            messages.append(userMessage)
            let systemMessage = ChatMessage.pending(participant: .system)
            messages.append(systemMessage)

            do {
                let response = try await chat.sendMessage(text)

                if let responseText = response.text {
                    messages[messages.count - 1].message = responseText
                    messages[messages.count - 1].pending = false
                }
            } catch {
                self.error = error
                print(error.localizedDescription)
                messages.removeLast()
            }
        }
    }
}
