////
////  OllamaModels.swift
////  Petals
////
////  Created by Aadi Shiv Malhotra on 2/17/25.
////
//
//import Foundation
//
//// MARK: - Ollama Data Models
//
///// Represents a request to the Ollama chat API.
//struct OllamaChatRequest: Codable {
//    /// The name of the model to use.
//    let model: String
//    
//    /// The conversation history, including the latest user message.
//    let messages: [OllamaChatMessage]
//    
//    /// Whether the response should be streamed or returned in a single request.
//    let stream: Bool
//    
//    /// A list of tools available for function calling, if any.
//    let tools: [OllamaTool]?
//    
//    /// Additional options for configuring the request.
//    let options: OllamaChatRequestOptions
//}
//
///// Contains options for configuring the chat request.
//struct OllamaChatRequestOptions: Codable {
//    /// The number of tokens the model should retain as context.
//    let num_ctx: Int
//}
//
///// Represents a response from the Ollama chat API.
//struct OllamaChatResponse: Codable {
//    /// The message returned by the assistant.
//    let message: OllamaChatMessage?
//    
//    /// Whether the response has finished processing.
//    let done: Bool
//}
//
///// Represents a message in the chat conversation.
//struct OllamaChatMessage: Codable {
//    /// The role of the sender (`user`, `assistant`, or `tool`).
//    let role: String
//    
//    /// The textual content of the message (if applicable).
//    let content: String?
//    
//    /// Any tool calls requested by the assistant.
//    let tool_calls: [OllamaToolCall]?
//}
//
///// Represents a tool call made by the model.
//struct OllamaToolCall: Codable {
//    /// The function being called by the model.
//    let function: OllamaFunctionCall
//}
//
///// Represents the function call details requested by the model.
//struct OllamaFunctionCall: Codable {
//    /// The name of the function being invoked.
//    let name: String
//    
//    /// The arguments provided for the function call.
//    let arguments: [String: AnyCodable]
//}
//
///// Represents a tool available for function calling.
//struct OllamaTool: Codable {
//    /// The type of the tool (e.g., "function").
//    let type: String
//    
//    /// The function details for this tool.
//    let function: OllamaFunction
//}
//
///// Represents a function available for calling.
//struct OllamaFunction: Codable {
//    /// The name of the function.
//    let name: String
//    
//    /// A brief description of what the function does.
//    let description: String
//    
//    /// The expected parameters for this function.
//    let parameters: OllamaFunctionParameters
//}
//
///// Defines the expected parameters for a function call.
//struct OllamaFunctionParameters: Codable {
//    /// The type of the parameter object (always `"object"`).
//    let type: String
//    
//    /// A dictionary mapping parameter names to their descriptions and types.
//    let properties: [String: OllamaFunctionProperty]
//    
//    /// A list of required parameters.
//    let required: [String]
//}
//
///// Represents an individual function parameter.
//struct OllamaFunctionProperty: Codable {
//    /// The data type of the parameter (e.g., `"string"`, `"integer"`).
//    let type: String
//    
//    /// A description of what the parameter represents.
//    let description: String
//}
//
///// Represents the response from the Ollama model listing API.
//struct OllamaModelResponse: Codable {
//    /// A list of available models.
//    let models: [OllamaModel]
//}
//
///// Represents a single model available in Ollama.
//struct OllamaModel: Codable {
//    /// The name of the model.
//    let name: String
//}
