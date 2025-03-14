//
//  ChatInputBar.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import SwiftUI

struct ChatInputBar: View {
    @Binding var userInput: String
    var sendMessage: () -> Void
    
    // Text Style
    private let font: Font = .body
    private let lineSpacing: CGFloat = 4
    private let minHeight: CGFloat = 36  // 1-line height with padding
    private let maxHeight: CGFloat = 150 // max height before scrolling
    
    // Track measured text height
    @State private var textHeight: CGFloat = 36
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Simple TextEditor approach - more reliable
            ZStack(alignment: .leading) {
                // Placeholder text
                if userInput.isEmpty {
                    Text("Message")
                        .font(font)
                        .foregroundColor(.secondary)
                        .padding(.leading, 5)
                        .padding(.top, 8)
                        .allowsHitTesting(false) // Make sure it doesn't block input
                }
                
                // Regular TextEditor with dynamic height
                TextEditor(text: $userInput)
                    .font(font)
                    .lineSpacing(lineSpacing)
                    .frame(height: calculateHeight())
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ViewHeightKey.self,
                                value: geo.frame(in: .local).size.height
                            )
                        }
                    )
                    .onPreferenceChange(ViewHeightKey.self) { height in
                        let calculatedHeight = min(max(height, minHeight), maxHeight)
                        if abs(calculatedHeight - textHeight) > 2 { // Only update if significant change
                            self.textHeight = calculatedHeight
                        }
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.textBackgroundColor).opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            
            // Send Button
            Button(action: sendAndClear) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
                    .foregroundColor(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray.opacity(0.5) : .blue)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .animation(.easeInOut(duration: 0.2), value: userInput.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.windowBackgroundColor))
        .animation(.easeOut(duration: 0.2), value: textHeight)
    }
    
    private func calculateHeight() -> CGFloat {
        return textHeight
    }
    
    private func sendAndClear() {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        sendMessage()
        userInput = ""
        textHeight = minHeight // Reset height after sending
    }
}

// Simple preference key to track view height
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Extension to handle Enter key presses globally
extension NSEvent {
    static var pressedEnter: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: NSEvent.didPressEnter)
    }
    
    static let didPressEnter = Notification.Name("didPressEnter")
}

extension NSApplication {
    static func setupEnterKeyListener() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 36 && !event.modifierFlags.contains(.shift) {  // Return/Enter without Shift
                NotificationCenter.default.post(name: NSEvent.didPressEnter, object: nil)
                return nil // Prevents default behavior
            }
            return event
        }
    }
}
