//
//  ChatInputBar.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import SwiftUI

struct ChatInputBar: View {
    @Binding var userInput: String
    @FocusState private var isFocused: Bool
    var sendMessage: () -> Void

    var body: some View {
        HStack {
            // Use TextField instead of TextEditor for simpler input handling
            TextField("Message", text: $userInput)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.windowBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .focused($isFocused)
                .onSubmit(sendMessage)  // This enables Enter key submission

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(userInput.isEmpty ? .gray : .blue)
            }
            .keyboardShortcut(.return, modifiers: [])  // Return key shortcut
            .disabled(userInput.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.windowBackgroundColor))
    }
}
