//
//  MLXModelSelectionView.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import SwiftUI
import MLXLMCommon

/// A beautiful model selection view with download capabilities
public struct MLXModelSelectionView: View {
    @ObservedObject private var modelManager = MLXModelManager.shared
    @Binding var selectedModel: ModelConfiguration
    @Environment(\.dismiss) private var dismiss
    
    public init(selectedModel: Binding<ModelConfiguration>) {
        self._selectedModel = selectedModel
    }
    
    public var body: some View {
        NavigationView {
            List {
                ForEach(modelManager.availableModels, id: \.name) { model in
                    MLXModelRowView(
                        model: model,
                        selectedModel: $selectedModel,
                        onDownload: { 
                            Task {
                                await modelManager.downloadModel(model)
                            }
                        },
                        onCancel: {
                            modelManager.cancelDownload(model)
                        },
                        onDelete: {
                            Task {
                                try? await modelManager.deleteModel(model)
                            }
                        }
                    )
                }
            }
            .navigationTitle("MLX Models")
            .navigationBarTitleDisplayMode(.large)
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

/// Individual model row with status and actions
struct MLXModelRowView: View {
    let model: ModelConfiguration
    @Binding var selectedModel: ModelConfiguration
    let onDownload: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void
    
    @ObservedObject private var modelManager = MLXModelManager.shared
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main model row
            HStack(spacing: 16) {
                // Model icon and info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        modelIcon
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text(modelTypeText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let size = model.modelSize {
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
                    }
                    
                    // Status and actions
                    statusView
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                if modelManager.isModelAvailable(model) {
                    selectedModel = model
                }
            }
            
            // Progress view for active downloads
            if let progress = modelManager.activeDownloads[model.idString] {
                MLXDownloadProgressView(progress: progress, onCancel: onCancel)
                    .padding(.top, 8)
            }
        }
        .alert("Delete Model", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Are you sure you want to delete \(model.name)? This will free up storage space but you'll need to download it again to use it.")
        }
    }
    
    private var modelIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(iconBackgroundColor)
                .frame(width: 48, height: 48)
            
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var iconBackgroundColor: Color {
        switch model.modelType {
        case .reasoning:
            return .purple
        case .regular:
            return .blue
        }
    }
    
    private var iconName: String {
        switch model.modelType {
        case .reasoning:
            return "brain"
        case .regular:
            return "cpu"
        }
    }
    
    private var modelTypeText: String {
        switch model.modelType {
        case .reasoning:
            return "Reasoning Model"
        case .regular:
            return "Language Model"
        }
    }
    
    private var statusView: some View {
        let status = modelManager.getModelStatus(model)
        
        return HStack {
            statusIndicator(for: status)
            
            Spacer()
            
            actionButton(for: status)
        }
    }
    
    @ViewBuilder
    private func statusIndicator(for status: MLXModelStatus) -> some View {
        HStack(spacing: 6) {
            switch status {
            case .downloaded:
                if selectedModel == model {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Selected")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                    Text("Downloaded")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
            case .downloading:
                ProgressView()
                    .scaleEffect(0.8)
                Text("Downloading...")
                    .font(.caption)
                    .foregroundColor(.orange)
                
            case .notDownloaded:
                Image(systemName: "icloud.and.arrow.down")
                    .foregroundColor(.secondary)
                Text("Not Downloaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
            case .failed(let error):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Failed")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    @ViewBuilder
    private func actionButton(for status: MLXModelStatus) -> some View {
        switch status {
        case .downloaded:
            Menu {
                if selectedModel != model {
                    Button("Select") {
                        selectedModel = model
                    }
                }
                
                Button("Delete", role: .destructive) {
                    showingDeleteAlert = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
            
        case .downloading:
            Button("Cancel") {
                onCancel()
            }
            .font(.caption)
            .foregroundColor(.red)
            
        case .notDownloaded, .failed:
            Button("Download") {
                onDownload()
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(6)
        }
    }
    
    private func formatSize(_ size: Decimal) -> String {
        return String(format: "%.1f", NSDecimalNumber(decimal: size).doubleValue)
    }
}

/// Progress view for active downloads
public struct MLXDownloadProgressView: View {
    @ObservedObject var progress: MLXModelDownloadProgress
    let onCancel: () -> Void
    
    public init(progress: MLXModelDownloadProgress, onCancel: @escaping () -> Void) {
        self.progress = progress
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress.percentage, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.3), value: progress.percentage)
                }
            }
            .frame(height: 8)
            
            // Progress info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(progress.percentage * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(progress.formattedProgress)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(progress.formattedTimeRemaining)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(.caption2)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    MLXModelSelectionView(selectedModel: .constant(ModelConfiguration.defaultModel))
}
