//
//  MLXModelManager.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import Foundation
import MLXLMCommon
import MLXLLM
import Hub
import SwiftUI
import Combine

/// Manages MLX model downloading, caching, and lifecycle
@MainActor
public class MLXModelManager: ObservableObject, Sendable {
    
    public static let shared = MLXModelManager()
    
    // MARK: - Published Properties
    
    /// All available MLX models
    @Published public var availableModels: [ModelConfiguration] = ModelConfiguration.availableModels
    
    /// Currently selected model
    @Published public var selectedModel: ModelConfiguration = ModelConfiguration.defaultModel
    
    /// Download status for each model
    @Published public var modelStatus: [String: MLXModelStatus] = [:]
    
    /// Active downloads with progress tracking
    @Published public var activeDownloads: [String: MLXModelDownloadProgress] = [:]
    
    // MARK: - Private Properties
    
    private var cancellationTokens: [String: Task<Void, Never>] = [:]
    private let fileManager = FileManager.default
    
    private init() {
        loadModelStatuses()
    }
    
    // MARK: - Public Methods
    
    /// Check if a model is downloaded and available locally
    public func isModelAvailable(_ model: ModelConfiguration) -> Bool {
        return modelStatus[model.idString]?.isDownloaded == true
    }
    
    /// Get the download status for a model
    public func getModelStatus(_ model: ModelConfiguration) -> MLXModelStatus {
        return modelStatus[model.idString] ?? .notDownloaded
    }
    
    /// Start downloading a model
    public func downloadModel(_ model: ModelConfiguration) async {
        let modelId = model.idString
        
        // Check if already downloading
        guard activeDownloads[modelId] == nil else {
            print("Model \(model.name) is already being downloaded")
            return
        }
        
        // Create download progress tracker
        let downloadProgress = MLXModelDownloadProgress(
            modelId: modelId,
            modelName: model.name,
            totalSize: NSDecimalNumber(decimal: model.modelSize ?? 0.0).doubleValue
        )
        
        activeDownloads[modelId] = downloadProgress
        modelStatus[modelId] = .downloading
        
        // Create cancellation token for this download
        let downloadTask = Task { @MainActor in
            do {
                try await performModelDownload(model: model, progress: downloadProgress)
                
                // Download completed successfully
                activeDownloads.removeValue(forKey: modelId)
                modelStatus[modelId] = .downloaded
                saveModelStatuses()
                
                print("✅ Model \(model.name) downloaded successfully")
                
            } catch {
                // Download failed
                activeDownloads.removeValue(forKey: modelId)
                modelStatus[modelId] = .failed(error)
                saveModelStatuses()
                
                print("❌ Failed to download model \(model.name): \(error)")
            }
        }
        
        cancellationTokens[modelId] = downloadTask
    }
    
    /// Cancel an active download
    public func cancelDownload(_ model: ModelConfiguration) {
        let modelId = model.idString
        
        // Cancel the task
        cancellationTokens[modelId]?.cancel()
        cancellationTokens.removeValue(forKey: modelId)
        
        // Clean up progress tracking
        activeDownloads.removeValue(forKey: modelId)
        modelStatus[modelId] = .notDownloaded
        
        print("🚫 Cancelled download for model \(model.name)")
    }
    
    /// Delete a downloaded model
    public func deleteModel(_ model: ModelConfiguration) async throws {
        let modelId = model.idString
        
        // Cancel any active downloads first
        cancelDownload(model)
        
        // Get the model directory
        let modelDirectory = model.modelDirectory()
        
        // Delete the model files
        if fileManager.fileExists(atPath: modelDirectory.path) {
            try fileManager.removeItem(at: modelDirectory)
        }
        
        // Update status
        modelStatus[modelId] = .notDownloaded
        saveModelStatuses()
        
        print("🗑️ Deleted model \(model.name)")
    }
    
    /// Get the local storage size for a model
    public func getModelSize(_ model: ModelConfiguration) -> String {
        let modelDirectory = model.modelDirectory()
        
        guard fileManager.fileExists(atPath: modelDirectory.path) else {
            return "Not downloaded"
        }
        
        do {
            let resourceValues = try modelDirectory.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
            if let size = resourceValues.totalFileAllocatedSize {
                return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            }
        } catch {
            print("Error getting model size: \(error)")
        }
        
        return "Unknown size"
    }
    
