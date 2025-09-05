//
//  TelemetrySessionsMobileView.swift
//  PetalsiOS
//
//  Created by AI Assistant on 4/3/25.
//

import SwiftUI
import PetalCore

struct TelemetrySessionsMobileView: View {
    @ObservedObject private var telemetry = TelemetryManager.shared

    var body: some View {
        List {
            ForEach(Array(telemetry.sessions.values).sorted(by: { $0.updatedAt > $1.updatedAt }), id: \.id) { session in
                Section(header: Text("Chat: \(session.id.uuidString.prefix(8)) • messages: \(session.messages.count)")) {
                    ForEach(session.messages, id: \.messageId) { m in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(m.userText.prefix(80))
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 2) {
                                metric("TTFT", value: m.timeToFirstTokenMs, suffix: " ms")
                                metric("Total", value: m.totalLatencyMs, suffix: " ms")
                                metric("Gen", value: m.generationDurationMs, suffix: " ms")
                                metric("Tokens/s", value: m.tokensPerSecond, suffix: "")
                                Text("Chars: \(m.responseLengthChars)")
                                    .foregroundColor(.secondary)
                            }
                            if !m.toolInvocations.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tools").font(.subheadline)
                                    ForEach(m.toolInvocations, id: \.self) { t in
                                        HStack {
                                            Text(t.name)
                                            Spacer()
                                            if let ms = t.durationMs {
                                                Text("\(Int(ms)) ms").foregroundColor(.secondary)
                                            }
                                            if let success = t.success {
                                                Image(systemName: success ? "checkmark.seal" : "xmark.seal")
                                                    .foregroundColor(success ? .green : .red)
                                            }
                                        }
                                    }
                                }
                            }
                            if let err = m.errorDescription {
                                Text("Error: \(err)").foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("Telemetry")
        .toolbar {
            Button("Clear All") { telemetry.clearAll() }
        }
    }

    @ViewBuilder
    private func metric(_ title: String, value: Double?, suffix: String) -> some View {
        if let value { Text("\(title): \(Int(value))\(suffix)").foregroundColor(.secondary) }
    }
}

#Preview {
    TelemetrySessionsMobileView()
}


