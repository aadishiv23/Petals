//
//  GenericToolMessageView.swift
//  Petals
//
//  Created for ChatBubbleView
//

import SwiftUI
import PetalCore

struct GenericToolMessageView: View {
    let message: ChatMessage
    let bubbleColor: Color
    let toolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "hammer")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text("Tool: \(toolName)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text(message.message)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .foregroundColor(.primary)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(BubbleShape(isUser: message.participant == .user).fill(bubbleColor))
        .contextMenu {
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.message, forType: .string)
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }
} 