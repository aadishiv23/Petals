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
                .onSubmit(sendMessage)

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(userInput.isEmpty ? .gray : .blue)
            }
            .keyboardShortcut(.return, modifiers: [])
            .disabled(userInput.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.windowBackgroundColor))
    }
}
