//
//  ChatHistory.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import Foundation

// Represents a single saved chat in the sidebar
struct ChatHistory: Identifiable {
    let id: UUID = UUID()
    var title: String
}
