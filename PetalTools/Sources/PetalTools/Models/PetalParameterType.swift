//
//  File.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/10/25.
//

import Foundation

/// Represents the type of a parameter.
public enum PetalParameterType: String, Codable {
    case string
    case number
    case boolean
    case date
    case object
    case array
    case json
    case enumeration
}
