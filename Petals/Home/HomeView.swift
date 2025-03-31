import SwiftUI

struct HomeView: View {
    /// Callback invoked when the user clicks the start chat box or "Ask" button
    var startChatAction: () -> Void

    // State for the search field and category selection
    @State private var searchQuery = ""
    @State private var selectedCategory: AgentCategory = .all

    // --- Body ---
    var body: some View {
        // Use a standard VStack as the root, since NavigationSplitView provides the structure
        VStack(spacing: 0) {
            headerView                 // Extracted Header
            categorySelectorView       // Extracted Category Selector
            mainContentScrollView      // Extracted Main Content Area
        }
        .background(backgroundColor) // Use platform-appropriate background
        // Apply frame constraints to the VStack itself
        .frame(
            minWidth: 800, // Consider adjusting minWidth for iOS if needed
            idealWidth: 1000,
            maxWidth: .infinity,
            minHeight: 600, // Consider adjusting minHeight for iOS
            idealHeight: 700,
            maxHeight: .infinity
        )
        // No .navigationTitle here - managed by the containing view (NavigationSplitView)
        // No NavigationView here
    }

    // --- Computed Properties for Body Breakdown ---

    /// Platform-agnostic background color
    private var backgroundColor: Color {
        #if os(macOS)
        return Color(.windowBackgroundColor)
        #else
        return Color(.systemGroupedBackground) // iOS equivalent
        #endif
    }

    /// View for the top header section
    private var headerView: some View {
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
                settingsButton // Extracted settings button
            }
            searchBar // Extracted search bar
        }
        .padding([.horizontal, .top], 24)
        .padding(.bottom, 12)
        .background(backgroundColor) // Use platform background
    }

    /// Settings button (extracted for clarity)
    private var settingsButton: some View {
        Button(action: {}) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 24))
                .foregroundColor(.primary)
        }
        .buttonStyle(plainOrBorderlessButtonStyle) // Platform-agnostic style
    }

    /// Search bar (extracted for clarity)
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Ask me anything or search for capabilities...", text: $searchQuery)
                .textFieldStyle(plainOrAutomaticTextFieldStyle) // Platform-agnostic style

            if !searchQuery.isEmpty {
                clearSearchButton // Extracted clear button
            }

            askButton // Extracted ask button
        }
        .padding(12)
        .background(backgroundColor.opacity(0.8)) // Slightly adjusted opacity
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    /// Clear search button (extracted)
    private var clearSearchButton: some View {
        Button(action: { searchQuery = "" }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
        }
        .buttonStyle(plainOrBorderlessButtonStyle) // Platform-agnostic style
    }

    /// Ask button (extracted)
    private var askButton: some View {
        Button(action: startChatAction) { // Uses the injected action
            Text("Ask")
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue) // Consider using accentColor
                .cornerRadius(8)
        }
        .buttonStyle(plainOrBorderlessButtonStyle) // Platform-agnostic style
    }


    /// View for the horizontal category pills
    private var categorySelectorView: some View {
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
        // Add a subtle background or border if needed for visual separation
        // .background(backgroundColor.shadow(radius: 1)) // Example
    }

    /// View for the main scrollable content area
    private var mainContentScrollView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Filter content based on selectedCategory if needed here
                // For now, showing all sections
                quickActionsSection
                advancedToolsSection
                recentSessionsSection
            }
            .padding(24)
        }
    }

    // --- Sections (Extracted for Readability) ---

    private var quickActionsSection: some View {
        SectionView(title: "Quick Actions", icon: "bolt") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                ActionButton(
                    icon: "terminal", text: "Execute Command", color: .blue,
                    description: "Run custom instructions"
                )
                ActionButton(
                    icon: "brain", text: "Think For Me", color: .purple,
                    description: "Solve complex problems"
                )
                ActionButton(
                    icon: "doc.text.magnifyingglass", text: "Research", color: .indigo,
                    description: "Find information on any topic"
                )
                ActionButton(
                    icon: "folder.badge.plus", text: "Organize Notes", color: .green,
                    description: "Collate and structure information"
                )
            }
        }
    }

    private var advancedToolsSection: some View {
        SectionView(title: "Advanced Tools", icon: "gearshape.2") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                ActionButton(
                    icon: "text.book.closed", text: "Essay Writer", color: .pink,
                    description: "Create well-structured essays"
                )
                ActionButton(
                    icon: "chart.pie", text: "Data Analysis", color: .orange,
                    description: "Interpret and visualize data"
                )
                ActionButton(
                    icon: "list.bullet.clipboard", text: "Project Planner", color: .teal,
                    description: "Break down complex projects"
                )
                ActionButton(
                    icon: "lightbulb", text: "Idea Generator", color: .yellow,
                    description: "Creative brainstorming"
                )
            }
        }
    }

    private var recentSessionsSection: some View {
        SectionView(title: "Recent Sessions", icon: "clock") {
            VStack(spacing: 12) {
                RecentSessionCard(
                    title: "Research: Quantum Computing Applications",
                    preview: "Collected 23 sources and summarized key findings",
                    icon: "atom", iconColor: .blue, time: "2 hours ago"
                )
                RecentSessionCard(
                    title: "Essay Draft: Impact of AI on Healthcare",
                    preview: "2,500 word draft with 15 citations organized by theme",
                    icon: "heart.text.square", iconColor: .pink, time: "Yesterday"
                )
                RecentSessionCard(
                    title: "Project Plan: Mobile App Development",
                    preview: "Created 8-week timeline with resource allocation",
                    icon: "calendar", iconColor: .green, time: "3 days ago"
                )
            }
        }
    }

    // --- Platform-Agnostic Styles (Helper Computed Properties) ---

    private var plainOrBorderlessButtonStyle: some PrimitiveButtonStyle {
        #if os(macOS)
        return PlainButtonStyle()
        #else
        return BorderlessButtonStyle() // iOS equivalent
        #endif
    }

    private var plainOrAutomaticTextFieldStyle: some TextFieldStyle {
        #if os(macOS)
        return PlainTextFieldStyle()
        #else
        // On iOS, .automatic often works well within standard containers,
        // or choose .roundedBorder if you prefer that look.
        return DefaultTextFieldStyle()
        #endif
    }

    // --- Nested Structs (Categories and Subviews) ---

    /// Categories for AI agent capabilities (Enum remains the same)
    enum AgentCategory: String, CaseIterable, Identifiable {
        case all = "All", research = "Research", writing = "Writing", organization = "Organization", analysis = "Analysis", creative = "Creative"
        var id: String { rawValue }
        var icon: String { /* ... icon logic ... */
             switch self {
                 case .all: "square.grid.2x2"; case .research: "magnifyingglass.circle"; case .writing: "pencil.and.document"; case .organization: "folder.badge.gearshape"; case .analysis: "chart.bar.xaxis"; case .creative: "paintbrush.pointed"
             }
        }
        var color: Color { /* ... color logic ... */
             switch self {
                 case .all: .blue; case .research: .indigo; case .writing: .purple; case .organization: .green; case .analysis: .orange; case .creative: .pink
             }
        }
    }
} // End of HomeView


