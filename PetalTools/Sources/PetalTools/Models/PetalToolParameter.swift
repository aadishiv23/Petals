//
//  File.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/10/25.
//

import Foundation

/// Represents a parameter for a tool.
public struct PetalToolParameter: Codable {

    /// The name of the parameter.
    public let name: String

    /// The description of the parameter.
    public let description: String

    /// The data-type of this parameter.
    public let dataType: PetalParameterType

    /// Whether this parameter is required for the tool to run.
    public let required: Bool

    /// Example value for documentation (supports any `Codable` type).
    public let example: Codable?

    /// Possible values (if this parameter is an enum).
    public let enumValues: [String]?

    /// Initializes a new `ToolParameter`.
    public init(
        name: String,
        description: String,
        dataType: PetalParameterType,
        required: Bool,
        example: Codable? = nil,
        enumValues: [String]? = nil
    ) {
        self.name = name
        self.description = description
        self.dataType = dataType
        self.required = required
        self.example = example
        self.enumValues = enumValues
    }
}
