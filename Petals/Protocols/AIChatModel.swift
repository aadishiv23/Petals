//
//  AIChatModel.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/15/25.
//

import Foundation
import PetalTools

protocol AIChatModel {
    func sendMessageStream(_ text: String) -> AsyncStream<PetalMessageStreamChunk>
    func sendMessage(_ text: String) async throws -> String
}
