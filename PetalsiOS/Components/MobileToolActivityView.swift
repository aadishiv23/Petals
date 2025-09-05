//
//  MobileToolActivityView.swift
//  PetalsiOS
//
//  Created by AI Assistant on 4/3/25.
//

import SwiftUI

struct MobileToolActivityView: View {
    let toolName: String?
    let symbolName: String
    @State private var animate = false

    init(toolName: String?, symbolName: String = "wrench.and.screwdriver") {
        self.toolName = toolName
        self.symbolName = symbolName
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "5E5CE6"))
                .frame(width: 16, height: 16)

            shimmerText(formattedToolName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            withAnimation(Animation.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }

    private var formattedToolName: String {
        guard var name = toolName, !name.isEmpty else { return "Using tool…" }
        // Strip common prefix/suffix
        if name.lowercased().hasPrefix("petal") {
            name = String(name.dropFirst(5))
        }
        if name.lowercased().hasSuffix("tool") {
            name = String(name.dropLast(4))
        }
        // Split camelCase
        let components = name.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .unicodeScalars
            .reduce(into: "") { result, scalar in
                if CharacterSet.uppercaseLetters.contains(scalar), let last = result.last, last != " " {
                    result.append(" ")
                }
                result.append(Character(scalar))
            }
        return components.capitalized.trimmingCharacters(in: .whitespaces)
    }

    @ViewBuilder
    private func shimmerText(_ text: String) -> some View {
        ZStack {
            Text(text)
                .opacity(0.55)

            Text(text)
                .mask(
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .black.opacity(0.0),
                                .black.opacity(0.8),
                                .black.opacity(0.0)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: width)
                        .offset(x: animate ? width : -width)
                    }
                )
                .opacity(0.85)
        }
        .compositingGroup()
    }
}

#Preview {
    VStack(spacing: 16) {
        MobileToolActivityView(toolName: "petalCalendarFetchEventsTool")
        MobileToolActivityView(toolName: nil)
    }
    .padding()
}


