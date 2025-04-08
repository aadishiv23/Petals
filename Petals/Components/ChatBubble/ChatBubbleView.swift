//
//  ChatBubbleView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/12/25.
//

import Foundation
import PetalCore
import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false

    /// Message appearance based on sender
    var bubbleColor: Color {
        message.participant == .user
            ? Color(hex: "5E5CE6")
            : (colorScheme == .dark ? Color(NSColor.controlBackgroundColor) : Color(NSColor.controlBackgroundColor))
    }

    var textColor: Color {
        message.participant == .user
            ? .white
            : (colorScheme == .dark ? .white : .primary)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.participant == .llm || message.participant == .system {
                Avatar(participant: .llm)
                    .offset(y: 2)

                MessageContentView(message: message, bubbleColor: bubbleColor, textColor: textColor)
                    .padding(.trailing, 60)

                Spacer()
            } else {
                Spacer()

                MessageContentView(message: message, bubbleColor: bubbleColor, textColor: textColor)
                    .padding(.leading, 60)

                Avatar(participant: .user)
                    .offset(y: 2)
            }
        }
        .padding(.vertical, 2)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
} 
