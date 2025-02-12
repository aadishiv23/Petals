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
        VStack {
            Text("Hello World")
            // A button to start a brand new chat
            Button(action: startChatAction) {
                Text("Start Chat")
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }
}
