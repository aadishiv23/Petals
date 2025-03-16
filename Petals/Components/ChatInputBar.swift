//
//  ChatInputBar.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import SwiftUI

/// A SwiftUI view representing the chat input bar.
/// This view supports dynamic height adjustment, placeholder display, and
/// sends messages either by pressing the send button or the Enter key.
struct ChatInputBar: View {
    /// A binding to the text entered by the user.
    @Binding var userInput: String
    /// Closure that sends the trimmed message.
    var sendMessage: (String) -> Void
    
    // MARK: - UI Constants
    
    /// The font used for the text editor.
    private let font: Font = .body
    /// The spacing between lines in the text editor.
    private let lineSpacing: CGFloat = 4
    /// The minimum height of the text editor (approx. one line).
    private let minHeight: CGFloat = 36
    /// The maximum height of the text editor before scrolling becomes enabled.
    private let maxHeight: CGFloat = 150
    
    // MARK: - State
    
    /// Tracks the current height of the text editor.
    @State private var textHeight: CGFloat = 36
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Text input area with a placeholder.
            ZStack(alignment: .leading) {
                if userInput.isEmpty {
                    Text("Message")
                        .font(font)
                        .foregroundColor(.secondary)
                        .padding(.leading, 5)
                        .padding(.top, 8)
                        .allowsHitTesting(false) // So that it doesn't intercept taps.
                }
                
                // A TextEditor with dynamic height.
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
                        // Limit the height between the minimum and maximum.
                        let calculatedHeight = min(max(height, minHeight), maxHeight)
                        if abs(calculatedHeight - textHeight) > 2 {
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
            
            // Send Button.
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
        // Listen for Enter key press notifications to trigger send.
        .onReceive(NSEvent.pressedEnter) { _ in
            sendAndClear()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns the current height for the TextEditor.
    private func calculateHeight() -> CGFloat {
        return textHeight
    }
    
    /// Trims the user input, sends the message if not empty, and resets the input.
    private func sendAndClear() {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Send the message using the provided closure.
        sendMessage(trimmed)
        // Clear the input field and reset the text editor height.
        userInput = ""
        textHeight = minHeight
    }
}

/// A preference key to capture the height of a view.
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - NSEvent and NSApplication Extensions for Enter Key Handling

extension NSEvent {
    /// A publisher that emits events when the Enter key is pressed without Shift.
    static var pressedEnter: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: NSEvent.didPressEnter)
    }
    
    /// Notification posted when the Enter key (without Shift) is pressed.
    static let didPressEnter = Notification.Name("didPressEnter")
}

extension NSApplication {
    /// Sets up a local monitor for keyDown events to detect when the Enter key is pressed.
    /// This should be called early in your app's lifecycle (for example, in the app delegate).
    static func setupEnterKeyListener() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Key code 36 corresponds to the Return/Enter key.
            if event.keyCode == 36 && !event.modifierFlags.contains(.shift) {
                NotificationCenter.default.post(name: NSEvent.didPressEnter, object: nil)
                return nil // Prevent the default behavior.
            }
            return event
        }
    }
}
