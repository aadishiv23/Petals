//
//  BubbleShape.swift
//  Petals
//
//  Created for ChatBubbleView
//

import Foundation
import SwiftUI

struct BubbleShape: Shape {
    var isUser: Bool

    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 12
        let minX = rect.minX
        let minY = rect.minY
        let maxX = rect.maxX
        let maxY = rect.maxY

        let path = Path { p in
            if isUser {
                // User message (right corner)
                p.move(to: CGPoint(x: minX + cornerRadius, y: minY))
                p.addLine(to: CGPoint(x: maxX - cornerRadius - 4, y: minY))
                p.addCurve(
                    to: CGPoint(x: maxX, y: minY + cornerRadius),
                    control1: CGPoint(x: maxX - 4, y: minY),
                    control2: CGPoint(x: maxX, y: minY + 4)
                )
                p.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
                p.addCurve(
                    to: CGPoint(x: maxX - cornerRadius, y: maxY),
                    control1: CGPoint(x: maxX, y: maxY - 4),
                    control2: CGPoint(x: maxX - 4, y: maxY)
                )
                p.addLine(to: CGPoint(x: minX + cornerRadius, y: maxY))
                p.addCurve(
                    to: CGPoint(x: minX, y: maxY - cornerRadius),
                    control1: CGPoint(x: minX + 4, y: maxY),
                    control2: CGPoint(x: minX, y: maxY - 4)
                )
                p.addLine(to: CGPoint(x: minX, y: minY + cornerRadius))
                p.addCurve(
                    to: CGPoint(x: minX + cornerRadius, y: minY),
                    control1: CGPoint(x: minX, y: minY + 4),
                    control2: CGPoint(x: minX + 4, y: minY)
                )
            } else {
                // AI message (left corner)
                p.move(to: CGPoint(x: minX + cornerRadius, y: minY))
                p.addLine(to: CGPoint(x: maxX - cornerRadius, y: minY))
                p.addCurve(
                    to: CGPoint(x: maxX, y: minY + cornerRadius),
                    control1: CGPoint(x: maxX - 4, y: minY),
                    control2: CGPoint(x: maxX, y: minY + 4)
                )
                p.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
                p.addCurve(
                    to: CGPoint(x: maxX - cornerRadius, y: maxY),
                    control1: CGPoint(x: maxX, y: maxY - 4),
                    control2: CGPoint(x: maxX - 4, y: maxY)
                )
                p.addLine(to: CGPoint(x: minX + cornerRadius + 4, y: maxY))
                p.addCurve(
                    to: CGPoint(x: minX, y: maxY - cornerRadius),
                    control1: CGPoint(x: minX + 4, y: maxY),
                    control2: CGPoint(x: minX, y: maxY - 4)
                )
                p.addLine(to: CGPoint(x: minX, y: minY + cornerRadius))
                p.addCurve(
                    to: CGPoint(x: minX + cornerRadius, y: minY),
                    control1: CGPoint(x: minX, y: minY + 4),
                    control2: CGPoint(x: minX + 4, y: minY)
                )
            }
            p.closeSubpath()
        }
        return path
    }
} 