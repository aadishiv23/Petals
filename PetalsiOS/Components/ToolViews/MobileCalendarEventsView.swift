//
//  MobileCalendarEventsView.swift
//  PetalsiOS
//
//  Created for iOS
//

import SwiftUI
import PetalCore

struct MobileCalendarEventsView: View {
    let message: ChatMessage
    @State private var selectedEvent: CalendarEvent? = nil
    
    // Model for calendar events 
    struct CalendarEvent: Identifiable {
        let id = UUID()
        let title: String
        let time: String
        let location: String?
        let description: String?
        let color: Color
    }
    
    // Parse events from the message
    private func parseEvents() -> [CalendarEvent] {
        // This is a simplified parser, in a real app we'd do proper JSON parsing
        let lines = message.message.components(separatedBy: .newlines)
        var events: [CalendarEvent] = []
        var currentEvent: (title: String, time: String, location: String?, description: String?, color: Color)?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.hasPrefix("Event:") {
                // Start a new event
                if let event = currentEvent {
                    events.append(CalendarEvent(
                        title: event.title,
                        time: event.time,
                        location: event.location,
                        description: event.description,
                        color: event.color
                    ))
                }
                
                let title = trimmed.replacingOccurrences(of: "Event:", with: "").trimmingCharacters(in: .whitespaces)
                currentEvent = (title, "", nil, nil, randomEventColor())
            } else if trimmed.hasPrefix("Time:"), let event = currentEvent {
                let time = trimmed.replacingOccurrences(of: "Time:", with: "").trimmingCharacters(in: .whitespaces)
                currentEvent = (event.title, time, event.location, event.description, event.color)
            } else if trimmed.hasPrefix("Location:"), let event = currentEvent {
                let location = trimmed.replacingOccurrences(of: "Location:", with: "").trimmingCharacters(in: .whitespaces)
                currentEvent = (event.title, event.time, location, event.description, event.color)
            } else if trimmed.hasPrefix("Description:"), let event = currentEvent {
                let description = trimmed.replacingOccurrences(of: "Description:", with: "").trimmingCharacters(in: .whitespaces)
                currentEvent = (event.title, event.time, event.location, description, event.color)
            }
        }
        
        // Add the last event if there is one
        if let event = currentEvent {
            events.append(CalendarEvent(
                title: event.title,
                time: event.time,
                location: event.location,
                description: event.description,
                color: event.color
            ))
        }
        
        return events
    }
    
    // Generate a random color for events
    private func randomEventColor() -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .yellow]
        return colors.randomElement() ?? .blue
    }
    
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
            
            Divider().padding(.vertical, 4)
            
            let events = parseEvents()
            
            if events.isEmpty {
                Text("No events found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(events) { event in
                        Button {
                            selectedEvent = event
                        } label: {
                            HStack(alignment: .top) {
                                // Color indicator
                                Rectangle()
                                    .fill(event.color)
                                    .frame(width: 4)
                                    .cornerRadius(2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text(event.time)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    if let location = event.location, !location.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.caption)
                                            Text(location)
                                                .font(.caption)
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.leading, 4)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
        .sheet(item: $selectedEvent) { event in
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with color
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(event.time)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(event.color.opacity(0.15))
                    
                    List {
                        if let location = event.location, !location.isEmpty {
                            Section(header: Text("Location")) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(event.color)
                                    Text(location)
                                }
                            }
                        }
                        
                        if let description = event.description, !description.isEmpty {
                            Section(header: Text("Details")) {
                                Text(description)
                            }
                        }
                        
                        Section {
                            Button(action: {
                                // Add to calendar action
                            }) {
                                Label("Add to Calendar", systemImage: "calendar.badge.plus")
                            }
                            
                            Button(action: {
                                // Set reminder action
                            }) {
                                Label("Set Reminder", systemImage: "bell.badge")
                            }
                            
                            Button(action: {
                                // Share action
                            }) {
                                Label("Share Event", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                .navigationTitle("Event Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            selectedEvent = nil
                        }
                    }
                }
            }
        }
    }
} 