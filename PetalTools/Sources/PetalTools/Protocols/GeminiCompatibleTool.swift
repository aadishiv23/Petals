//
//  GeminiCompatibleTool.swift
//  PetalTools
//
//  Created by Aadi Shiv Malhotra on 3/11/25.
//

import Foundation
import GoogleGenerativeAI

/// Protocol for tools that can be used with Gemini.
public protocol GeminiCompatibleTool: PetalTool {
    /// Converts this tool into a Gemini function declaration.
    func asGeminiFunctionDeclaration() -> FunctionDeclaration
}
