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
    
    public func provideModelContainer() -> any CoreModelContainerProtocol {
        // Here we choose our ConcreteModelContainer (see next file) with the default model.
        return ConcreteCoreModelContainer(
            modelConfiguration: ModelConfiguration.defaultModel,
            generateParameters: GenerateParameters(temperature: 0.5)
        )
    }
}
