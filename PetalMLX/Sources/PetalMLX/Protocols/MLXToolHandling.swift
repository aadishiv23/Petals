//
//  MLXToolHandlerProtocol.swift
//  PetalMLX
//
//  Created by Aadi Shiv Malhotra on 3/26/25.
//

import Foundation

public protocol MLXToolHandling {

    /// Processes the tool call JSON and returns the results.
    func handle(json: Data) async throws -> String
}
