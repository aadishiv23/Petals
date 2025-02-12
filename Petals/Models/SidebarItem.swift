//
//  SidebarItem.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/12/25.
//

import Foundation

/// We define an enum for what the user selected in the sidebar
enum SidebarItem: Hashable {
    case home
    case chat(id: UUID)
}
