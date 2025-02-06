//
//  LLMChatView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import GoogleGenerativeAI
import SwiftUI

struct LLMChatView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    @State private var userInput: String = ""
    @Namespace private var animation

    let availableModels = [
        "gemini-1.5-flash-8b",
        "gemini-1.5-flash",
        "gemini-2.0-flash",
        "gemini-2.0-flash-lite-preview-02-05",
        "gemini-1.5-pro"
    ]

    var body: some View {
        VStack(spacing: 0) { // Set spacing to 0
            VStack {
                // Model selection dropdown
                Picker("Model", selection: $conversationVM.selectedModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .padding()

                ScrollView {
                    ForEach(conversationVM.messages, id: \.id) { msg in
                        ChatBubbleView(message: msg)
                    }
                }
                .padding()
            }

            ChatInputBar(userInput: $userInput) {
                Task {
                    let text = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else {
                        return
                    }
                    userInput = ""
                    await conversationVM.sendMessage(text, streaming: true)
                }
            }
        }
    }
}
