//
//  ModernChatInputBar.swift
//  PetalsiOS
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import SwiftUI

// MARK: - Modern Chat Input Bar

struct ModernChatInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let isLoading: Bool
    let isEnabled: Bool
    let onSend: () -> Void
    let onStop: () -> Void
    let onModelPicker: () -> Void
    
    @State private var textHeight: CGFloat = 20
    @State private var showingPlaceholder = true
    @State private var sendButtonScale: CGFloat = 1.0
    
    private let accentColor = Color(hex: "5E5CE6")
    private let maxHeight: CGFloat = 100
    private let minHeight: CGFloat = 44
    private let cornerRadius: CGFloat = 22 // Half of minHeight for proper pill shape
    private let singleLineHeight: CGFloat = 20
    
    private var isTextEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var shouldShowSendButton: Bool {
        !isTextEmpty && isEnabled
    }
    
    // Dynamic corner radius based on height
    private var dynamicCornerRadius: CGFloat {
        let currentHeight = max(minHeight, min(textHeight + 24, maxHeight))
        // Keep it pill-shaped when at min height, transition to rounded rect as it grows
        return currentHeight <= minHeight + 4 ? cornerRadius : min(cornerRadius, 16)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            inputContainer
            actionButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            // Subtle background for the entire input area
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground).opacity(0.01))
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: textHeight)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: shouldShowSendButton)
        .onChange(of: text) { _ in
            updatePlaceholderVisibility()
            updateTextHeight()
        }
        .onAppear {
            // Initialize with single line height
            textHeight = singleLineHeight
        }
    }
    
    // MARK: - Components
    
    private var inputContainer: some View {
        HStack(alignment: .center, spacing: 8) {
            modelPickerButton
            textInputArea
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: dynamicCornerRadius)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: dynamicCornerRadius)
                        .stroke(
                            isFocused ? accentColor.opacity(0.3) : Color(.separator).opacity(0.3),
                            lineWidth: isFocused ? 1.5 : 0.5
                        )
                )
                .shadow(
                    color: isFocused ? accentColor.opacity(0.1) : .clear,
                    radius: isFocused ? 8 : 0,
                    x: 0,
                    y: 0
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var modelPickerButton: some View {
        Button(action: {
            impactFeedback()
            onModelPicker()
        }) {
            Image(systemName: "gear")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var textInputArea: some View {
        ZStack(alignment: .topLeading) {
            // Custom placeholder
            if showingPlaceholder {
                Text("Message")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 16))
                    .padding(.leading, 6)
                    .padding(.top, 16)
                    .allowsHitTesting(false)
            }
            
            // Text editor with proper sizing
            TextEditor(text: $text)
                .focused($isFocused)
                .font(.system(size: 16))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: singleLineHeight, maxHeight: maxHeight)
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .fixedSize(horizontal: false, vertical: true)
                .onSubmit {
                    if !isTextEmpty {
                        sendMessage()
                    }
                }
        }
    }
    
    private var actionButton: some View {
        Group {
            if isLoading {
                stopButton
            } else {
                sendButton
            }
        }
    }
    
    private var sendButton: some View {
        Button(action: sendMessage) {
            Image(systemName: shouldShowSendButton ? "arrow.up.circle.fill" : "arrow.up.circle")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(
                    shouldShowSendButton ?
                    accentColor :
                    Color(.tertiaryLabel)
                )
                .scaleEffect(sendButtonScale)
        }
        .disabled(!shouldShowSendButton)
        .buttonStyle(ScaleButtonStyle())
        .frame(width: 44, height: 44)
    }
    
    private var stopButton: some View {
        Button(action: {
            impactFeedback()
            onStop()
        }) {
            Image(systemName: "stop.circle.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.primary)
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(width: 44, height: 44)
    }
    
    // MARK: - Helper Methods
    
    private func sendMessage() {
        guard !isTextEmpty && isEnabled else { return }
        
        impactFeedback(.medium)
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            sendButtonScale = 0.9
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                sendButtonScale = 1.0
            }
        }
        
        onSend()
    }
    
    private func updateTextHeight() {
        if text.isEmpty {
            withAnimation(.easeOut(duration: 0.15)) {
                textHeight = singleLineHeight
            }
            return
        }
        
        let textToMeasure = text
        let constraintWidth = UIScreen.main.bounds.width - 140 // Account for padding and buttons
        
        let size = textToMeasure.boundingRect(
            with: CGSize(width: constraintWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.systemFont(ofSize: 16)],
            context: nil
        ).size
        
        let newHeight = max(singleLineHeight, size.height)
        
        if abs(newHeight - textHeight) > 2 {
            withAnimation(.easeOut(duration: 0.15)) {
                textHeight = newHeight
            }
        }
    }
    
    private func updatePlaceholderVisibility() {
        withAnimation(.easeInOut(duration: 0.15)) {
            showingPlaceholder = text.isEmpty
        }
    }
    
    private func impactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.impactOccurred()
    }
}

// MARK: - Custom Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    @State var text = ""
    @FocusState var isFocused: Bool
    
    return VStack {
        Spacer()
        ModernChatInputBar(
            text: $text,
            isFocused: $isFocused,
            isLoading: false,
            isEnabled: true,
            onSend: {
                print("Send: \(text)")
                text = ""
            },
            onStop: { print("Stop pressed") },
            onModelPicker: { print("Model Picker") }
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
