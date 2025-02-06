//
//  HomeView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import SwiftUI

struct HomeView: View {

    // Callback invoked when the user clicks your "start chat" box
    var startChatAction: () -> Void

    var body: some View {
        VStack {
            Text("Welcome to the Home View!")
                .font(.largeTitle)
                .padding()

            // Just some placeholder boxes
            HStack {
                boxView(title: "Brainstorm")
                boxView(title: "Ideate")
                boxView(title: "Analyze")
            }

            Spacer().frame(height: 50)

            // A button to start a brand new chat
            Button(action: startChatAction) {
                Text("Start Chat")
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }

    // A small helper to mimic "box" UI
    func boxView(title: String) -> some View {
        VStack {
            Text(title)
                .font(.headline)
        }
        .frame(width: 120, height: 100)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
        .padding()
    }
}
