//
//  File.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import Foundation
import PetalCore

/// Protocol for tools that can be used with Ollama.
public protocol MLXCompatibleTool: PetalTool {
    /// Returns the MLX tool definition for this tool.
    func asMLXToolDefinition() -> MLXToolDefinition
}

