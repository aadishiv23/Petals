//
//  ToolProcessingView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 3/12/25.
//

import Foundation
import SwiftUI

/// An animated view that displays the chain-of-thought process during tool calls
struct ToolProcessingView: View {
    // Animation states
    @State private var currentStep = 0
    @State private var opacity = 0.7
    
    // Processing steps definition
    let processingSteps = [
        (icon: "arrow.down.doc.fill", text: "Processing Input"),
        (icon: "hammer.fill", text: "Using Tool"),
        (icon: "gear", text: "Analyzing Data"),
        (icon: "text.badge.checkmark", text: "Preparing Output")
    ]
    
    // Timer for animation progression
    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<processingSteps.count, id: \.self) { index in
                HStack(spacing: 12) {
                    // Icon with animated background
                    ZStack {
                        Circle()
                            .fill(Color(hex: index == currentStep ? "5E5CE6" : "D8D8D8"))
                            .frame(width: 28, height: 28)
                            .opacity(index == currentStep ? 1.0 : 0.5)
                        
                        Image(systemName: processingSteps[index].icon)
                            .font(.system(size: 12))
                            .foregroundColor(index == currentStep ? .white : Color(.secondaryLabelColor))
                    }
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                    
                    // Step text with animated opacity
                    Text(processingSteps[index].text)
                        .font(.system(size: 14, weight: index == currentStep ? .medium : .regular))
                        .foregroundColor(index == currentStep ? .primary : Color(.secondaryLabelColor))
                        .opacity(index == currentStep ? 1.0 : 0.7)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
                
                // Progress line connecting steps
                if index < processingSteps.count - 1 {
                    Rectangle()
                        .fill(Color(hex: "D8D8D8"))
                        .frame(width: 2, height: 16)
                        .offset(x: 14)
                        .opacity(0.7)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
        .opacity(opacity)
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                // Only increment until the last step; once reached, keep pulsing
                if currentStep < processingSteps.count - 1 {
                    currentStep += 1
                }
            }
        }
    }
}

// Preview provider for SwiftUI Canvas
struct ToolProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        ToolProcessingView()
            .frame(width: 300)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
