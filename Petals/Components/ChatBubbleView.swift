//
//  ChatBubbleView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/12/25.
//

import Foundation
import SwiftUI

struct ChatBubbleView: View {
    
    /// The message payload.
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.participant == .user {
                Spacer()
                bubbleContent
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                bubbleContent
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.gray.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Spacer()
            }
        }
    }
    
    // MARK: Subview
    
    @ViewBuilder
    private var bubbleContent: some View {
        if message.pending {
            HStack(spacing: 8) {
                ProgressView()
                Text("Responding...")
            }
        } else {
            // FormattedMarkdownView(text: message.message)
            Text(message.message)
        }
    }

}
