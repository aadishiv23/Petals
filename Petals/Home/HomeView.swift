import Foundation
import SwiftUI

struct HomeView: View {
    /// Callback invoked when the user clicks the start chat box
    var startChatAction: () -> Void
    
    // State for the search field
    @State private var searchQuery = ""
    @State private var selectedCategory: AgentCategory = .all
    
    // Categories for AI agent capabilities
    enum AgentCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case research = "Research"
        case writing = "Writing"
        case organization = "Organization"
        case analysis = "Analysis"
        case creative = "Creative"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .research: return "magnifyingglass.circle"
            case .writing: return "pencil.and.document"
            case .organization: return "folder.badge.gearshape"
            case .analysis: return "chart.bar.xaxis"
            case .creative: return "paintbrush.pointed"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .research: return .indigo
            case .writing: return .purple
            case .organization: return .green
            case .analysis: return .orange
            case .creative: return .pink
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with greeting and search
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Command Center")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("What would you like me to help with today?")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // User profile / Settings
                        Button(action: {}) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Ask me anything or search for capabilities...", text: $searchQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Button(action: startChatAction) {
                            Text("Ask")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(12)
                    .background(Color(.windowBackgroundColor).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
                .padding([.horizontal, .top], 24)
                .padding(.bottom, 12)
                .background(Color(.windowBackgroundColor))
                
                // Category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AgentCategory.allCases) { category in
                            CategoryPill(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                
                // Main content area
                ScrollView {
                    VStack(spacing: 24) {
                        // Quick Actions Section
                        SectionView(title: "Quick Actions", icon: "bolt") {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                                ActionButton(
                                    icon: "terminal",
                                    text: "Execute Command",
                                    color: .blue,
                                    description: "Run custom instructions"
                                )
                                
                                ActionButton(
                                    icon: "brain",
                                    text: "Think For Me",
                                    color: .purple,
                                    description: "Solve complex problems"
                                )
                                
                                ActionButton(
                                    icon: "doc.text.magnifyingglass",
                                    text: "Research",
                                    color: .indigo,
                                    description: "Find information on any topic"
                                )
                                
                                ActionButton(
                                    icon: "folder.badge.plus",
                                    text: "Organize Notes",
                                    color: .green,
                                    description: "Collate and structure information"
                                )
                            }
                        }
                        
                        // Advanced Tools Section
                        SectionView(title: "Advanced Tools", icon: "gearshape.2") {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                                ActionButton(
                                    icon: "text.book.closed",
                                    text: "Essay Writer",
                                    color: .pink,
                                    description: "Create well-structured essays"
                                )
                                
                                ActionButton(
                                    icon: "chart.pie",
                                    text: "Data Analysis",
                                    color: .orange,
                                    description: "Interpret and visualize data"
                                )
                                
                                ActionButton(
                                    icon: "list.bullet.clipboard",
                                    text: "Project Planner",
                                    color: .teal,
                                    description: "Break down complex projects"
                                )
                                
                                ActionButton(
                                    icon: "lightbulb",
                                    text: "Idea Generator",
                                    color: .yellow,
                                    description: "Creative brainstorming"
                                )
                            }
                        }
                        
                        // Recent Sessions Section
                        SectionView(title: "Recent Sessions", icon: "clock") {
                            VStack(spacing: 12) {
                                RecentSessionCard(
                                    title: "Research: Quantum Computing Applications",
                                    preview: "Collected 23 sources and summarized key findings",
                                    icon: "atom",
                                    iconColor: .blue,
                                    time: "2 hours ago"
                                )
                                
                                RecentSessionCard(
                                    title: "Essay Draft: Impact of AI on Healthcare",
                                    preview: "2,500 word draft with 15 citations organized by theme",
                                    icon: "heart.text.square",
                                    iconColor: .pink,
                                    time: "Yesterday"
                                )
                                
                                RecentSessionCard(
                                    title: "Project Plan: Mobile App Development",
                                    preview: "Created 8-week timeline with resource allocation",
                                    icon: "calendar",
                                    iconColor: .green,
                                    time: "3 days ago"
                                )
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .frame(minWidth: 800, idealWidth: 1000, maxWidth: .infinity, minHeight: 600, idealHeight: 700, maxHeight: .infinity)
        }
        .navigationTitle("")
        // Removed the StackNavigationViewStyle that's unavailable in macOS
        .background(Color(.windowBackgroundColor))
    }
}

// Category selector pill
struct CategoryPill: View {
    let category: HomeView.AgentCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                
                Text(category.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? category.color.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? category.color : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? category.color : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Section view with title
struct SectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// Enhanced action button
struct ActionButton: View {
    let icon: String
    let text: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                Spacer()
                
                // Quick action button
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(color.opacity(0.7))
            }
            
            // Text
            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            // Description
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// Recent session card
struct RecentSessionCard: View {
    let title: String
    let preview: String
    let icon: String
    let iconColor: Color
    let time: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(preview)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Time and action
            VStack(alignment: .trailing, spacing: 4) {
                Text(time)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Button(action: {}) {
                    Text("Continue")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView {}
}
