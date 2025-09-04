//
//  SettingsView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import SwiftUI
import PetalMLX
import MLXLMCommon

/// Settings view for the desktop Petals app
struct SettingsView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Model Selection Section
                Section {
                    ModelSelectionRow(conversationVM: conversationVM)
                    
                    if conversationVM.useOllama {
                        NavigationLink("MLX Model Management") {
                            MLXModelSettingsView()
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    Text("AI Model")
                } footer: {
                    if conversationVM.useOllama {
                        Text("MLX models run locally on your device. Manage downloads and switch between available models.")
                    } else {
                        Text("Gemini API requires an internet connection and API key.")
                    }
                }
                
                // Chat History Section
                Section {
                    HStack {
                        Text("Total Conversations")
                        Spacer()
                        Text("\(conversationVM.chatHistory.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear All Chat History") {
                        conversationVM.clearAllChatHistory()
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Chat History")
                }
                
                // About Section
                Section {
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
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .frame(minWidth: 400, minHeight: 500)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// A row for model selection
struct ModelSelectionRow: View {
    @ObservedObject var conversationVM: ConversationViewModel
    @ObservedObject private var modelManager = MLXModelManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Current selection
            HStack {
                Text("Current Model")
                    .font(.headline)
                Spacer()
            }
            
            // Model options
            VStack(spacing: 8) {
                // Gemini option
                ModelOptionRow(
                    icon: "cloud",
                    title: "Gemini API",
                    subtitle: "Cloud-based • Always available",
                    isSelected: !conversationVM.useOllama,
                    statusColor: .green
                ) {
                    conversationVM.useOllama = false
                }
                
                // MLX option
                ModelOptionRow(
                    icon: "desktopcomputer",
                    title: "MLX Local",
                    subtitle: mlxSubtitle,
                    isSelected: conversationVM.useOllama,
                    statusColor: mlxStatusColor
                ) {
                    if modelManager.isModelAvailable(conversationVM.selectedMLXModel) {
                        conversationVM.useOllama = true
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var mlxSubtitle: String {
        let status = modelManager.getModelStatus(conversationVM.selectedMLXModel)
        
        switch status {
        case .downloaded:
            return "Local • \(conversationVM.selectedMLXModel.name)"
        case .downloading:
            return "Downloading • \(conversationVM.selectedMLXModel.name)"
        case .notDownloaded:
            return "Not downloaded • \(conversationVM.selectedMLXModel.name)"
        case .failed:
            return "Download failed • \(conversationVM.selectedMLXModel.name)"
        }
    }
    
    private var mlxStatusColor: Color {
        let status = modelManager.getModelStatus(conversationVM.selectedMLXModel)
        
        switch status {
        case .downloaded:
            return .green
        case .downloading:
            return .orange
        case .notDownloaded:
            return .gray
        case .failed:
            return .red
        }
    }
}

/// A row for individual model options
struct ModelOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let statusColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView(conversationVM: ConversationViewModel())
}
