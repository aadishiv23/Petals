//
//  PetalToolResultStatus.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/10/25.
//

import Foundation

/// An enumeration representing the status of a tool execution.
public enum PetalToolResultStatus: String, Codable {
    case success
    case failure
    case partialSuccess
    case partialFailure
    case needMoreInfo
}
