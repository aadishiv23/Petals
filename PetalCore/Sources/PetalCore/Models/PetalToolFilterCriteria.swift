//
//  File.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/10/25.
//

import Foundation

/// Criteria for filtering tools.
public struct PetalToolFilterCriteria: Sendable {

    /// Filter tools by domain.
    public let domain: String?

    /// Filter tools by keyword match.
    public let keyword: String?

    /// Filter tools by required permission level or lower.
    public let maxPermissionLevel: PetalToolPermission?
}
