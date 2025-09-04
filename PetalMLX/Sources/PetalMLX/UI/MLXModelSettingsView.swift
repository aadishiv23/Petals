//
//  MLXModelSettingsView.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import SwiftUI
import MLXLMCommon

/// A comprehensive settings view for managing MLX models
public struct MLXModelSettingsView: View {
    @ObservedObject private var modelManager = MLXModelManager.shared
    @State private var showingModelSelection = false
    @State private var showingDeleteAlert = false
    @State private var modelToDelete: ModelConfiguration?
    
    public init() {}
    
    public var body: some View {
        List {
            // Current model section
            Section {
                currentModelRow
            } header: {
                Text("Current Model")
            }
            
            // Available models section
            Section {
                ForEach(modelManager.availableModels, id: \.name) { model in
                    modelManagementRow(for: model)
                }
            } header: {
                Text("Available Models")
            } footer: {
                Text("Downloaded models can be used offline. Delete models to free up storage space.")
            }
            
            // Storage information
            Section {
                storageInfoView
            } header: {
                Text("Storage Information")
            }
        }
        .navigationTitle("MLX Models")
        .sheet(isPresented: $showingModelSelection) {
            MLXModelSelectionView(selectedModel: $modelManager.selectedModel)
        }
        .alert("Delete Model", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { 
                modelToDelete = nil
            }
            Button("Delete", role: .destructive) { 
                if let model = modelToDelete {
                    Task {
                        try? await modelManager.deleteModel(model)
                    }
                }
                modelToDelete = nil
            }
        } message: {
            if let model = modelToDelete {
                Text("Are you sure you want to delete \(model.name)? This will free up storage space but you'll need to download it again to use it.")
            }
        }
    }
    
    private var currentModelRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(modelManager.selectedModel.name)
                    .font(.headline)
                
                HStack {
                    statusBadge(for: modelManager.selectedModel)
                    
                    if let size = modelManager.selectedModel.modelSize {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(formatSize(size)) GB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button("Change") {
                showingModelSelection = true
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(6)
        }
    }
    
    private func modelManagementRow(for model: ModelConfiguration) -> some View {
        VStack(spacing: 0) {
            HStack {
                modelIcon(for: model)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        statusBadge(for: model)
                        
                        if let size = model.modelSize {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("\(formatSize(size)) GB")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if modelManager.isModelAvailable(model) {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(modelManager.getModelSize(model))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                actionButtonsForModel(model)
            }
            
            // Show progress if downloading
            if let progress = modelManager.activeDownloads[model.idString] {
                MLXDownloadProgressView(
                    progress: progress,
                    onCancel: {
                        modelManager.cancelDownload(model)
                    }
                )
                .padding(.top, 12)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func modelIcon(for model: ModelConfiguration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(iconBackgroundColor(for: model))
                .frame(width: 36, height: 36)
            
            Image(systemName: iconName(for: model))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private func iconBackgroundColor(for model: ModelConfiguration) -> Color {
        switch model.modelType {
        case .reasoning:
            return .purple
        case .regular:
            return .blue
        }
    }
    
    private func iconName(for model: ModelConfiguration) -> String {
        switch model.modelType {
        case .reasoning:
            return "brain"
        case .regular:
            return "cpu"
        }
    }
    
    @ViewBuilder
    private func statusBadge(for model: ModelConfiguration) -> some View {
        let status = modelManager.getModelStatus(model)
        
        HStack(spacing: 4) {
            switch status {
            case .downloaded:
                if modelManager.selectedModel == model {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Active")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Downloaded")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
            case .downloading:
                ProgressView()
                    .scaleEffect(0.6)
                Text("Downloading")
                    .font(.caption2)
                    .foregroundColor(.orange)
                
            case .notDownloaded:
                Image(systemName: "icloud.and.arrow.down")
                    .foregroundColor(.gray)
                    .font(.caption)
                Text("Not Downloaded")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                Text("Failed")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
    }
    
    @ViewBuilder
    private func actionButtonsForModel(_ model: ModelConfiguration) -> some View {
        let status = modelManager.getModelStatus(model)
        
        HStack(spacing: 8) {
            switch status {
            case .downloaded:
                if modelManager.selectedModel != model {
                    Button("Use") {
                        modelManager.selectedModel = model
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                }
                
                Button("Delete") {
                    modelToDelete = model
                    showingDeleteAlert = true
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(4)
                
            case .downloading:
                Button("Cancel") {
                    modelManager.cancelDownload(model)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(4)
                
            case .notDownloaded, .failed:
                Button("Download") {
                    Task {
                        await modelManager.downloadModel(model)
                    }
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
            }
        }
    }
    
    private var storageInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Downloaded Models")
                Spacer()
                Text("\(downloadedModelsCount)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Total Storage Used")
                Spacer()
                Text(totalStorageUsed)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Available Models")
                Spacer()
                Text("\(modelManager.availableModels.count)")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var downloadedModelsCount: Int {
        modelManager.availableModels.count { model in
            modelManager.isModelAvailable(model)
        }
    }
    
    private var totalStorageUsed: String {
        // Calculate total storage used by all downloaded models
        let totalBytes = modelManager.availableModels.reduce(0) { total, model in
            guard modelManager.isModelAvailable(model) else { return total }
            
            let modelDirectory = model.modelDirectory()
            do {
                let resourceValues = try modelDirectory.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                return total + (resourceValues.totalFileAllocatedSize ?? 0)
            } catch {
                return total
            }
        }
        
        return ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }
    
    private func formatSize(_ size: Decimal) -> String {
        return String(format: "%.1f", NSDecimalNumber(decimal: size).doubleValue)
    }
}

#Preview {
    NavigationView {
        MLXModelSettingsView()
    }
}