    /// Load a specific model for use
    public func loadModel(_ model: ModelConfiguration) async throws -> ModelContainer {
        guard isModelAvailable(model) else {
            throw MLXModelManagerError.modelNotDownloaded(model.name)
        }
        
        // Update selected model
        selectedModel = model
        
        // Load using existing MLX infrastructure
        return try await LLMModelFactory.shared.loadContainer(configuration: model) { progress in
            Task { @MainActor in
                print("Loading \(model.name): \(Int(progress.fractionCompleted * 100))%")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performModelDownload(model: ModelConfiguration, progress: MLXModelDownloadProgress) async throws {
        // Use MLX's built-in download mechanism with progress tracking
        _ = try await LLMModelFactory.shared.loadContainer(configuration: model) { downloadProgress in
            Task { @MainActor in
                let percentage = downloadProgress.fractionCompleted
                let bytesCompleted = Int64(percentage * progress.totalSize)
                
                // Update our progress tracker
                progress.update(
                    downloadedBytes: bytesCompleted,
                    totalBytes: Int64(progress.totalSize),
                    percentage: percentage
                )
                
                print("Download \(model.name): \(Int(percentage * 100))% - \(ByteCountFormatter.string(fromByteCount: bytesCompleted, countStyle: .file)) / \(ByteCountFormatter.string(fromByteCount: Int64(progress.totalSize), countStyle: .file))")
            }
        }
    }
    
    private func loadModelStatuses() {
        // Check each available model's download status on disk
        for model in availableModels {
            let modelId = model.idString
            let modelDirectory = model.modelDirectory()
            
            if fileManager.fileExists(atPath: modelDirectory.path) {
                modelStatus[modelId] = .downloaded
            } else {
                modelStatus[modelId] = .notDownloaded
            }
        }
    }
    
    private func saveModelStatuses() {
        // Persist model statuses to UserDefaults or similar storage
        let statusData = modelStatus.compactMapValues { status in
            switch status {
            case .downloaded: return "downloaded"
            case .notDownloaded: return "notDownloaded"
            case .downloading: return "downloading"
            case .failed: return "failed"
            }
        }
        
        UserDefaults.standard.set(statusData, forKey: "MLXModelStatuses")
    }
}

// MARK: - Supporting Types

/// Represents the download status of an MLX model
public enum MLXModelStatus: Equatable {
    case notDownloaded
    case downloading
    case downloaded
    case failed(Error)
    
    public var isDownloaded: Bool {
        if case .downloaded = self { return true }
        return false
    }
    
    public var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
    
    public static func == (lhs: MLXModelStatus, rhs: MLXModelStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notDownloaded, .notDownloaded): return true
        case (.downloading, .downloading): return true
        case (.downloaded, .downloaded): return true
        case (.failed, .failed): return true
        default: return false
        }
    }
}

/// Tracks download progress for an MLX model
@MainActor
public class MLXModelDownloadProgress: ObservableObject, Identifiable {
    public let id = UUID()
    public let modelId: String
    public let modelName: String
    public let totalSize: Double
    
    @Published public var downloadedBytes: Int64 = 0
    @Published public var percentage: Double = 0.0
    @Published public var isComplete: Bool = false
    @Published public var estimatedTimeRemaining: TimeInterval?
    
    private var startTime: Date = Date()
    
    public init(modelId: String, modelName: String, totalSize: Double) {
        self.modelId = modelId
        self.modelName = modelName
        self.totalSize = totalSize
        self.startTime = Date()
    }
    
    public func update(downloadedBytes: Int64, totalBytes: Int64, percentage: Double) {
        self.downloadedBytes = downloadedBytes
        self.percentage = percentage
        self.isComplete = percentage >= 1.0
        
        // Calculate estimated time remaining
        if downloadedBytes > 0 {
            let elapsedTime = Date().timeIntervalSince(startTime)
            let bytesPerSecond = Double(downloadedBytes) / elapsedTime
            let remainingBytes = Double(totalBytes - downloadedBytes)
            
            if bytesPerSecond > 0 {
                self.estimatedTimeRemaining = remainingBytes / bytesPerSecond
            }
        }
    }
    
    public var formattedProgress: String {
        let downloaded = ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
        return "\(downloaded) / \(total)"
    }
    
    public var formattedTimeRemaining: String {
        guard let timeRemaining = estimatedTimeRemaining, timeRemaining > 0 else {
            return "Calculating..."
        }
        
        if timeRemaining < 60 {
            return String(format: "%.0f seconds remaining", timeRemaining)
        } else if timeRemaining < 3600 {
            return String(format: "%.0f minutes remaining", timeRemaining / 60)
        } else {
            return String(format: "%.1f hours remaining", timeRemaining / 3600)
        }
    }
}

/// Errors that can occur in the MLX Model Manager
public enum MLXModelManagerError: LocalizedError {
    case modelNotDownloaded(String)
    case downloadFailed(String, Error)
    case deleteFailed(String, Error)
    
    public var errorDescription: String? {
        switch self {
        case .modelNotDownloaded(let modelName):
            return "Model '\(modelName)' is not downloaded. Please download it first."
        case .downloadFailed(let modelName, let error):
            return "Failed to download model '\(modelName)': \(error.localizedDescription)"
        case .deleteFailed(let modelName, let error):
            return "Failed to delete model '\(modelName)': \(error.localizedDescription)"
        }
    }
}
