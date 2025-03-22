//
//  PetalMessageStreamChunk.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/19/25.
//

/// A custom struct that represents a response from an assistant.
/// The object holds the message as well as an optional tool call name.
public struct PetalMessageStreamChunk {
    
    /// The message returned by the LLM.
    public let message: String
    
    /// (Optional) The name of the tool call used by the assistant.
    public let toolCallName: String?
    
    // MARK: Initializer
    
    public init(message: String, toolCallName: String?) {
        self.message = message
        self.toolCallName = toolCallName
    }
}
