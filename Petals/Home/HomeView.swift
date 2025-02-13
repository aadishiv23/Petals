//
//  HomeView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/12/25.
//

import Foundation
import SwiftUI

struct HomeView: View {

    /// Callback invoked when the user clicks your "start chat" box
    var startChatAction: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("What can  I help with?")
                .font(.system(size: 32).bold())
                //.padding(.top, 64)

            // A button to start a brand new chat
            Button(action: startChatAction) {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)

                    Text("Start chat")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.windowBackgroundColor))
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Action Buttons
            HStack(spacing: 16) {
                ActionButton(icon: "wand.and.stars", text: "Create image", color: .green)
                ActionButton(icon: "bubble.left", text: "Get advice", color: .blue)
                ActionButton(icon: "pencil", text: "Help me write", color: .purple)
                ActionButton(icon: "lightbulb", text: "Make a plan", color: .yellow)
                ActionButton(icon: "ellipsis", text: "More", color: .gray)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    HomeView {}
}
