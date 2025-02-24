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

    @Published var selectedModel: String {
        didSet {
            startNewChat() // ✅ This line requires the function to exist.
        }
    }

    @Published var useOllama: Bool = false {
        didSet {
            switchModel()
        }
    }

    private var chatModel: AIChatModel

    init() {
        let initialModel = "gemini-1.5-flash-latest"
        self.selectedModel = initialModel
        self.chatModel = GeminiChatModel(modelName: initialModel)
    }

    /// ✅ **Fix: Add back `startNewChat()`**
    func startNewChat() {
        stop()
        error = nil
        switchModel() // ✅ Ensures the selected model is properly set.
        messages.removeAll()
    }

    func stop() {
        // Placeholder for stopping ongoing tasks (if any)
        error = nil
    }

    private func switchModel() {
        if useOllama {
            chatModel = OllamaChatModel()
            print("🔵 Now using **Ollama** (local model)")
        } else {
            chatModel = GeminiChatModel(modelName: selectedModel)
            print("🟢 Now using **Gemini** (Google API) with model: \(selectedModel)")
        }
        messages.removeAll()
    }

    func sendMessage(_ text: String, streaming: Bool = true) async {
        error = nil
        messages.append(ChatMessage(message: text, participant: .user))
        messages.append(ChatMessage.pending(participant: .system))

        do {
            if streaming {
                let stream = chatModel.sendMessageStream(text)
                for await chunk in stream {
                    messages[messages.count - 1].message += chunk
                    messages[messages.count - 1].pending = false
                }
            } else {
                let response = try await chatModel.sendMessage(text)
                messages[messages.count - 1].message = response
                messages[messages.count - 1].pending = false
            }
        } catch {
            self.error = error
            messages.removeLast()
        }
    }
}
