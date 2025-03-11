//
//  OllamaCompatibleTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/10/25.
//

import Foundation

/// Protocol for tools that can be used with Ollama.
protocol OllamaCompatibleTool: Tool {

    /// Convert this tool to Ollama's format.
    func asOllamaTool() -> OllamaTool
}
