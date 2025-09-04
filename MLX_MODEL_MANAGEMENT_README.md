# MLX Model Management System

## Overview

A comprehensive MLX model management system that allows users to select, download, and manage local AI models with beautiful progress tracking and seamless integration.

## ✨ Features

### 🔄 Model Selection & Switching
- **Smart Model Picker**: Beautiful UI showing all available MLX models with status indicators
- **Seamless Switching**: Toggle between Gemini (cloud) and MLX (local) models
- **Automatic Fallback**: Falls back to Gemini if selected MLX model isn't available
- **Real-time Status**: Shows download status, model availability, and current selection

### 📥 Download Management
- **Progress Tracking**: Real-time download progress with percentage, size, and time estimates
- **Cancel Downloads**: Ability to cancel ongoing downloads
- **Smart Validation**: Checks model availability before switching
- **Error Handling**: Graceful error handling with user-friendly messages

### 💾 Storage Management
- **Local Storage**: Models stored locally for offline use
- **Size Information**: Shows model sizes and storage usage
- **Delete Models**: Remove downloaded models to free up space
- **Storage Overview**: View total storage used by all models

### 🎨 Beautiful UI Components
- **Progress Bars**: Animated progress indicators with detailed information
- **Status Badges**: Color-coded status indicators (downloaded, downloading, failed)
- **Model Cards**: Rich model information cards with icons and metadata
- **Settings Integration**: Seamless integration into both mobile and desktop settings

## 🏗️ Architecture

### Core Components

#### `MLXModelManager`
- **Singleton Service**: Centralized model management
- **Download Orchestration**: Handles model downloading with progress tracking
- **Status Management**: Tracks model availability and download status
- **Storage Management**: Manages local model storage and cleanup

#### `MLXModelDownloadProgress`
- **Real-time Tracking**: Live progress updates during downloads
- **Detailed Metrics**: Size, percentage, speed, and time estimates
- **Observable**: SwiftUI integration with `@ObservableObject`

#### `MLXModelStatus`
- **State Management**: Tracks model states (downloaded, downloading, failed, etc.)
- **Error Handling**: Captures and presents download errors
- **Availability Checks**: Quick status checks for UI updates

### UI Components

#### `MLXModelSelectionView`
- **Model Browser**: Browse and select from available models
- **Download Interface**: Initiate downloads directly from selection
- **Progress Display**: Show download progress inline
- **Status Indicators**: Visual status for each model

#### `MLXModelSettingsView`
- **Management Hub**: Central location for model management
- **Storage Overview**: View storage usage and model information
- **Bulk Operations**: Download, delete, and manage multiple models
- **Current Model**: Shows and allows changing the active model

#### `ModelToggleView`
- **Quick Switch**: Fast switching between Gemini and MLX
- **Status Display**: Shows current model and availability
- **Settings Access**: Quick access to model management
- **Visual Feedback**: Clear visual indicators for model status

## 📱 Platform Integration

### iOS (PetalsiOS)
- **Native iOS Design**: Follows iOS design patterns and guidelines
- **Settings Integration**: Integrated into app settings
- **Mobile-Optimized**: Touch-friendly interface with haptic feedback
- **Sheet Presentations**: Modal presentations for model selection

### macOS (Petals)
- **Desktop Experience**: Optimized for mouse and keyboard interaction
- **Window Management**: Proper window sizing and navigation
- **Menu Integration**: Integrated into app menus and toolbars
- **Visual Effects**: Native macOS visual effects and materials

## 🔧 Available Models

The system supports multiple MLX models with different sizes and capabilities:

### Regular Models
- **Llama 3.2 1B (4-bit)**: ~0.7GB - Compact and fast
- **Llama 3.2 3B (4-bit)**: ~1.8GB - Balanced performance (default)
- **Meta Llama 3.1 8B (4-bit)**: Larger, more capable model

### Reasoning Models
- **DeepSeek R1 1.5B (4-bit)**: ~1.0GB - Reasoning-optimized
- **DeepSeek R1 1.5B (8-bit)**: ~1.9GB - Higher precision reasoning
- **DeepSeek R1 Llama 8B (4-bit)**: Large reasoning model

## 🚀 Usage

### For Users

1. **Select MLX Mode**: Toggle to "MLX (Local)" in settings
2. **Choose Model**: Select from available models in the picker
3. **Download**: If not available, initiate download with progress tracking
4. **Use**: Once downloaded, the model is ready for local inference
5. **Manage**: Delete models or check storage usage in settings

### For Developers

```swift
// Get the shared model manager
let modelManager = MLXModelManager.shared

// Check if a model is available
if modelManager.isModelAvailable(model) {
    // Use the model
} else {
    // Download the model
    await modelManager.downloadModel(model)
}

// Monitor download progress
if let progress = modelManager.activeDownloads[modelId] {
    print("Progress: \(progress.percentage * 100)%")
}
```

## 💡 Benefits

### For Users
- **Offline Capability**: Run AI models without internet connection
- **Privacy**: All inference happens locally on device
- **Performance**: No network latency for model responses
- **Control**: Full control over which models to download and use
- **Transparency**: Clear information about model sizes and requirements

### For Developers
- **Modular Design**: Easy to extend with new models
- **Clean Architecture**: Separation of concerns with clear interfaces
- **Reusable Components**: UI components can be reused across the app
- **Error Handling**: Robust error handling and recovery
- **Testing**: Easy to test with mocked dependencies

## 🔮 Future Enhancements

- **Model Updates**: Automatic checking for model updates
- **Model Recommendations**: Suggest models based on device capabilities
- **Batch Operations**: Download multiple models simultaneously
- **Model Compression**: On-device model compression options
- **Usage Analytics**: Track model usage and performance metrics
- **Cloud Sync**: Sync model preferences across devices

## 🤝 Integration Points

The MLX Model Management system integrates seamlessly with:

- **ConversationViewModel**: Automatic model switching and fallback
- **ConcreteCoreModelContainer**: Model availability validation
- **Settings Views**: Native settings integration on both platforms
- **Chat Interface**: Real-time model status in chat header
- **Error Handling**: Graceful error handling throughout the app

This system provides a production-ready, user-friendly way to manage MLX models with beautiful UI and robust architecture.
