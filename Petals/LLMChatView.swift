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
    @State private var showActionBar = false

    let availableModels = [
        "gemini-1.5-flash-8b",
        "gemini-1.5-flash",
        "gemini-2.0-flash",
        "gemini-2.0-flash-lite-preview-02-05",
        "gemini-1.5-pro"
    ]

    var body: some View {
        VStack(spacing: 0) {
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
            
            HStack {
                Button {
                    showActionBar.toggle()
                } label: {
                    Image(systemName: "chevron.up")
                        .rotationEffect(showActionBar ? Angle(degrees: 90) : Angle(degrees: 0))
                }

                if showActionBar {
                    withAnimation {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ActionButton(icon: "doc.fill", label: "Docs")
                                ActionButton(icon: "pencil", label: "Canvas")
                                ActionButton(icon: "calendar", label: "Calendar")
                                ActionButton(icon: "lightbulb", label: "Ideas")
                                ActionButton(icon: "chart.bar", label: "Analyze")
                                ActionButton(icon: "graduationcap", label: "Advice")
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
            }
            .padding(.bottom, 10)

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

struct ActionButton: View {
    let icon: String
    let label: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            Text(label)
                .font(.caption)
        }
        .padding(8)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
