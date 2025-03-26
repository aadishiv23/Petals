//
//  File.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 3/25/25.
//

import Foundation
import MLXLLM
import MLXLMCommon
import SwiftUI

public protocol CoreModelContainer: Sendable, ObservableObject {
    associatedtype ContainerResult = MLXLMCommon.GenerateResult
    typealias Tool = [String: any Sendable]
    typealias OnProgress = @Sendable (String) -> Void

    var onProgress: String { get }

    func generate(
        messages: [[String: String]],
        tools: [Tool]?,
        onProgress: @escaping OnProgress
    ) async throws -> ContainerResult
}

public struct CoreModelService {
    public init() {}
    
    public func provideModelContainer() -> any CoreModelContainer {
        // Here we choose our ConcreteModelContainer (see next file) with the default model.
        return ConcreteModelContainer(
            modelConfiguration: ModelConfiguration.defaultModel,
            generateParameters: GenerateParameters(temperature: 0.5)
        )
    }
}
