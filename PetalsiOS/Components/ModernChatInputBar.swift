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
    let onModelPicker: () -> Void
    
    @State private var textHeight: CGFloat = 44
    @State private var showingPlaceholder = true
    @State private var sendButtonScale: CGFloat = 1.0
    @State private var inputScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    
    private let accentColor = Color(hex: "5E5CE6")
    private let maxHeight: CGFloat = 120
    private let minHeight: CGFloat = 44
    
    private var isTextEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var shouldShowSendButton: Bool {
        !isTextEmpty && isEnabled
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main input container
            HStack(alignment: .bottom, spacing: 12) {
                modelPickerButton
                inputTextContainer
                actionButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                inputBackgroundView
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: textHeight)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: shouldShowSendButton)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
        .onChange(of: text) { _ in
            updatePlaceholderVisibility()
        }
        .onChange(of: isFocused) { focused in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                glowOpacity = focused ? 0.3 : 0.0
                inputScale = focused ? 1.02 : 1.0
            }
        }
    }
    
    // MARK: - Input Components
    
    private var modelPickerButton: some View {
        Button(action: {
            impactFeedback()
            onModelPicker()
        }) {
            Image(systemName: "gearshape.2")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color(UIColor.separator), lineWidth: 0.5)
                        )
                )
                .scaleEffect(inputScale * 0.98)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var inputTextContainer: some View {
        ZStack(alignment: .topLeading) {
            // Background with dynamic height
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isFocused ? accentColor.opacity(0.5) : Color(UIColor.separator), lineWidth: isFocused ? 1.5 : 0.5)
                        .shadow(color: accentColor.opacity(glowOpacity), radius: 8, x: 0, y: 0)
                )
                .frame(height: max(minHeight, min(textHeight + 16, maxHeight)))
                .scaleEffect(inputScale)
            
            // Text input with placeholder
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    // Custom placeholder
                    if showingPlaceholder {
                        Text("Message")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .opacity(showingPlaceholder ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: showingPlaceholder)
                    }
                    
                    // Actual text field
                    TextEditor(text: $text)
                        .focused($isFocused)
                        .font(.system(size: 16))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minHeight: minHeight - 16)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(
                            // Height measurement
                            GeometryReader { geometry in
                                Color.clear.onAppear {
                                    updateTextHeight(geometry.size.height)
                                }
                                .onChange(of: text) { _ in
                                    DispatchQueue.main.async {
                                        updateTextHeight(geometry.size.height)
                                    }
                                }
                            }
                        )
                        .onSubmit {
                            if !isTextEmpty {
                                sendMessage()
                            }
                        }
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
        .frame(width: 32, height: 32)
    }
    
    private var sendButton: some View {
        Button(action: sendMessage) {
            Image(systemName: "arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(shouldShowSendButton ? .white : Color(UIColor.tertiaryLabel))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            shouldShowSendButton ? 
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) : 
                            LinearGradient(
                                colors: [Color(UIColor.systemGray4), Color(UIColor.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: shouldShowSendButton ? accentColor.opacity(0.3) : Color.clear, 
                            radius: shouldShowSendButton ? 6 : 0, 
                            x: 0, 
                            y: shouldShowSendButton ? 3 : 0
                        )
                )
                .scaleEffect(sendButtonScale)
                .opacity(shouldShowSendButton ? 1.0 : 0.6)
        }
        .disabled(!shouldShowSendButton)
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: shouldShowSendButton)
    }
    
    private var stopButton: some View {
        Button(action: {
            impactFeedback()
            // Stop functionality would go here
        }) {
            Image(systemName: "stop.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red, .red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .red.opacity(0.3), radius: 6, x: 0, y: 3)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var inputBackgroundView: some View {
        Rectangle()
            .fill(.clear)
    }
    
    // MARK: - Helper Methods
    
    private func sendMessage() {
        guard !isTextEmpty else { return }
        
        impactFeedback(.medium)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            sendButtonScale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                sendButtonScale = 1.0
            }
        }
        
        onSend()
    }
    
    private func updateTextHeight(_ height: CGFloat) {
        let newHeight = max(minHeight, min(height + 16, maxHeight))
        if abs(newHeight - textHeight) > 1 {
            textHeight = newHeight
        }
    }
    
    private func updatePlaceholderVisibility() {
        withAnimation(.easeInOut(duration: 0.2)) {
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
    
    return ModernChatInputBar(
        text: $text,
        isFocused: $isFocused,
        isLoading: false,
        isEnabled: true,
        onSend: { print("Send") },
        onModelPicker: { print("Model Picker") }
    )
    .background(Color(.systemGroupedBackground))
}
