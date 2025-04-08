//
//  MobileHomeContent.swift
//  PetalsiOS
//
//  Created for iOS target
//

import SwiftUI

struct MobileHomeContent: View {
    var newChatAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "5E5CE6"))

            Text("Petals")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            Text("Your personal AI assistant powered by Gemini and MLX")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()

            Button(action: newChatAction) {
                HStack {
                    Image(systemName: "plus")
                    Text("New Chat")
                }
                .frame(minWidth: 200, minHeight: 44)
                .background(Color(hex: "5E5CE6"))
                .foregroundColor(.white)
                .cornerRadius(22)
                .padding()
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .padding()
    }
} 