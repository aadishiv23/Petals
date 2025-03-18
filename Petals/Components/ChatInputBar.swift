//
//  ChatInputBar.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

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
    
    // MARK: - Environment
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Text input area with a placeholder.
            ZStack(alignment: .leading) {
                if userInput.isEmpty {
                    Text("Message")
                        .font(font)
                        .foregroundColor(.secondary) // Adaptive placeholder color
                        .padding(.leading, 5)
                        .padding(.bottom, 10)
                        .allowsHitTesting(false)
                }
                
                // TextEditor with dynamic height
                TextEditor(text: $userInput)
                    .font(font)
                    .lineSpacing(lineSpacing)
                    .frame(height: calculateHeight())
                    .foregroundColor(.primary) // Adaptive text color
                    // For iOS 16 and later, hides the background while scrolling
                    .scrollContentBackground(.hidden)
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
                        if abs(calculatedHeight - textHeight) > 2 {
                            self.textHeight = calculatedHeight
                        }
                    }
            }
            .padding(.trailing, 40) // Make room for the button
            
            // Send Button
            withAnimation {
                Button(action: sendAndClear) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                      Color.secondary.opacity(0.3) : Color.blue)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.trailing, 5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        // A background that’s not pure black or white in either mode
        .background(
            colorScheme == .dark
            ? Color(white: 0.15, opacity: 0.9)
            : Color(white: 0.95, opacity: 0.9)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(colorScheme == .dark
                        ? Color.gray.opacity(0.2)
                        : Color.gray.opacity(0.3),
                        lineWidth: 0.5)
        )
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
