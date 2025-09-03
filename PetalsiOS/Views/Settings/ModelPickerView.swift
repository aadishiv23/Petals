//
//  ModelPickerView.swift
//  PetalsiOS
//
//  Created for iOS target
//

import SwiftUI
import PetalMLX
import MLXLMCommon

struct ModelPickerView: View {
    @Binding var useMLX: Bool
    @Binding var selectedMLXModel: ModelConfiguration
    @ObservedObject private var modelManager = MLXModelManager.shared
    @State private var showingMLXModelSelection = false
    
    var body: some View {
        List {
            Section(header: Text("Select Model")) {
                Button(action: { useMLX = false }) {
                    HStack {
                        Image(systemName: "cloud")
                            .foregroundColor(Color(hex: "5E5CE6"))
                        Text("Gemini API (Cloud)")
                        Spacer()
                        if !useMLX {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(hex: "5E5CE6"))
                        }
                    }
                }
                
                Button(action: { 
                    if modelManager.isModelAvailable(selectedMLXModel) {
                        useMLX = true
                    } else {
                        showingMLXModelSelection = true
                    }
                }) {
                    HStack {
                        Image(systemName: "desktopcomputer")
                            .foregroundColor(Color(hex: "5E5CE6"))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MLX (Local)")
                            
                            if useMLX {
                                Text(selectedMLXModel.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                statusText
                            }
                        }
                        
                        Spacer()
                        
                        if useMLX {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(hex: "5E5CE6"))
                        } else if !modelManager.isModelAvailable(selectedMLXModel) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            if useMLX {
                Section {
                    Button("Change MLX Model") {
                        showingMLXModelSelection = true
                    }
                    .foregroundColor(Color(hex: "5E5CE6"))
                    
                    if let progress = modelManager.activeDownloads[selectedMLXModel.idString] {
                        MLXDownloadProgressView(
                            progress: progress,
                            onCancel: {
                                modelManager.cancelDownload(selectedMLXModel)
                            }
                        )
                    }
                } header: {
                    Text("MLX Model Settings")
                }
            }
        }
        .navigationTitle("Model Selection")
        .sheet(isPresented: $showingMLXModelSelection) {
            MLXModelSelectionView(selectedModel: $selectedMLXModel)
        }
    }
    
    private var statusText: some View {
        let status = modelManager.getModelStatus(selectedMLXModel)
        
        switch status {
        case .downloaded:
            return Text("Ready to use")
                .font(.caption)
                .foregroundColor(.green)
        case .downloading:
            return Text("Downloading...")
                .font(.caption)
                .foregroundColor(.orange)
        case .notDownloaded:
            return Text("Not downloaded")
                .font(.caption)
                .foregroundColor(.secondary)
        case .failed:
            return Text("Download failed")
                .font(.caption)
                .foregroundColor(.red)
        }
    }
} 