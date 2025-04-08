//
//  PetalsiOSApp.swift
//  PetalsiOS
//
//  Created by Aadi Shiv Malhotra on 4/2/25.
//

import SwiftUI
import PetalCore

@main
struct PetalsiOSApp: App {
    @StateObject private var conversationVM = ConversationViewModel()

    var body: some Scene {
        WindowGroup {
            MobileHomeView(
                conversationVM: conversationVM
            )
        }
    }
}

//
//  ChatHistory.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation

//  MobileChatListView.swift
//  Petals
//
//  Created for iOS target

import PetalCore
import SwiftUI


/// Mobile-friendly toggle for model selection
struct MobileModelToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "desktopcomputer" : "cloud")
                    .font(.system(size: 12))
                Text(isOn ? "MLX" : "Gemini API")
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "5E5CE6")))
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

//  MobileChatInputBar.swift
//  Petals
//
//  Created for iOS target

import SwiftUI

struct MobileChatInputBar: View {
    @Binding var userInput: String
    @FocusState var isFocused: Bool
    var onSend: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom) {
                // Text input field
                TextField("Message", text: $userInput, axis: .vertical)
                    .padding(10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(20)
                    .focused($isFocused)
                    .lineLimit(5)

                // Send button
                Button(action: {
                    if !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend(userInput)
                        userInput = ""
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(
                            userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.gray
                                : Color(hex: "5E5CE6")
                        )
                }
                .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
        }
    }
}

//  MobileChatBubbleView.swift
//  Petals
//
//  Created for iOS target

/// Tool processing view for mobile
struct MobileToolProcessingView: View {
    @State private var typingDots = 1

    var body: some View {
        Text(String(repeating: ".", count: typingDots))
            .font(.system(size: 24, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(Color.secondary)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) {
                    typingDots = (typingDots % 3) + 1
                }
            }
    }
}

//
//  ToolTriggerEvaluator.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/17/25.
//

import Foundation
import NaturalLanguage

/// Eveluates whether a tool should be triggered based on semantic similarity.
struct ToolTriggerEvaluator {
    let embedding: NLEmbedding

    init() {
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
            fatalError("English Embedding not availalble")
        }
        self.embedding = embedding
    }

    /// Returns a vector for the given text. First, attempts to retrieve the vector directly.
    /// If that fails, splits the text into words and averages their vectors.
    func vector(for text: String) -> [Double]? {
        // Try the full string first.
        if let fullVector = embedding.vector(for: text.lowercased()) {
            return fullVector
        }

        // Fallback: Tokenize and average the vectors for individual words.
        let tokens = text.lowercased().split(separator: " ").map { String($0) }
        var sumVector: [Double] = []
        var validCount = 0

        for token in tokens {
            if let tokenVector = embedding.vector(for: token) {
                if sumVector.isEmpty {
                    sumVector = tokenVector
                } else {
                    for i in 0..<min(sumVector.count, tokenVector.count) {
                        sumVector[i] += tokenVector[i]
                    }
                }
                validCount += 1
            }
        }

        guard validCount > 0 else {
            return nil
        }
        return sumVector.map { $0 / Double(validCount) }
    }

    /// Computes the centroid (prototype) vector for a set of exemplar phrases.
    /// - Parameter exemplars: An array of exemplar trigger phrases for a tool.
    /// - Returns: A vector representing the averaged (centroid) embedding, or nil if none could be computed.
    func prototype(for exemplars: [String]) -> [Double]? {
        var sum: [Double] = []
        var count = 0

        for exemplar in exemplars {
            if let vector = vector(for: exemplar) {
                if sum.isEmpty {
                    sum = vector
                } else {
                    for i in 0..<min(sum.count, vector.count) {
                        sum[i] += vector[i]
                    }
                }
                count += 1
            }
        }
        guard count > 0 else {
            return nil
        }
        return sum.map { $0 / Double(count) }
    }

    /// Computes the cosine similarity between two vectors.
    func cosineSimilarity(_ vectorA: [Double], _ vectorB: [Double]) -> Double {
        let dotProduct = zip(vectorA, vectorB).reduce(0.0) { $0 + $1.0 * $1.1 }
        let magnitudeA = sqrt(vectorA.reduce(0.0) { $0 + $1 * $1 })
        let magnitudeB = sqrt(vectorB.reduce(0.0) { $0 + $1 * $1 })
        guard magnitudeA != 0, magnitudeB != 0 else {
            return 0
        }
        return dotProduct / (magnitudeA * magnitudeB)
    }

    /// Determines whether the given message should trigger a tool by comparing it to the provided prototype.
    /// - Parameters:
    ///   - message: The incoming user message.
    ///   - exemplarPrototype: The prototype embedding computed from exemplar phrases.
    ///   - threshold: The similarity threshold (0 to 1) for a match.
    /// - Returns: True if the message's similarity to the prototype is at least the threshold.
    func shouldTriggerTool(for message: String, exemplarPrototype: [Double], threshold: Double = 0.75) -> Bool {
        guard let messageVector = vector(for: message) else {
            return false
        }
        let similarity = cosineSimilarity(messageVector, exemplarPrototype)
        return similarity >= threshold
    }

//
//    /// Checks if any keywords in `toolKeywords` is semantically close to the message.
//    /// - Parameters:
//    ///     - `message`: The user's message to the LLM.
//    ///     - `toolKeywords`:  An array of keywords that are trigger words for our given tool.
//    ///     - `threshold`:  A similarity threshold from 0 to 1, where 1 is a perfect match.
//    /// - Returns:
//    ///     - True if tool should be trigger, false if not.
//    func shouldTriggerTool(for message: String, toolKeywords: [String], threshold: Float = 0.6) -> Bool {
//        // Normalize and sanitize the message
//        let lowercasedMessage = message.lowercased()
//
//        for keyword in toolKeywords {
//            if let distance = embedding.distance(between: lowercasedMessage, and: keyword.lowercased()) {
//                if distance < (1.0 - threshold) {
//                    return true
//                }
//            }
//        }
//
//        return false
//    }
}

//
//  GeminiChatModel.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/15/25.
//

import Foundation
import GoogleGenerativeAI
import PetalCore
import PetalTools

class GeminiChatModel: AIChatModel {
    private var model: GenerativeModel
    private var chat: Chat

    init(modelName: String) {
        self.model = GenerativeModel(name: modelName, apiKey: APIKey.default)
        self.chat = model.startChat()
    }

    func sendMessageStream(_ text: String) -> AsyncThrowingStream<PetalMessageStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await response in chat.sendMessageStream(text) {
                        if let textChunk = response.text {
                            continuation.yield(PetalMessageStreamChunk(message: textChunk, toolCallName: nil))
                        }
                    }
                    continuation.finish()
                } catch {
                    print("Gemini streaming error: \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }

    func sendMessage(_ text: String) async throws -> String {
        let response = try await chat.sendMessage(text)
        return response.text ?? ""
    }
}


enum APIKey {
    /// Fetch the API key from `GenerativeAI-Info.plist`
    /// This is just *one* way how you can retrieve the API key for your app.
    static var `default`: String {
        guard let filePath = Bundle.main.path(forResource: "Petals-GenerativeAI-Info", ofType: "plist")
        else {
            fatalError("Couldn't find file 'Petals-GenerativeAI-Info.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "API_KEY") as? String else {
            fatalError("Couldn't find key 'API_KEY' in 'GenerativeAI-Info.plist'.")
        }
        if value.starts(with: "_") || value.isEmpty {
            fatalError(
                "Follow the instructions at https://ai.google.dev/tutorials/setup to get an API key."
            )
        }
        return value
    }
}
