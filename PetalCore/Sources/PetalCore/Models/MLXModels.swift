//
//  File.swift
//  PetalCore
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import Foundation

/// Top-level MLX tool definition
public struct MLXToolDefinition: Codable, Sendable {
    public let type: String // e.g. "function"
    public let function: MLXFunctionDefinition

    public init(
        type: String,
        function: MLXFunctionDefinition
    ) {
        self.type = type
        self.function = function
    }

    /// CodingKeys
    private enum CodingKeys: String, CodingKey {
        case type
        case function
    }

    /// Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.function = try container.decode(MLXFunctionDefinition.self, forKey: .function)
    }

    /// Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(function, forKey: .function)
    }
}

/// Represents a function available for calling.
public struct MLXFunctionDefinition: Codable, Sendable {
    /// The name of the function.
    public let name: String

    /// A brief description of what the function does.
    public let description: String

    /// The expected parameters for this function.
    public let parameters: MLXParametersDefinition

    /// Custom initializer.
    public init(
        name: String,
        description: String,
        parameters: MLXParametersDefinition
    ) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }

    /// Coding keys.
    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case parameters
    }

    /// Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.parameters = try container.decode(MLXParametersDefinition.self, forKey: .parameters)
    }

    /// Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(parameters, forKey: .parameters)
    }
}

/// Defines the expected parameters for a function call.
public struct MLXParametersDefinition: Codable, Sendable {
    /// The type of the parameter object (always `"object"`).
    public let type: String // e.g. "object"

    /// A dictionary mapping parameter names to their descriptions and types.
    public let properties: [String: MLXParameterProperty]

    /// A list of required parameters.
    public let required: [String]

    /// Custom initializer.
    public init(
        type: String,
        properties: [String: MLXParameterProperty],
        required: [String]
    ) {
        self.type = type
        self.properties = properties
        self.required = required
    }

    /// CodingKeys
    private enum CodingKeys: String, CodingKey {
        case type
        case properties
        case required
    }

    /// Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.properties = try container.decode([String: MLXParameterProperty].self, forKey: .properties)
        self.required = try container.decode([String].self, forKey: .required)
    }

    /// Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(properties, forKey: .properties)
        try container.encode(required, forKey: .required)
    }
}

public struct MLXParameterProperty: Codable, Sendable {
    /// The data type of the parameter (e.g., `"string"`, `"integer"`).
    public let type: String

    /// A description of what the parameter represents.
    public let description: String

    /// Custom initializer
    public init(type: String, description: String) {
        self.type = type
        self.description = description
    }

    /// CodingKeys
    private enum CodingKeys: String, CodingKey {
        case type
        case description
    }

    /// Custom init(from:)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.description = try container.decode(String.self, forKey: .description)
    }

    /// Custom encode(to:)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(description, forKey: .description)
    }
}


extension MLXToolDefinition {
    public func toDictionary() -> [String: any Sendable] {
        // First, convert the "properties" dictionary.
        let propertiesDict: [String: [String: any Sendable]] = self.function.parameters.properties.mapValues { property in
            return [
                "type": property.type,
                "description": property.description
            ]
        }
        
        // Build the parameters dictionary.
        let parametersDict: [String: any Sendable] = [
            "type": self.function.parameters.type,
            "properties": propertiesDict,
            "required": self.function.parameters.required  // [String] is Sendable.
        ]
        
        // Build the function dictionary.
        let functionDict: [String: any Sendable] = [
            "name": self.function.name,
            "description": self.function.description,
            "parameters": parametersDict
        ]
        
        // Finally, build the outer dictionary.
        let outerDict: [String: any Sendable] = [
            "type": self.type,
            "function": functionDict
        ]
        
        return outerDict
    }
}
