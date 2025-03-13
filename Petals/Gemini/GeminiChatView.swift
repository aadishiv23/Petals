//
//  GeminiChatView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/12/25.
//

import Foundation
import SwiftUI

struct GeminiChatView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    @State private var userInput: String = ""
    @State private var showSettings: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header with model selector
            HStack {
                Text("Petals")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .padding(.leading)
                
                Spacer()
                
                ModelToggle(isOn: $conversationVM.useOllama)
                    .padding(.trailing)
            }
            .padding(.vertical, 10)
            .background(
                VisualEffectView(material: .headerView, blendingMode: .behindWindow)
            )
            
            // Chat area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(conversationVM.messages, id: \.self) { msg in
                            if msg.pending, conversationVM.isProcessingTool {
                                withAnimation {
                                    toolLoadingView(for: msg)
                                }
                            } else {
                                withAnimation {
                                    ChatBubbleView(message: msg)
                                        .id(msg)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
                .padding(.vertical, 10)
                .background(
                    VisualEffectView(material: .headerView, blendingMode: .behindWindow)
                )
                .onChange(of: conversationVM.messages.count) { _ in
                    if let lastMessage = conversationVM.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage, anchor: .bottom)
                        }
                    }
                }
            }

            // Input area
            ChatInputBar(userInput: $userInput) {
                Task {
                    let text = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else {
                        return
                    }
                    userInput = ""
                    await conversationVM.sendMessage(text, streaming: true)
                }
            }
        }
    }

    private func toolLoadingView(for msg: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Avatar(participant: .llm)
                .offset(y: 2)

            ToolProcessingView()
                .id(msg)
            Spacer()
        }
    }

}

// MARK: - Supporting Views

struct ModelToggle: View {
    @Binding var isOn: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "desktopcomputer" : "cloud")
                    .font(.system(size: 12))

                Text(isOn ? "Ollama" : "Gemini API")
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "5E5CE6")))
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    colorScheme == .dark
                        ? Color(NSColor.controlBackgroundColor)
                        : Color(NSColor.controlBackgroundColor).opacity(0.8)
                )
        )
    }
}

// MARK: - Helper Views

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
