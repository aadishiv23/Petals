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
                    .onAppear {
                        print("\(message.participant.stringValue)")
                        print("🩸 typing indicator appeared")
                    }
            } else if let toolName = message.toolCallName {
                ToolMessageView(message: message, bubbleColor: bubbleColor, toolName: toolName)
                    .onAppear {
                        print("🙅‍♂️ tool message view appeared")
                    }
            } else {
                TextMessageView(message: message, bubbleColor: bubbleColor, textColor: textColor)
                    .onAppear {
                        print("💀 text msg view appeared")
                    }
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
