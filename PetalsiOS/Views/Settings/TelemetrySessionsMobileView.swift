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
                            // New: Model/tool-call visibility
                            if let initial = m.modelInitialOutput, !initial.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Model output (pre-tool)")
                                        .font(.subheadline)
                                    ScrollView(.horizontal, showsIndicators: false) { Text(initial).font(.caption).foregroundColor(.secondary) }
                                }
                                .padding(.top, 4)
                            }
                            if let raw = m.toolCallJsonRaw, !raw.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tool call JSON (raw)")
                                        .font(.subheadline)
                                    ScrollView(.horizontal, showsIndicators: false) { Text(raw).font(.caption2).foregroundColor(.secondary) }
                                }
                                .padding(.top, 2)
                            }
                            if let norm = m.toolCallJsonNormalized, !norm.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tool call JSON (normalized)")
                                        .font(.subheadline)
                                    ScrollView(.horizontal, showsIndicators: false) { Text(norm).font(.caption2).foregroundColor(.secondary) }
                                }
                            }
                            if let tool = m.chosenToolName, !tool.isEmpty {
                                HStack { Text("Chosen tool:") .font(.subheadline); Text(tool).font(.subheadline).foregroundColor(.secondary) }
                            }
                            if let rawOut = m.toolRawOutput, !rawOut.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tool processed output")
                                        .font(.subheadline)
                                    Text(rawOut).font(.caption).foregroundColor(.secondary)
                                }
                                .padding(.top, 2)
                            }
                            if let final = m.finalResponse, !final.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Final response")
                                        .font(.subheadline)
                                    Text(final).font(.caption).foregroundColor(.secondary)
                                }
                                .padding(.top, 2)
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


