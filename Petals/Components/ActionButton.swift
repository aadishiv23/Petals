////
////  ActionButton.swift
////  Petals
////
////  Created by Aadi Shiv Malhotra on 2/13/25.
////
//
//import Foundation
//import SwiftUI
//
//struct ActionButton: View {
//    let icon: String
//    let text: String
//    let color: Color
//
//    var body: some View {
//        VStack(spacing: 8) {
//            Image(systemName: icon)
//                .font(.system(size: 20))
//                .foregroundStyle(color)
//                .frame(width: 50, height: 50)
//                .background(color.opacity(0.3))
//                .clipShape(Circle())
//
//            Text(text)
//                .font(.system(size: 15))
//                .foregroundStyle(.primary)
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 12, style: .continuous)
//                .fill(Color(.windowBackgroundColor))
//        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 12)
//                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
//        )
//    }
//}
//
//#Preview {
//    ActionButton(
//        icon: "pencil",
//        text: "Write",
//        color: Color.blue
//    )
//}
