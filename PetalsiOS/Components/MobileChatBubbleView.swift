//
//  MobileChatBubbleView.swift
//  PetalsiOS
//
//  Created for iOS target
//

import SwiftUI
import PetalCore

struct MobileChatBubbleView: View {
    let message: ChatMessage
    @State private var showingOptions = false

    var body: some View {
        HStack(alignment: .top) {
            // Avatar
            if message.participant == .llm {
                MobileAvatar(participant: .llm)
                    .padding(.top, 4)
            }

            // Message bubble
            VStack(alignment: message.participant == .user ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.message)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                message.participant == .user
                                    ? Color(hex: "5E5CE6")
                                    : Color(UIColor.secondarySystemBackground)
                            )
                    )
                    .foregroundColor(
                        message.participant == .user
                            ? .white
                            : Color.primary
                    )
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = message.message
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
            }
            .frame(maxWidth: .infinity, alignment: message.participant == .user ? .trailing : .leading)

            // User avatar (right side)
            if message.participant == .user {
                MobileAvatar(participant: .user)
                    .padding(.top, 4)
            }
        }
    }
} 