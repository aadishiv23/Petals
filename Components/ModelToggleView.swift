//
//  ModelToggleView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import SwiftUI
import PetalMLX
import MLXLMCommon

/// A modern toggle view for switching between Gemini and MLX models with status indicators
struct ModelToggleView: View {
    @Binding var useMLX: Bool
    @Binding var selectedMLXModel: ModelConfiguration
    @ObservedObject private var modelManager = MLXModelManager.shared
    @State private var showingMLXModelSelection = false
    @State private var showingMLXSettings = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Model status indicator
            statusIndicator
            
            // Toggle switch
            Toggle("", isOn: $useMLX)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .scaleEffect(0.8)
            
            // Model selection button
            Button(action: {
                if useMLX {
                    showingMLXSettings = true
                } else {
                    showingMLXModelSelection = true
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "gear")
                        .font(.system(size: 12))
                    Text("Settings")
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingMLXModelSelection) {
            MLXModelSelectionView(selectedModel: $selectedMLXModel)
        }
        .sheet(isPresented: $showingMLXSettings) {
            NavigationView {
                MLXModelSettingsView()
            }
        }
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            // Model icon
            Image(systemName: useMLX ? "desktopcomputer" : "cloud")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(useMLX ? .blue : .green)
            
            // Model name and status
            VStack(alignment: .leading, spacing: 2) {
                Text(useMLX ? "MLX" : "Gemini")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                
                if useMLX {
                    let status = modelManager.getModelStatus(selectedMLXModel)
                    HStack(spacing: 4) {
                        switch status {
                        case .downloaded:
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text(selectedMLXModel.name)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                        case .downloading:
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 6, height: 6)
                            Text("Downloading...")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            
                        case .notDownloaded:
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                            Text("Not Available")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            
                        case .failed:
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("Failed")
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Online")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(minWidth: 100, alignment: .leading)
    }
    
    private var backgroundMaterial: some View {
        #if os(macOS)
        return VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        #else
        return Color(.secondarySystemGroupedBackground)
        #endif
    }
}

#Preview {
    ModelToggleView(
        useMLX: .constant(false),
        selectedMLXModel: .constant(ModelConfiguration.defaultModel)
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
