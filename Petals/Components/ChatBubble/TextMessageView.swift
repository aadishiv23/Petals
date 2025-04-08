//
//  TextMessageView.swift
//  Petals
//
//  Created for ChatBubbleView
//

import Foundation
import PetalCore
import SwiftUI

struct TextMessageView: View {
    let message: ChatMessage
    let bubbleColor: Color
    let textColor: Color

    var body: some View {
        Text(message.message)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .foregroundColor(textColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(BubbleShape(isUser: message.participant == .user).fill(bubbleColor))
            .contextMenu {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message.message, forType: .string)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
    }
} 

// A specialized view for streaming text content
struct StreamingTextMessageView: View {
    let message: ChatMessage
    let bubbleColor: Color
    let textColor: Color
    
    // Force redraw with timer
    @StateObject private var timer = StreamingTextTimer()
    
    // Track state for animation
    @State private var displayedText: String = ""
    @State private var lastLength: Int = 0
    @State private var refreshToken = UUID()
    
    var body: some View {
        Text(displayedText)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .foregroundColor(textColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(BubbleShape(isUser: message.participant == .user).fill(bubbleColor))
            .id("streaming-\(message.id)-\(refreshToken)")
            .contextMenu {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message.message, forType: .string)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
            .onAppear {
                // Initialize with current text
                displayedText = message.message
                lastLength = message.message.count
                timer.start()
            }
            .onDisappear {
                timer.stop()
            }
            // This is crucial - update our local state on timer ticks
            .onReceive(timer.timerPublisher) { _ in
                if displayedText != message.message {
                    displayedText = message.message
                    refreshToken = UUID() // Force view refresh
                }
            }
            // Also update when message changes
            .onChange(of: message.message) { newValue in
                if lastLength != newValue.count {
                    displayedText = newValue
                    lastLength = newValue.count
                    refreshToken = UUID() // Force view refresh
                }
            }
    }
}

// Timer to force UI updates at regular intervals
class StreamingTextTimer: ObservableObject {
    private var timer: Timer?
    @Published private var tick = 0
    
    var timerPublisher: Published<Int>.Publisher { $tick }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.tick += 1
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
