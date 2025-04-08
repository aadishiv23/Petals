//
//  CalendarEventsView.swift
//  Petals
//
//  Created for ChatBubbleView
//

import SwiftUI
import PetalCore

struct CalendarEventsView: View {
    let message: ChatMessage
    let bubbleColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Calendar Events")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            Divider().padding(.vertical, 2)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(
                        message.message.components(separatedBy: .newlines).filter { !$0.isEmpty },
                        id: \.self
                    ) { eventLine in
                        HStack(alignment: .top, spacing: 10) {
                            let components = eventLine.components(separatedBy: " @ ")
                            let eventName = components.first?.trimmingCharacters(in: .whitespacesAndNewlines)
                                .replacingOccurrences(
                                    of: "• ",
                                    with: ""
                                ) ?? ""
                            let dateTimeLocation = components.count > 1 ? components[1] : ""
                            Image(systemName: "calendar.badge.clock")
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                                .padding(6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(eventName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                if !dateTimeLocation.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                        Text(dateTimeLocation)
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(bubbleColor))
        .contextMenu {
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.message, forType: .string)
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }
} 