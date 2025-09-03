//
//  MobileGeminiChatView.swift
//  PetalsiOS
//
//  Created for iOS target
//

import PetalCore
import SwiftUI

struct MobileGeminiChatView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    @State private var userInput: String = ""
    @FocusState private var inputIsFocused: Bool
    @State private var showModelPicker = false
    @Namespace private var bottomID
    
    let platformBackgroundColor = Color(UIColor.secondarySystemBackground)
    
    var isUserInputEmpty: Bool {
        userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chatMessagesView
                inputBarView
            }
            .contentShape(Rectangle()) // 👈 Makes the whole VStack tappable
            .onTapGesture {
                inputIsFocused = false // 👈 Dismiss keyboard on background tap
            }
            .navigationTitle(conversationVM.currentChatTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showModelPicker) {
                navigationModelPickerView
            }
        }
    }
    
    // MARK: - Main View Components
    
    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(conversationVM.messages, id: \.self) { msg in
                        if msg.pending && conversationVM.isProcessingTool {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                toolLoadingView(for: msg)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                        removal: .opacity.combined(with: .scale(scale: 0.95))
                                    ))
                                    .id(msg)
                            }
                        } else if !msg.message.isEmpty {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                MobileChatBubbleView(message: msg)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                        removal: .opacity.combined(with: .scale(scale: 0.95))
                                    ))
                                    .id(msg)
                            }
                        }
                    }
                    
                    // Invisible spacer for scrolling
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            // Scroll when message count changes
            .onChange(of: conversationVM.messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
            // Also scroll when the content of the last message changes (for streaming)
            .onChange(of: conversationVM.messages.last?.message) { _ in
                scrollToBottom(proxy: proxy)
            }
            // Add this to prevent duplicate content after streaming completes
            .onChange(of: conversationVM.busy) { isBusy in
                if !isBusy && conversationVM.messages.last?.pending == true {
                    // When streaming ends, mark the message as not pending
                    // but don't add the complete text again
                    if let lastIndex = conversationVM.messages.indices.last {
                        conversationVM.messages[lastIndex].pending = false
                    }
                }
                scrollToBottom(proxy: proxy)
            }
            // Initial scroll when view appears
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    private var inputBarView: some View {
        ModernChatInputBar(
            text: $userInput,
            isFocused: $inputIsFocused,
            isLoading: conversationVM.busy,
            isEnabled: !conversationVM.busy,
            onSend: sendMessage,
            onModelPicker: { showModelPicker.toggle() }
        )
    }
    
    private var navigationModelPickerView: some View {
        NavigationStack {
            ModelPickerView(
                useMLX: $conversationVM.useMLX,
                selectedMLXModel: $conversationVM.selectedMLXModel
            )
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.4)])
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showModelPicker.toggle() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func toolLoadingView(for msg: ChatMessage) -> some View {
        EnhancedToolView(message: msg)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            proxy.scrollTo(bottomID, anchor: .bottom)
        }
    }
    
    private func sendMessage() {
        if !isUserInputEmpty {
            Task {
                let message = userInput
                userInput = ""
                inputIsFocused = false
                await conversationVM.sendMessage(message, streaming: true)
            }
        }
    }
}

struct EnhancedToolLoadingView: View {
    let msg: ChatMessage
    @State private var animationProgress: CGFloat = 0
    @State private var glowOpacity: Double = 0.5
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var gradientRotation: Double = 0
    
    private let gradientColors = [
        Color(hex: "5E5CE6"),
        Color(hex: "7875FF"),
        Color(hex: "A78BFA"),
        Color(hex: "7875FF"),
        Color(hex: "5E5CE6")
    ]
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MobileAvatar(participant: .llm)
                .offset(y: 2)
                .overlay(
                    Circle()
                        .stroke(Color(hex: "5E5CE6").opacity(0.3), lineWidth: 2)
                        .scaleEffect(pulseScale)
                        .opacity(glowOpacity)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                )
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseScale = 1.2
                        glowOpacity = 0.8
                    }
                }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Processing")
                    .font(.subheadline)
                    .foregroundColor(Color.secondary)
                    .padding(.horizontal, 2)
                
                // Tool processing indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: Color(hex: "5E5CE6").opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    // Fancy progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            Capsule()
                                .fill(Color(UIColor.systemGray5))
                                .frame(height: 6)
                                .padding(.horizontal, 4)
                            
                            // Animated gradient progress
                            Capsule()
                                .fill(
                                    AngularGradient(
                                        gradient: Gradient(colors: gradientColors),
                                        center: .center,
                                        angle: .degrees(gradientRotation)
                                    )
                                )
                                .frame(width: geometry.size.width * animationProgress, height: 6)
                                .padding(.horizontal, 4)
                                .shadow(color: Color(hex: "5E5CE6").opacity(0.3), radius: 3, x: 0, y: 0)
                        }
                    }
                    .frame(height: 20)
                    
                    // Processing particles
                    ZStack {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(Color(hex: "5E5CE6").opacity(0.5))
                                .frame(width: 4, height: 4)
                                .offset(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -10...10))
                                .rotationEffect(.degrees(Double(index) * 72 + rotationAngle))
                                .opacity(Double.random(in: 0.3...0.8))
                                .animation(
                                    Animation.easeInOut(duration: 1.2)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: rotationAngle
                                )
                        }
                    }
                    
                    // Floating icons representing processing
                    HStack(spacing: 20) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "5E5CE6"))
                            .rotationEffect(.degrees(rotationAngle))
                            .opacity(0.8)
                        
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "A78BFA"))
                            .offset(y: cos(animationProgress * .pi) * 5)
                            .opacity(0.8)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "7875FF"))
                            .scaleEffect(1.0 + sin(animationProgress * .pi) * 0.2)
                            .opacity(0.8)
                    }
                }
                .frame(height: 60)
                .frame(maxWidth: 240)
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            // Start animations
            withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                animationProgress = 1.0
                rotationAngle = 360
            }
            
            // Rotate gradient
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                withAnimation {
                    gradientRotation += 1
                }
            }
        }
    }
}
