//
//  MobileAvatar.swift
//  PetalsiOS
//
//  Created for iOS target
//

import SwiftUI
import PetalCore

struct MobileAvatar: View {
    let participant: ChatParticipant
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    participant == .user
                        ? Color(hex: "5E5CE6").opacity(0.2)
                        : Color(UIColor.secondarySystemBackground)
                )
                .frame(width: 32, height: 32)
            
            Image(systemName: participant == .user ? "person.fill" : "brain.head.profile")
                .font(.system(size: 16))
                .foregroundColor(
                    participant == .user
                        ? Color(hex: "5E5CE6")
                        : .gray
                )
        }
    }
} 