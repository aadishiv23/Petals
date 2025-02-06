//
//  ChatBubbleView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.participant == .user {
                Spacer()
                bubbleContent
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            } else {
                bubbleContent
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var bubbleContent: some View {
        if message.pending {
            HStack(spacing: 8) {
                ProgressView()
                Text("Responding...")
            }
        } else {
            FormattedMarkdownView(text: message.message)
        }
    }
}
