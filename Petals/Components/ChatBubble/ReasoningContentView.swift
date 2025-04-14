//
//  ReasoningContentView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 4/13/25.
//

import Foundation
import PetalCore
import SwiftUI

/// A view to display a message that includes internal reasoning wrapped in <think>...</think> tags.
/// It shows an elegant animated thinking process and reveals the final answer with a smooth transition.
struct ReasoningMessageView: View {
    let chatMessage: ChatMessage

    // Extracted content from the message
    let reasoningText: String?
    let finalText: String

    // Animation states
    @State private var revealFinalText: Bool = false
    @State private var showReasoning: Bool = false
    @State private var animationProgress: CGFloat = 0
    @State private var pulseAnimation: Bool = false

    /// Theme colors
    private let thinkingColor = Color(hex: "9E8CFC")

    init(chatMessage: ChatMessage) {
        self.chatMessage = chatMessage
        let parsed = ReasoningMessageView.parseMessage(chatMessage.message)
        self.reasoningText = parsed.reasoning
        self.finalText = parsed.finalAnswer
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Final answer or thinking animation
            if revealFinalText {
                Text(finalText)
                    .transition(.opacity)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                thinkingView
            }

            // Reasoning section (if available)
            if let reasoning = reasoningText, !reasoning.isEmpty {
                reasoningView(reasoning)
            }
        }
        .padding(16)
        .background(
            BubbleShape(isUser: chatMessage.participant == .user)
                .fill(chatMessage.participant == .user ? Color(hex: "5E5CE6") : Color(NSColor.controlBackgroundColor))
        )
        .onAppear {
            startAnimations()
        }
    }

    /// Extracted thinking animation view
    private var thinkingView: some View {
        HStack(spacing: 16) {
            // Animated dots
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(thinkingColor)
                        .frame(width: 6, height: 6)
                        .scaleEffect(pulseAnimation && index == Int(animationProgress * 3) % 3 ? 1.5 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: pulseAnimation
                        )
                }
            }

            Text("Thinking...")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
        }
    }

    /// Extracted reasoning view
    private func reasoningView(_ reasoning: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                withAnimation(.spring()) {
                    showReasoning.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(thinkingColor)

                    Text("View Reasoning")
                        .font(.footnote.weight(.medium))

                    Spacer()

                    Image(systemName: showReasoning ? "chevron.up" : "chevron.down")
                        .imageScale(.small)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if showReasoning {
                withAnimation(.easeIn(duration: 0.3)) {
                    Text(reasoning)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                        .cornerRadius(6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    /// Start all animations
    private func startAnimations() {
        pulseAnimation = true

        withAnimation(.easeInOut(duration: finalText.contains("</think>") ? 2.0 : 8.0)) {
            animationProgress = 1.0
        }

        let showFinalDelay = finalText.contains("</think>") ? 2.0 : 8.0

        DispatchQueue.main.asyncAfter(deadline: .now() + showFinalDelay) {
            withAnimation {
                revealFinalText = true
            }
        }
    }

    /// Parser that extracts the chain-of-thought and the final answer
    private static func parseMessage(_ message: String) -> (reasoning: String?, finalAnswer: String) {
        if let startRange = message.range(of: "Okay"),
           let endRange = message.range(of: "</think>")
        {
            let reasoning = String(message[startRange.upperBound..<endRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let finalAnswer = String(message[endRange.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (reasoning, finalAnswer)
        } else {
            return (nil, message)
        }
    }
}
