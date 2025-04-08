//
//  ContentView.swift
//  PetalsiOS
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import SwiftUI
import PetalCore

struct ContentView: View {
    @StateObject private var conversationVM = ConversationViewModel()
    
    var body: some View {
        MobileHomeView(conversationVM: conversationVM)
    }
}

#Preview {
    ContentView()
}
