//
//  CalendarCreateEventView.swift
//  Petals
//
//  Created for ChatBubbleView
//

import SwiftUI
import PetalCore

struct CalendarCreateEventView: View {
    let message: ChatMessage
    let bubbleColor: Color
    @State private var isExpanded = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }

                Text("New Event Created")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                if isExpanded {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }

            Divider().padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 28, height: 28)

                        Image(systemName: "text.bubble")
                            .font(.system(size: 14))
                            .foregroundColor(.purple)
                    }

                    Text("Project Meeting")
                        .font(.system(size: 16, weight: .semibold))
                }

                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 28, height: 28)

                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                    }

                    Text("March 20, 2025")
                        .font(.system(size: 14))
                }

                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 28, height: 28)

                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }

                    Text("10:00 AM - 11:30 AM")
                        .font(.system(size: 14))
                }

                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 28, height: 28)

                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }

                    Text("Conference Room B")
                        .font(.system(size: 14))
                }

                if isExpanded {
                    Divider().padding(.vertical, 8)

                    HStack(spacing: 8) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 14))
                                Text("Accept")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.green)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {}) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 14))
                                Text("Decline")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {}) {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 14))
                                Text("Edit")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 28, height: 28)

                            Image(systemName: "person.2")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }

                        Text("3 Attendees")
                            .font(.system(size: 14))

                        Spacer()

                        Button(action: {}) {
                            Text("View All")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 28, height: 28)

                            Image(systemName: "doc.text")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }

                        Text("Project status update and planning")
                            .font(.system(size: 14))
                            .lineLimit(1)

                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(bubbleColor)
                .shadow(
                    color: Color.black.opacity(isHovered ? 0.15 : 0.08),
                    radius: isHovered ? 4 : 2,
                    x: 0,
                    y: isHovered ? 3 : 1
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
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