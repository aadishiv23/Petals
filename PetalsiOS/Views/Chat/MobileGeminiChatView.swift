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
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(conversationVM.messages, id: \.self) { msg in
                                if msg.pending, conversationVM.isProcessingTool {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        toolLoadingView(for: msg)
                                            .transition(.asymmetric(
                                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                                removal: .opacity.combined(with: .scale(scale: 0.95))
                                            ))
                                            .id(msg)
                                    }
                                } else if let content = msg.message, !content.isEmpty {
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
                
                // Input bar (enhanced)
                HStack(alignment: .bottom, spacing: 0) {
                    // Model picker button
                    modelPickerButton
                    
                    // Text input field
                    chatInput
                }
                .padding()
            }
            .navigationTitle(conversationVM.currentChatTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showModelPicker) {
                NavigationStack {
                    ModelPickerView(useOllama: $conversationVM.useOllama)
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
        }
    }
    
    // MARK: - Components
    
    var modelPickerButton: some View {
        Button {
            // Add haptic feedback if available in your app
            showModelPicker.toggle()
        } label: {
            Image(systemName: "chevron.up")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16)
                .tint(.primary)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(platformBackgroundColor)
                )
        }
    }
    
    var chatInput: some View {
        HStack(alignment: .bottom, spacing: 0) {
            TextField("Message", text: $userInput, axis: .vertical)
                .focused($inputIsFocused)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 48)
                .onSubmit {
                    inputIsFocused = true
                    sendMessage()
                }
            
            if conversationVM.busy {
                stopButton
            } else {
                sendButton
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(platformBackgroundColor)
        )
    }
    
    var sendButton: some View {
        Button {
            sendMessage()
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(isUserInputEmpty ? .gray.opacity(0.5) : Color(hex: "5E5CE6"))
        }
        .disabled(isUserInputEmpty)
        .padding(.trailing, 12)
        .padding(.bottom, 12)
    }
    
    var stopButton: some View {
        Button {
            // Implement stop functionality if needed
            conversationVM.stop()
        } label: {
            Image(systemName: "stop.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(Color.red.opacity(0.8))
        }
        .padding(.trailing, 12)
        .padding(.bottom, 12)
    }
    
    // MARK: - Helper Methods
    
    private func toolLoadingView(for msg: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            MobileAvatar(participant: .llm)
                .offset(y: 2)
            
            // Enhanced loading animation
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color(hex: "5E5CE6").opacity(0.7))
                        .frame(width: 8, height: 8)
                        .offset(y: sin(Double(index) * 0.3) * 4)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: index
                        )
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            
            Spacer()
        }
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
                inputIsFocused = true
                await conversationVM.sendMessage(message, streaming: true)
            }
        }
    }
} 