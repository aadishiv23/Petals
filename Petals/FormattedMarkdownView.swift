//
//  FormattedMarkdownView.swift
//  Petals
//
//  Created by Aadi Shiv Malhotra on 2/6/25.
//

import Foundation
import SwiftUI

struct FormattedMarkdownView: View {
    let text: String

    var body: some View {
        if let attributedString = parseMarkdown(text) {
            Text(attributedString)
                .padding()
        } else {
            Text(text) // Fallback in case of error
                .foregroundColor(.red)
                .padding()
        }
    }

    /// Parses Markdown into an `AttributedString`
    private func parseMarkdown(_ text: String) -> AttributedString? {
        do {
            return try AttributedString(markdown: text)
        } catch {
            print("⚠️ Markdown Parsing Error: \(error.localizedDescription)")
            return nil
        }
    }
}
