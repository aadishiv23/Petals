//
//  StringIdentifiable.swift
//  Petals
//
//  Created for ChatBubbleView
//

import Foundation

/// Extension to make String an Identifiable for sheet presentation
extension String: Identifiable {
    public var id: String { self }
} 