// MARK: - Subviews (Modified for Platform Agnosticism)

/// Category selector pill
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
            .cornerRadius(20) // Consider clipShape(Capsule()) for pill shape
        }
        .buttonStyle(plainOrBorderlessButtonStyle) // Use helper
    }

    // Duplicated helper for convenience within this scope
    private var plainOrBorderlessButtonStyle: some PrimitiveButtonStyle {
        #if os(macOS)
        return PlainButtonStyle()
        #else
        return BorderlessButtonStyle()
        #endif
    }
}

/// Section view with title
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
                    .foregroundColor(.blue) // Consider .accentColor
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(plainOrBorderlessButtonStyle) // Use helper
            }
            content
        }
        .padding(20)
        .background(sectionBackground) // Use helper for background/shadow
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(16) // Apply cornerRadius after overlay if stroke is desired on edge
    }

    // Helper for platform-specific background/shadow
    @ViewBuilder private var sectionBackground: some View {
        #if os(macOS)
        // Use window background and shadow on macOS
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.windowBackgroundColor))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        #else
        // Use system background on iOS (less emphasis on shadows typical)
        RoundedRectangle(cornerRadius: 16)
             .fill(Color(.secondarySystemGroupedBackground)) // Or .systemGroupedBackground
        #endif
    }

    // Duplicated helper for convenience
    private var plainOrBorderlessButtonStyle: some PrimitiveButtonStyle {
        #if os(macOS)
        return PlainButtonStyle()
        #else
        return BorderlessButtonStyle()
        #endif
    }
}


/// Enhanced action button
struct ActionButton: View {
    let icon: String
    let text: String
    let color: Color
    let description: String

    var body: some View {
        // Wrap in Button if the whole card should be tappable
        // Button(action: { /* Action for this button */ }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(color)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Spacer()
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(color.opacity(0.7))
                }
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(height: 30, alignment: .top) // Give description consistent space
            }
            .padding(16)
            .frame(minHeight: 140, alignment: .top) // Ensure minimum height
            .background(cardBackground) // Use helper
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(16) // Apply after overlay
        // }
        // .buttonStyle(.plain) // Or custom style if wrapped in Button
    }

    // Background helper
    private var cardBackground: some View {
        #if os(macOS)
        return RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        #else
        return RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        #endif
    }
}


/// Recent session card
struct RecentSessionCard: View {
    let title: String
    let preview: String
    let icon: String
    let iconColor: Color
    let time: String

    var body: some View {
         // Button(action: { /* Action for this card */ }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(iconColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

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
                VStack(alignment: .trailing, spacing: 4) {
                    Text(time)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Button(action: { /* Action for Continue button */ }) { // Make only "Continue" tappable
                        Text("Continue")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue) // Use accentColor?
                    }
                    .buttonStyle(plainOrBorderlessButtonStyle) // Use helper
                }
            }
            .padding(16)
            .background(cardBackground) // Use helper
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(12) // Apply after overlay
        // }
        // .buttonStyle(.plain) // If whole card is button
    }

    // Background helper
    private var cardBackground: some View {
        #if os(macOS)
        return RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        #else
        return RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        #endif
    }

    // Button style helper
    private var plainOrBorderlessButtonStyle: some PrimitiveButtonStyle {
        #if os(macOS)
        return PlainButtonStyle()
        #else
        return BorderlessButtonStyle()
        #endif
    }
}

// MARK: - Preview
#Preview {
    // Provide a dummy action for the preview
    HomeView(startChatAction: { print("Start Chat Tapped") })
        // Add frame constraints to preview if needed for layout testing
        // .frame(width: 900, height: 700)
}
