//
//  File.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 3/25/25.
//

import Foundation
import MLXLMCommon
import PetalCore

extension ModelConfiguration {

    /// The type of model available.
    public enum ModelType {
        case regular
        case reasoning
    }

    public var modelType: ModelType {
        switch self {
        case .deepseek_r1_distill_qwen_1_5b_4bit: .reasoning
        case .deepseek_r1_distill_qwen_1_5b_8bit: .reasoning
        default: .regular
        }
    }
}

extension ModelConfiguration: @retroactive Equatable {
    public static func == (lhs: MLXLMCommon.ModelConfiguration, rhs: MLXLMCommon.ModelConfiguration) -> Bool {
        lhs.name == rhs.name
    }
    
    /// Convenience property to get a string representation of the model ID for use as dictionary keys
    public var idString: String {
        switch id {
        case .id(let stringId):
            return stringId
        case .directory(let url):
            return url.path
        }
    }

    public static let llama_3_2_1b_4bit = ModelConfiguration(
        id: "mlx-community/Llama-3.2-1B-Instruct-4bit"
    )

    public static let llama_3_2_3b_4bit = ModelConfiguration(
        id: "mlx-community/Llama-3.2-3B-Instruct-4bit"
    )

    public static let llama_3_1_8b_4bit = ModelConfiguration(
        id: "mlx-community/Meta-Llama-3.1-8B-Instruct-4bit"
    )

    public static let deepseek_r1_distill_qwen_1_5b_4bit = ModelConfiguration(
        id: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B-4bit"
    )

    public static let deepseek_r1_distill_qwen_1_5b_8bit = ModelConfiguration(
        id: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B-8bit"
    )

    public static let deepseek_r1_distill_llama_8b_4bit = ModelConfiguration(
        id: "mlx-community/DeepSeek-R1-Distill-Llama-8B-4bit"
    )

    public static let availableModels: [ModelConfiguration] = [
        llama_3_2_1b_4bit,
        llama_3_2_3b_4bit,
        llama_3_1_8b_4bit,
        deepseek_r1_distill_qwen_1_5b_4bit,
        deepseek_r1_distill_qwen_1_5b_8bit,
        deepseek_r1_distill_llama_8b_4bit
    ]

    public static var defaultModel: ModelConfiguration {
        llama_3_2_3b_4bit
        // deepseek_r1_distill_llama_8b_4bit
    }

    public static func getModelByName(_ name: String) -> ModelConfiguration? {
        if let model = availableModels.first(where: { $0.name == name }) {
            return model
        } else {
            return nil
        }
    }

    /// Builds the prompt history using a system prompt and an array of ChatMessages.
    /// - Parameters:
    ///   - messages: An array of ChatMessage instances.
    ///   - systemPrompt: The system prompt to prepend.
    /// - Returns: An array of dictionaries formatted for the MLX model.
    func getPromptHistory(from messages: [ChatMessage], systemPrompt: String) -> [[String: String]] {
        var history: [[String: String]] = []

        // Add the system prompt first.
        history.append([
            "role": "system",
            "content": systemPrompt
        ])

        // Append all messages from the conversation.
        for message in messages {
            history.append([
                "role": message.participant.stringValue,
                "content": message.message
            ])
        }
        return history
    }

    /// For models with reasoning, add a space and remove think-tags.
    func formatForTokenizer(_ message: String) -> String {
        if modelType == .reasoning {
            return " " + message
                .replacingOccurrences(of: "<think>", with: "Start thinking")
                .replacingOccurrences(of: "</think>", with: "End thinking")
        }
        return message
    }

    /// Returns an approximate model size in GB.
    public var modelSize: Decimal? {
        switch self {
        case .llama_3_2_1b_4bit: 0.7
        case .llama_3_2_3b_4bit: 1.8
        case .deepseek_r1_distill_qwen_1_5b_4bit: 1.0
        case .deepseek_r1_distill_qwen_1_5b_8bit: 1.9
        default: nil
        }
    }
}
