//
//  PetalsApp.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import SwiftUI

@main
struct PetalsApp: App {

    /// The user’s selection in the sidebar
    @State private var selectedSidebarItem: SidebarItem? = .home
    
    // FIXME:
    ///Temp, eval in future
    @StateObject private var conversationVM = ConversationViewModel()

    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                SidebarView(selectedItem: $selectedSidebarItem)
            } detail: {
                switch selectedSidebarItem {
                case .home:
                    HomeView()
                case .chat(let id):
                    EmptyView()
                case .none:
                    Text("Select a tab from the sidebar.")
                        .font(.title)
                }
            }

        }
    }
}
