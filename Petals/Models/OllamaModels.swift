//
//  OllamaModels.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/17/25.
//

import Foundation

struct OllamaChatMessage: Codable {
    let role: String
    let content: String
}

struct OllamaChatRequestOptions: Codable {
    let num_ctx: Int
}

struct OllamaChatRequest: Codable {
    let model: String
    let messages: [OllamaChatMessage]
    let stream: Bool?
    let options: OllamaChatRequestOptions?
}

struct OllamaChatResponse: Codable {
    let message: OllamaChatMessage?
    let done: Bool
}

struct OllamaModelResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable {
    let name: String
}
