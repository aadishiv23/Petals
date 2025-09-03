//
//  SettingsView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section("AI Model") {
                    Toggle(isOn: $conversationVM.useOllama) {
                        HStack {
                            Image(systemName: conversationVM.useOllama ? "desktopcomputer" : "cloud")
                                .foregroundColor(.blue)
                            Text(conversationVM.useOllama ? "Ollama (Local)" : "Gemini API (Cloud)")
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Aadi Shiv Malhotra")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Data") {
                    Button("Clear All Chat History") {
                        conversationVM.clearAllChatHistory()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(conversationVM: ConversationViewModel())
}
