//
//  DeviceStat.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/24/25.
//

import Foundation
import MLXLLM
import MLX
import Observation

@Observable
final class DeviceStat: @unchecked Sendable {
    
    /// The variable holding a snapshot of GPU memory state.
    @MainActor
    var gpuUsage = GPU.snapshot()
    
    private let initialGPUSnapshot = GPU.snapshot()
    
    private var timer: Timer?
    
    init() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateGPUUsages()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func updateGPUUsages() {
        let gpuSnapshotDelta = initialGPUSnapshot.delta(GPU.snapshot())
        DispatchQueue.main.async { [weak self] in
            self?.gpuUsage = gpuSnapshotDelta
        }
    }
}

