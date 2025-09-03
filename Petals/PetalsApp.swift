//
//  PetalsApp.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import SwiftUI

@main
struct PetalsApp: App {
    @StateObject private var conversationVM = ConversationViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                UnifiedHomeView(conversationVM: conversationVM)
            }
        }
    }
}
