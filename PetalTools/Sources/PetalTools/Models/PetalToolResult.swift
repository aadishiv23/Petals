//
//  PetalToolResult.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/10/25.
//

import Foundation

/// An object returned as the result of a tool.
public struct PetalToolResult {
    
    /// The status of the tool execution.
    public let status: PetalToolStatus
    
    /// The data returned by the tool.
    public let data: [String: Codable]?
    
    /// The error message returned by the tool if execution of the tool has failed.
    public let error: String?
    
    /// The list of suggested follow-up actions that can potentially be taken to act upon the result of this tool.
    public let suggestedActions: [PetalSuggestedAction]?
}
