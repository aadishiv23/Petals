//
//  Avatar.swift
//  Petals
//
//  Created for ChatBubbleView
//

import SwiftUI
import PetalCore

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