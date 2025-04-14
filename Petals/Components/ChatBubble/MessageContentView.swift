//
//  MessageContentView.swift
//  Petals
//
//  Created for ChatBubbleView
//

import Foundation
import PetalCore
import SwiftUI

struct MessageContentView: View {
    let message: ChatMessage
    let bubbleColor: Color
    let textColor: Color

    var body: some View {
        VStack(alignment: message.participant == .user ? .trailing : .leading, spacing: 4) {
            if message.pending {
                TypingIndicator()
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Capsule().fill(bubbleColor))
            }
            // Use the custom reasoning view if the message contains a chain-of-thought.
//            else if message.message.contains("<think>") {
//                ReasoningMessageView(chatMessage: message)
//            }
            else if message.message.hasPrefix("<think>") {
                ReasoningMessageView(chatMessage: message)
            }
            // Existing handling for tool calls:
            else if let toolName = message.toolCallName {
                ToolMessageView(message: message, bubbleColor: bubbleColor, toolName: toolName)
            }
            // Otherwise, fall back to a regular text message view.
            else {
                TextMessageView(message: message, bubbleColor: bubbleColor, textColor: textColor)
            }

            if !message.pending {
                Text("\(message.date.formatted(date: .numeric, time: .shortened))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)
            }
        }
    }
}
