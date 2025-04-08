//
//  MobileCalendarCreateEventView.swift
//  PetalsiOS
//
//  Created for iOS
//

import SwiftUI
import PetalCore

struct MobileCalendarCreateEventView: View {
    let message: ChatMessage
    
    // Parse the event creation result
    private func parseEventData() -> EventData? {
        let lines = message.message.components(separatedBy: .newlines)
        var eventData = EventData()
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.hasPrefix("Title:") {
                eventData.title = trimmed.replacingOccurrences(of: "Title:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Date:") {
                eventData.date = trimmed.replacingOccurrences(of: "Date:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Time:") {
                eventData.time = trimmed.replacingOccurrences(of: "Time:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Location:") {
                eventData.location = trimmed.replacingOccurrences(of: "Location:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Description:") {
                eventData.description = trimmed.replacingOccurrences(of: "Description:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Calendar:") {
                eventData.calendar = trimmed.replacingOccurrences(of: "Calendar:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Alert:") {
                eventData.alert = trimmed.replacingOccurrences(of: "Alert:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("Created:") || trimmed.hasPrefix("Event created") {
                eventData.isCreated = true
            }
        }
        
        // Only return event data if at least title and date are available
        return eventData.title.isEmpty || eventData.date.isEmpty ? nil : eventData
    }
    
    // Model for event data
    struct EventData {
        var title: String = ""
        var date: String = ""
        var time: String = ""
        var location: String = ""
        var description: String = ""
        var calendar: String = "Default"
        var alert: String = "None"
        var isCreated: Bool = false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Calendar Event")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Divider().padding(.vertical, 4)
            
            if let eventData = parseEventData() {
                // Event details card
                VStack(spacing: 16) {
                    // Status header
                    HStack {
                        Text(eventData.isCreated ? "Event Created" : "Event Preview")
                            .font(.headline)
                            .foregroundColor(eventData.isCreated ? .green : .primary)
                        
                        Spacer()
                        
                        if eventData.isCreated {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(eventData.isCreated ? Color.green.opacity(0.1) : Color(UIColor.tertiarySystemBackground))
                    )
                    
                    // Event details
                    VStack(spacing: 16) {
                        // Title
                        HStack(alignment: .top) {
                            Image(systemName: "bookmark.fill")
                                .frame(width: 24)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("Title")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(eventData.title)
                                    .font(.headline)
                            }
                            
                            Spacer()
                        }
                        
                        // Date & Time
                        HStack(alignment: .top) {
                            Image(systemName: "clock.fill")
                                .frame(width: 24)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading) {
                                Text("Date & Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(eventData.date) \(eventData.time)")
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                        }
                        
                        // Location (if exists)
                        if !eventData.location.isEmpty {
                            HStack(alignment: .top) {
                                Image(systemName: "mappin.circle.fill")
                                    .frame(width: 24)
                                    .foregroundColor(.red)
                                
                                VStack(alignment: .leading) {
                                    Text("Location")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(eventData.location)
                                        .font(.subheadline)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Calendar
                        HStack(alignment: .top) {
                            Image(systemName: "calendar")
                                .frame(width: 24)
                                .foregroundColor(.purple)
                            
                            VStack(alignment: .leading) {
                                Text("Calendar")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(eventData.calendar)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                        }
                        
                        // Alert (if specified)
                        if !eventData.alert.isEmpty && eventData.alert.lowercased() != "none" {
                            HStack(alignment: .top) {
                                Image(systemName: "bell.fill")
                                    .frame(width: 24)
                                    .foregroundColor(.yellow)
                                
                                VStack(alignment: .leading) {
                                    Text("Alert")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(eventData.alert)
                                        .font(.subheadline)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Description (if exists)
                        if !eventData.description.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Description")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(eventData.description)
                                    .font(.subheadline)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
                    .cornerRadius(10)
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        if !eventData.isCreated {
                            Button(action: {
                                // Mock "Add to calendar" action
                            }) {
                                Text("Add to Calendar")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                // Mock "Edit" action
                            }) {
                                Text("Edit")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(8)
                            }
                        } else {
                            Button(action: {
                                // Mock "View in Calendar" action
                            }) {
                                Text("View in Calendar")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                // Mock "Share" action
                            }) {
                                Text("Share")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            } else {
                // No valid event data found
                Text("Could not parse event details")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
    }
} 