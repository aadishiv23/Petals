//
//  AIChatModel.swift
//  PetalCore
//
//  Created by Aadi Shiv Malhotra on 2/15/25.
//

import Foundation

@MainActor
public protocol AIChatModel {
    func sendMessageStream(_ text: String) -> AsyncThrowingStream<PetalMessageStreamChunk, Error>
    func sendMessage(_ text: String) async throws -> String
}

public enum AIModelOption: String, CaseIterable, Identifiable {
    case gemini = "Gemini"
    case ollama = "Ollama"
    case mlx = "MLX"

    public var id: String { rawValue }
}
