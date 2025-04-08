//
//  TypingIndicator.swift
//  Petals
//
//  Created for ChatBubbleView
//

import SwiftUI

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