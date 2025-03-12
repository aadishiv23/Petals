//
//  File.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/10/25.
//

import Foundation

public enum PetalToolPermission: Int, Codable, Comparable, Sendable {
    case basic = 0
    case standard = 1
    case sensitive = 2
    case administrative = 3

    static public func < (lhs: PetalToolPermission, rhs: PetalToolPermission) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Converts permission to a human-readable string.
    public func toString() -> String {
        switch self {
            case .basic: return "basic"
            case .standard: return "standard"
            case .sensitive: return "sensitive"
            case .administrative: return "administrative"
        }
    }
}
