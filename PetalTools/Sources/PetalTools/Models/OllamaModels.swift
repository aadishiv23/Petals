//
//  OllamaModels.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/17/25.
//

import Foundation

// MARK: - Ollama Data Models

/// Represents a request to the Ollama chat API.
public struct OllamaChatRequest: Codable {
    /// The name of the model to use.
    public let model: String
    
    /// The conversation history, including the latest user message.
    public let messages: [OllamaChatMessage]
    
    /// Whether the response should be streamed or returned in a single request.
    public let stream: Bool
    
    /// A list of tools available for function calling, if any.
    public let tools: [OllamaTool]?
    
    /// Additional options for configuring the request.
    public let options: OllamaChatRequestOptions
    
    // Custom initializer
    public init(
        model: String,
        messages: [OllamaChatMessage],
        stream: Bool,
        tools: [OllamaTool]?,
        options: OllamaChatRequestOptions
    ) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.tools = tools
        self.options = options
    }
    
    // CodingKeys
    private enum CodingKeys: String, CodingKey {
        case model
        case messages
        case stream
        case tools
        case options
    }
    
    // Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.model = try container.decode(String.self, forKey: .model)
        self.messages = try container.decode([OllamaChatMessage].self, forKey: .messages)
        self.stream = try container.decode(Bool.self, forKey: .stream)
        self.tools = try container.decodeIfPresent([OllamaTool].self, forKey: .tools)
        self.options = try container.decode(OllamaChatRequestOptions.self, forKey: .options)
    }
    
    // Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(messages, forKey: .messages)
        try container.encode(stream, forKey: .stream)
        try container.encode(tools, forKey: .tools)
        try container.encode(options, forKey: .options)
    }
}

/// Contains options for configuring the chat request.
public struct OllamaChatRequestOptions: Codable {
    /// The number of tokens the model should retain as context.
    public let num_ctx: Int
    
    // Custom initializer
    public init(num_ctx: Int) {
        self.num_ctx = num_ctx
    }
    
    // CodingKeys
    private enum CodingKeys: String, CodingKey {
        case num_ctx
    }
    
    // Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.num_ctx = try container.decode(Int.self, forKey: .num_ctx)
    }
    
    // Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(num_ctx, forKey: .num_ctx)
    }
}

/// Represents a response from the Ollama chat API.
public struct OllamaChatResponse: Codable {
    /// The message returned by the assistant.
    public let message: OllamaChatMessage?
    
    /// Whether the response has finished processing.
    public let done: Bool
    
    // Custom initializer
    public init(message: OllamaChatMessage?, done: Bool) {
        self.message = message
        self.done = done
    }
    
    // CodingKeys
    private enum CodingKeys: String, CodingKey {
        case message
        case done
    }
    
    // Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decodeIfPresent(OllamaChatMessage.self, forKey: .message)
        self.done = try container.decode(Bool.self, forKey: .done)
    }
    
    // Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
        try container.encode(done, forKey: .done)
    }
}

/// Represents a message in the chat conversation.
public struct OllamaChatMessage: Codable {
    /// The role of the sender (`user`, `assistant`, or `tool`).
    public let role: String
    
    /// The textual content of the message (if applicable).
    public let content: String?
    
    /// Any tool calls requested by the assistant.
    public let tool_calls: [OllamaToolCall]?
    
    // Custom initializer
    public init(role: String, content: String?, tool_calls: [OllamaToolCall]?) {
        self.role = role
        self.content = content
        self.tool_calls = tool_calls
    }
    
    // CodingKeys
    private enum CodingKeys: String, CodingKey {
        case role
        case content
        case tool_calls
    }
    
    // Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.role = try container.decode(String.self, forKey: .role)
        self.content = try container.decodeIfPresent(String.self, forKey: .content)
        self.tool_calls = try container.decodeIfPresent([OllamaToolCall].self, forKey: .tool_calls)
    }
    
    // Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encode(tool_calls, forKey: .tool_calls)
    }
}

/// Represents a tool call made by the model.
public struct OllamaToolCall: Codable {
    /// The function being called by the model.
    public let function: OllamaFunctionCall
    
    // Custom initializer
    public init(function: OllamaFunctionCall) {
        self.function = function
    }
    
    // CodingKeys
    private enum CodingKeys: String, CodingKey {
        case function
    }
    
    // Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.function = try container.decode(OllamaFunctionCall.self, forKey: .function)
    }
    
    // Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(function, forKey: .function)
    }
}

/// Represents the function call details requested by the model.
public struct OllamaFunctionCall: Codable {
    /// The name of the function being invoked.
    public let name: String
    
    /// The arguments provided for the function call.
    public let arguments: [String: AnyCodable]
    
    // Custom initializer
    public init(name: String, arguments: [String: AnyCodable]) {
        self.name = name
        self.arguments = arguments
    }
    
    // CodingKeys
    private enum CodingKeys: String, CodingKey {
        case name
        case arguments
    }
    
    // Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.arguments = try container.decode([String: AnyCodable].self, forKey: .arguments)
    }
    
    // Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(arguments, forKey: .arguments)
    }
}

/// Represents a tool available for function calling.
public struct OllamaTool: Codable {
    /// The type of the tool (e.g., "function").
    public let type: String
    
    /// The function details for this tool.
    public let function: OllamaFunction
    
    // Custom initializer
    public init(type: String, function: OllamaFunction) {
        self.type = type
        self.function = function
    }
    
    // CodingKeys
    private enum CodingKeys: String, CodingKey {
        case type
        case function
    }
    
    // Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.function = try container.decode(OllamaFunction.self, forKey: .function)
    }
    
    // Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(function, forKey: .function)
    }
}

/// Represents a function available for calling.
public struct OllamaFunction: Codable {
    /// The name of the function.
    public let name: String
    
    /// A brief description of what the function does.
    public let description: String
    
    /// The expected parameters for this function.
    public let parameters: OllamaFunctionParameters
    
    // Custom initializer
    public init(name: String, description: String, parameters: OllamaFunctionParameters) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
    
    // CodingKeys
    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case parameters
    }
    
    // Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.parameters = try container.decode(OllamaFunctionParameters.self, forKey: .parameters)
    }
    
    // Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(parameters, forKey: .parameters)
    }
}

/// Defines the expected parameters for a function call.
public struct OllamaFunctionParameters: Codable {
    /// The type of the parameter object (always `"object"`).
    public let type: String
    
    /// A dictionary mapping parameter names to their descriptions and types.
    public let properties: [String: OllamaFunctionProperty]
    
    /// A list of required parameters.
    public let required: [String]
    
    // Custom initializer
    public init(type: String, properties: [String: OllamaFunctionProperty], required: [String]) {
        self.type = type
        self.properties = properties
        self.required = required
    }
    
    // CodingKeys
    private enum CodingKeys: String, CodingKey {
        case type
        case properties
        case required
    }
    
    // Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.properties = try container.decode([String: OllamaFunctionProperty].self, forKey: .properties)
        self.required = try container.decode([String].self, forKey: .required)
    }
    
    // Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(properties, forKey: .properties)
        try container.encode(required, forKey: .required)
    }
}

/// Represents an individual function parameter.
public struct OllamaFunctionProperty: Codable {
    /// The data type of the parameter (e.g., `"string"`, `"integer"`).
    public let type: String
    
    /// A description of what the parameter represents.
    public let description: String
    
    // Custom initializer
    public init(type: String, description: String) {
        self.type = type
        self.description = description
    }
    
    // CodingKeys
    private enum CodingKeys: String, CodingKey {
        case type
        case description
    }
    
    // Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.description = try container.decode(String.self, forKey: .description)
    }
    
    // Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(description, forKey: .description)
    }
}

/// Represents the response from the Ollama model listing API.
public struct OllamaModelResponse: Codable {
    /// A list of available models.
    public let models: [OllamaModel]
    
    // Custom initializer
    public init(models: [OllamaModel]) {
        self.models = models
    }
    
    // CodingKeys
    private enum CodingKeys: String, CodingKey {
        case models
    }
    
    // Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.models = try container.decode([OllamaModel].self, forKey: .models)
    }
    
    // Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(models, forKey: .models)
    }
}

/// Represents a single model available in Ollama.
public struct OllamaModel: Codable {
    /// The name of the model.
    public let name: String
    
    // Custom initializer
    public init(name: String) {
        self.name = name
    }
    
    // CodingKeys
    private enum CodingKeys: String, CodingKey {
        case name
    }
    
    // Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
    }
    
    // Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
}
