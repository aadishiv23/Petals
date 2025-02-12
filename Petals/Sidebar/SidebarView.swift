//
//  SidebarView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/12/25.
//

import Foundation
import SwiftUI

struct SidebarView: View {

    /// The search query for the search bar.
    @State private var searchQuery: String = ""

    /// The binding to the selected sidebar item.
    @Binding var selectedItem: SidebarItem?
    
    // FIXME: Temp
    @ObservedObject var conversationalVM: ConversationViewModel

    var body: some View {
        VStack {
            TextField("Search", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding()

            List(selection: $selectedItem) {
                Label("Home", image: "house")
                    .tag(SidebarItem.home)

                // LLM Chat (just a placeholder if you want to jump right in)
                Label("LLM Chat", systemImage: "ellipsis.bubble")
                    .tag(SidebarItem.chat(id: UUID())) // ephemeral ID if you want direct switch

                Divider()
                
                Button {
                    // Do action in future
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("New Chat")
                    }
                }
                .buttonStyle(LinkButtonStyle())
                .padding()
            }
            .listStyle(.sidebar)
        }
    }
}
