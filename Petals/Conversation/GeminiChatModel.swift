//
//  GeminiChatModel.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/15/25.
//

import Foundation
import GoogleGenerativeAI
import PetalTools

class GeminiChatModel: AIChatModel {
    private var model: GenerativeModel
    private var chat: Chat

    init(modelName: String) {
        self.model = GenerativeModel(name: modelName, apiKey: APIKey.default)
        self.chat = model.startChat()
    }

    func sendMessageStream(_ text: String) -> AsyncStream<PetalMessageStreamChunk> {
        return AsyncStream { continuation in
            Task {
                do {
                    for try await response in chat.sendMessageStream(text) {
                        if let textChunk = response.text {
                            continuation.yield(PetalMessageStreamChunk(message: textChunk, toolCallName: nil))
                        }
                    }
                    continuation.finish()
                } catch {
                    print("Gemini streaming error: \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }


    func sendMessage(_ text: String) async throws -> String {
        let response = try await chat.sendMessage(text)
        return response.text ?? ""
    }
}
