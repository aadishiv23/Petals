//
//  ChatBubbleView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/12/25.
//

import Foundation
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
                // AI avatar
                Avatar(participant: .llm)
                    .offset(y: 2)

                // AI message
                MessageContent
                    .padding(.trailing, 60)

                Spacer()
            } else {
                Spacer()

                // User message
                MessageContent
                    .padding(.leading, 60)

                // User avatar
                Avatar(participant: .user)
                    .offset(y: 2)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Message Content

    @ViewBuilder
    var MessageContent: some View {
        VStack(alignment: message.participant == .user ? .trailing : .leading, spacing: 4) {
            // Message content
            if message.pending {
                TypingIndicator()
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Capsule().fill(bubbleColor))
            } else {
                // Message text
                Group {
                    Text(message.message)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(textColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    BubbleShape(isUser: message.participant == .user)
                        .fill(bubbleColor)
                )
                .contextMenu {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(message.message, forType: .string)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            }

            // Optional timestamp
            if isHovered, !message.pending {
                Text("\(message.date.formatted(date: .numeric, time: .shortened))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)
            }
        }
        .onHover(perform: { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        })
    }
}

// MARK: - Supporting Views

struct BubbleShape: Shape {
    var isUser: Bool

    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 12
        let minX = rect.minX
        let minY = rect.minY
        let maxX = rect.maxX
        let maxY = rect.maxY

        let path = Path { p in
            if isUser {
                // User message (right corner)
                p.move(to: CGPoint(x: minX + cornerRadius, y: minY))
                p.addLine(to: CGPoint(x: maxX - cornerRadius - 4, y: minY))
                p.addCurve(
                    to: CGPoint(x: maxX, y: minY + cornerRadius),
                    control1: CGPoint(x: maxX - 4, y: minY),
                    control2: CGPoint(x: maxX, y: minY + 4)
                )
                p.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
                p.addCurve(
                    to: CGPoint(x: maxX - cornerRadius, y: maxY),
                    control1: CGPoint(x: maxX, y: maxY - 4),
                    control2: CGPoint(x: maxX - 4, y: maxY)
                )
                p.addLine(to: CGPoint(x: minX + cornerRadius, y: maxY))
                p.addCurve(
                    to: CGPoint(x: minX, y: maxY - cornerRadius),
                    control1: CGPoint(x: minX + 4, y: maxY),
                    control2: CGPoint(x: minX, y: maxY - 4)
                )
                p.addLine(to: CGPoint(x: minX, y: minY + cornerRadius))
                p.addCurve(
                    to: CGPoint(x: minX + cornerRadius, y: minY),
                    control1: CGPoint(x: minX, y: minY + 4),
                    control2: CGPoint(x: minX + 4, y: minY)
                )
            } else {
                // AI message (left corner)
                p.move(to: CGPoint(x: minX + cornerRadius, y: minY))
                p.addLine(to: CGPoint(x: maxX - cornerRadius, y: minY))
                p.addCurve(
                    to: CGPoint(x: maxX, y: minY + cornerRadius),
                    control1: CGPoint(x: maxX - 4, y: minY),
                    control2: CGPoint(x: maxX, y: minY + 4)
                )
                p.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
                p.addCurve(
                    to: CGPoint(x: maxX - cornerRadius, y: maxY),
                    control1: CGPoint(x: maxX, y: maxY - 4),
                    control2: CGPoint(x: maxX - 4, y: maxY)
                )
                p.addLine(to: CGPoint(x: minX + cornerRadius + 4, y: maxY))
                p.addCurve(
                    to: CGPoint(x: minX, y: maxY - cornerRadius),
                    control1: CGPoint(x: minX + 4, y: maxY),
                    control2: CGPoint(x: minX, y: maxY - 4)
                )
                p.addLine(to: CGPoint(x: minX, y: minY + cornerRadius))
                p.addCurve(
                    to: CGPoint(x: minX + cornerRadius, y: minY),
                    control1: CGPoint(x: minX, y: minY + 4),
                    control2: CGPoint(x: minX + 4, y: minY)
                )
            }
            p.closeSubpath()
        }
        return path
    }
}

struct Avatar: View {
    let participant: ChatMessage.Participant
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    participant == .user
                        ? Color(hex: "5E5CE6")
                        : (colorScheme == .dark ? Color(hex: "5A5A5A") : Color(hex: "D8D8D8"))
                )
                .frame(width: 28, height: 28)

            if participant == .user {
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationOffset = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .opacity(0.7)
                    .offset(y: animationOffset * (index == 1 ? 1.5 : 1))
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                animationOffset = -5
            }
        }
    }
}
