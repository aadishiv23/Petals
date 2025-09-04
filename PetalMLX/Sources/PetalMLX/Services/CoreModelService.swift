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

public struct CoreModelService {
    public init() {}
    
    /// Provide a model container for a given MLX `ModelConfiguration`.
    /// Defaults to `ModelConfiguration.defaultModel` if none is provided.
    public func provideModelContainer(
        model: ModelConfiguration = ModelConfiguration.defaultModel,
        parameters: GenerateParameters = GenerateParameters(temperature: 0.5)
    ) -> any CoreModelContainerProtocol {
        ConcreteCoreModelContainer(
            modelConfiguration: model,
            generateParameters: parameters
        )
    }
}
