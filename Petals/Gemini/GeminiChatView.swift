//
//  GeminiChatView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/12/25.
//

import Foundation
import SwiftUI

struct GeminiChatView: View {

    @ObservedObject var conversationVM: ConversationViewModel
    @State private var userInput: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                ForEach(conversationVM.messages, id: \.self) { msg in
                    ChatBubbleView(message: msg)
                }
            }
            .padding()

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
