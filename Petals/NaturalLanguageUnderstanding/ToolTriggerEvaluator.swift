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
        
        guard validCount > 0 else { return nil }
        return sumVector.map { $0 / Double(validCount) }
    }

    /// Computes the centroid (prototype) vector for a set of exemplar phrases.
    /// - Parameter exemplars: An array of exemplar trigger phrases for a tool.
    /// - Returns: A vector representing the averaged (centroid) embedding, or nil if none could be computed.
    func prototype(for exemplars: [String]) -> [Double]? {
        var sum: [Double] = []
        var count = 0
        
        for exemplar in exemplars {
            if let vector = self.vector(for: exemplar) {
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
        guard count > 0 else { return nil }
        return sum.map { $0 / Double(count) }
    }
    
    /// Computes the cosine similarity between two vectors.
    func cosineSimilarity(_ vectorA: [Double], _ vectorB: [Double]) -> Double {
        let dotProduct = zip(vectorA, vectorB).reduce(0.0) { $0 + $1.0 * $1.1 }
        let magnitudeA = sqrt(vectorA.reduce(0.0) { $0 + $1 * $1 })
        let magnitudeB = sqrt(vectorB.reduce(0.0) { $0 + $1 * $1 })
        guard magnitudeA != 0 && magnitudeB != 0 else { return 0 }
        return dotProduct / (magnitudeA * magnitudeB)
    }

    /// Determines whether the given message should trigger a tool by comparing it to the provided prototype.
    /// - Parameters:
    ///   - message: The incoming user message.
    ///   - exemplarPrototype: The prototype embedding computed from exemplar phrases.
    ///   - threshold: The similarity threshold (0 to 1) for a match.
    /// - Returns: True if the message's similarity to the prototype is at least the threshold.
    func shouldTriggerTool(for message: String, exemplarPrototype: [Double], threshold: Double = 0.75) -> Bool {
        guard let messageVector = self.vector(for: message) else { return false }
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
