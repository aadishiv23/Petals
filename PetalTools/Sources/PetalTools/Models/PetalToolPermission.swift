//
//  File.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/10/25.
//

import Foundation

public enum PetalToolPermission: Int, Codable, Comparable {
    public case basic = 0
    public case standard = 1
    public case sensitive = 2
    public case administrative = 3

    public static func < (lhs: PetalToolPermission, rhs: PetalToolPermission) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Converts permission to a human-readable string.
    public func toString() -> String {
        switch self {
            public case .basic: return "basic"
            public case .standard: return "standard"
            public case .sensitive: return "sensitive"
            public case .administrative: return "administrative"
        }
    }
}
