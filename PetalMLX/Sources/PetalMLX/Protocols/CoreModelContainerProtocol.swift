//
//  CoreModelContainerProtocol.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 3/26/25.
//

import Foundation
import MLXLLM
import MLXLMCommon

/// A protocol that outlines the core functionalities of a model container.
/// Classes or structures conforming to this protocol should be observable,
/// and should support the ability to send data asynchronously.
public protocol CoreModelContainerProtocol: Sendable, ObservableObject {
    /// The result type that will be produced by the container.
    associatedtype ContainerResult = MLXLMCommon.GenerateResult

    /// A typealias for a dictionary of tools, where each tool is any type
    /// that conforms to the `Sendable` protocol.
    typealias Tool = [String: any Sendable]

    /// A typealias for a closure that takes a `String` and returns `Void`.
    /// Used to handle progress updates as a string message.
    typealias OnProgress = @Sendable (String) -> Void

    /// A string property that represents the progress of an operation.
    var onProgress: String { get }

    /// Asynchronously generates a result based on the given messages and tools.
    /// - Parameters:
    ///   - messages: An array of dictionaries, where each dictionary represents
    ///     a message with string keys and values.
    ///   - tools: An optional array of tools used during the generation process.
    ///   - onProgress: A closure that is called with progress updates as a string.
    /// - Returns: A result of type `ContainerResult`.
    /// - Throws: An error if the generation process fails.
    func generate(
        messages: [[String: String]],
        tools: [Tool]?,
        onProgress: @escaping OnProgress
    ) async throws -> ContainerResult
}
