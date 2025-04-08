//
//  ToolProcessingView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/12/25.
//

import Foundation
import SwiftUI

/// Represents the different stages of tool processing
enum ToolProcessingStage: Int, CaseIterable {
    case processingInput = 0
    case usingTool
    case thinking
    case preparingOutput
    case completed
    
    var icon: String {
        switch self {
        case .processingInput: return "arrow.down.doc.fill"
        case .usingTool: return "hammer.fill"
        case .thinking: return "lightbulb.max.fill"
        case .preparingOutput: return "text.badge.checkmark"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    var text: String {
        switch self {
        case .processingInput: return "Processing Input"
        case .usingTool: return "Using Tool"
        case .thinking: return "Thinking"
        case .preparingOutput: return "Preparing Output"
        case .completed: return "Completed"
        }
    }
}

/// An animated view that displays the chain-of-thought process during tool calls
struct ToolProcessingView: View {
    // Current processing stage
    let currentStage: ToolProcessingStage
    
    // For the glowing outline
    @State private var glowPhase: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(ToolProcessingStage.allCases, id: \.self) { stage in
                if stage != .completed || currentStage == .completed {
                    HStack(spacing: 12) {
                        // Icon with animated background
                        ZStack {
                            Circle()
                                .fill(Color(hex: stage.rawValue <= currentStage.rawValue ? "5E5CE6" : "D8D8D8"))
                                .frame(width: 28, height: 28)
                                .opacity(stage.rawValue <= currentStage.rawValue ? 1.0 : 0.5)
                            
                            Image(systemName: stage.icon)
                                .font(.system(size: 12))
                                .foregroundColor(stage.rawValue <= currentStage.rawValue ? .white : Color(.secondaryLabelColor))
                        }
                        .animation(.easeInOut(duration: 0.3), value: currentStage)
                        
                        // Step text with animated opacity
                        Text(stage.text)
                            .font(.system(size: 14, weight: stage.rawValue == currentStage.rawValue ? .medium : .regular))
                            .foregroundColor(stage.rawValue <= currentStage.rawValue ? .primary : Color(.secondaryLabelColor))
                            .opacity(stage.rawValue <= currentStage.rawValue ? 1.0 : 0.7)
                            .animation(.easeInOut(duration: 0.3), value: currentStage)
                    }
                    
                    // Progress line connecting steps
                    if stage != .completed {
                        Rectangle()
                            .fill(Color(hex: "D8D8D8"))
                            .frame(width: 2, height: 16)
                            .offset(x: 14)
                            .opacity(0.7)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        // Main background
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
        // Standard border stroke
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
        // Glowing animated border
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.purple, .blue, .pink, .purple]),
                        center: .center,
                        startAngle: .degrees(glowPhase),
                        endAngle: .degrees(glowPhase + 360)
                    ),
                    lineWidth: 3
                )
                .blur(radius: 3)
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        glowPhase = 360
                    }
                }
        )
        .opacity(currentStage == .completed ? 0.7 : 1.0)
    }
}

// MARK: - Preview
struct ToolProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ToolProcessingView(currentStage: .processingInput)
            ToolProcessingView(currentStage: .usingTool)
            ToolProcessingView(currentStage: .thinking)
            ToolProcessingView(currentStage: .preparingOutput)
            ToolProcessingView(currentStage: .completed)
        }
        .frame(width: 300)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
