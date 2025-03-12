//
//  PetalSuggestedAction.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/10/25.
//

import Foundation

/// A suggested follow-up action to a tool call.
public struct PetalSuggestedAction: Codable {
    
    /// The title of the suggested action.
    public let title: String
    
    /// The description of the suggested action.
    public let description: String
    
    /// The tool to execute as a suggested action.
    public let toolId: String
    
    /// The pre-filled parameters for the suggested action.
    public let parameters: [String: AnyCodable]?
}
