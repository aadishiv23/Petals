//
//  ModelPickerView.swift
//  PetalsiOS
//
//  Created for iOS target
//

import SwiftUI

struct ModelPickerView: View {
    @Binding var useOllama: Bool
    
    var body: some View {
        List {
            Section(header: Text("Select Model")) {
                Button(action: { useOllama = false }) {
                    HStack {
                        Image(systemName: "cloud")
                            .foregroundColor(Color(hex: "5E5CE6"))
                        Text("Gemini API (Cloud)")
                        Spacer()
                        if !useOllama {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(hex: "5E5CE6"))
                        }
                    }
                }
                
                Button(action: { useOllama = true }) {
                    HStack {
                        Image(systemName: "desktopcomputer")
                            .foregroundColor(Color(hex: "5E5CE6"))
                        Text("MLX (Local)")
                        Spacer()
                        if useOllama {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(hex: "5E5CE6"))
                        }
                    }
                }
            }
        }
        .navigationTitle("Model Selection")
    }
} 