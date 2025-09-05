//
//  MobileContactsToolView.swift
//  PetalsiOS
//
//  Created by Aadi Shiv Malhotra on 9/4/25.
//

import SwiftUI
import PetalCore

/// A compact, high-quality mobile UI for rendering results from `petalContactsTool`.
///
/// This view parses a tool-formatted string in the associated `ChatMessage` and
/// renders a performant, Apple-like list experience that gracefully handles
/// large contact sets. Supports quick search, alphabetical grouping, expandable
/// rows, and adaptive layouts.
struct MobileContactsToolView: View {
    /// Chat message that contains the contacts output as a newline-separated list.
    /// Each line is expected in the shape:
    /// "Display Name • phone1, phone2 • email1, email2"
    /// Components after the first are optional.
    let message: ChatMessage

    @State private var searchText: String = ""
    @State private var expanded: Set<UUID> = []

    // MARK: Model

    struct ContactItem: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let phones: [String]
        let emails: [String]
    }

    // MARK: Parsing

    private func parseContacts() -> [ContactItem] {
        let lines = message.message
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.map { line in
            // Split on the middle dot delimiter we used when formatting
            let parts = line.components(separatedBy: " • ")
            let name = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "(No Name)"

            var phones: [String] = []
            var emails: [String] = []

            if parts.count >= 2 {
                // Remaining parts can contain phones or emails; split on comma for each part
                for idx in 1..<parts.count {
                    let tokens = parts[idx]
                        .split(separator: ",")
                        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    for token in tokens {
                        if token.contains("@") {
                            emails.append(token)
                        } else {
                            phones.append(token)
                        }
                    }
                }
            }

            return ContactItem(name: name, phones: phones, emails: emails)
        }
    }

    // MARK: Derived Collections

    private var allContacts: [ContactItem] {
        parseContacts()
    }

    private var filteredContacts: [ContactItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allContacts
        }
        let q = searchText.lowercased()
        return allContacts.filter { c in
            if c.name.lowercased().contains(q) { return true }
            if c.phones.contains(where: { $0.lowercased().contains(q) }) { return true }
            if c.emails.contains(where: { $0.lowercased().contains(q) }) { return true }
            return false
        }
    }

    private var groupedContacts: [(key: String, value: [ContactItem])] {
        let dict = Dictionary(grouping: filteredContacts) { (item: ContactItem) -> String in
            let first = item.name.first.map { String($0).uppercased() } ?? "#"
            return first.rangeOfCharacter(from: CharacterSet.letters) != nil ? first : "#"
        }
        return dict.map { ($0.key, $0.value.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) }
            .sorted { lhs, rhs in
                if lhs.key == "#" { return false }
                if rhs.key == "#" { return true }
                return lhs.key < rhs.key
            }
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            searchField
            if groupedContacts.isEmpty {
                emptyState
            } else {
                contactList
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Contacts")
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "5E5CE6"))
            Text("Contacts")
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Text("\(filteredContacts.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search contacts", text: $searchText)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(false)
        }
        .padding(10)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(10)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("No contacts found")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var contactList: some View {
        // Use ScrollView + LazyVStack for smooth performance with large datasets
        ScrollView {
            LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedContacts, id: \.key) { group in
                    Section(header: sectionHeader(group.key)) {
                        ForEach(group.value) { item in
                            contactRow(item)
                                .id(item.id)
                                .contextMenu { contextMenu(for: item) }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: Components

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(Color(UIColor.tertiarySystemBackground))
                )
            Spacer()
        }
        .padding(.horizontal, 2)
    }

    private func contactRow(_ item: ContactItem) -> some View {
        Button {
            toggleExpanded(item.id)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                avatar(for: item.name)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)

                    if isExpanded(item.id) {
                        // Show all phones and emails
                        VStack(alignment: .leading, spacing: 4) {
                            if !item.phones.isEmpty {
                                WrapBadges(items: item.phones, systemImage: "phone.fill", tint: .green)
                            }
                            if !item.emails.isEmpty {
                                WrapBadges(items: item.emails, systemImage: "envelope.fill", tint: .blue)
                            }
                        }
                    } else {
                        // Compact view shows up to two phones and two emails, with wrapping
                        VStack(alignment: .leading, spacing: 4) {
                            if !item.phones.isEmpty {
                                WrapBadges(items: Array(item.phones.prefix(2)), systemImage: "phone.fill", tint: .green)
                            }
                            if !item.emails.isEmpty {
                                WrapBadges(items: Array(item.emails.prefix(2)), systemImage: "envelope.fill", tint: .blue)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isExpanded(item.id) ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(item.name)
    }

    private func avatar(for name: String) -> some View {
        let initials = initialsFromName(name)
        let color = colorForName(name)
        return ZStack {
            Circle().fill(color.opacity(0.18))
            Text(initials)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(width: 28, height: 28)
    }

    private func badge(text: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundColor(tint)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }

    private func contextMenu(for item: ContactItem) -> some View {
        Group {
            if let phone = item.phones.first {
                Button {
                    UIPasteboard.general.string = phone
                } label: { Label("Copy Phone", systemImage: "doc.on.doc") }
            }
            if let email = item.emails.first {
                Button {
                    UIPasteboard.general.string = email
                } label: { Label("Copy Email", systemImage: "doc.on.doc") }
            }
            Button {
                UIPasteboard.general.string = item.name
            } label: { Label("Copy Name", systemImage: "doc.on.doc") }
        }
    }

    // MARK: Helpers

    private func isExpanded(_ id: UUID) -> Bool { expanded.contains(id) }
    private func toggleExpanded(_ id: UUID) {
        if expanded.contains(id) { expanded.remove(id) } else { expanded.insert(id) }
    }

    private func initialsFromName(_ name: String) -> String {
        let comps = name.split(separator: " ")
        let first = comps.first?.first
        let second = comps.dropFirst().first?.first
        let initials = String([first, second].compactMap { $0 })
        return initials.isEmpty ? "?" : initials.uppercased()
    }

    private func colorForName(_ name: String) -> Color {
        var hasher = Hasher()
        hasher.combine(name)
        let value = hasher.finalize()
        let colors: [Color] = [.blue, .teal, .indigo, .purple, .pink, .orange, .green]
        let index = abs(value) % colors.count
        return colors[index]
    }
}

/// A flexible badge layout that wraps items across multiple lines.
private struct WrapBadges: View {
    let items: [String]
    let systemImage: String
    let tint: Color

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        self.generateContent()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(viewHeightReader($totalHeight))
    }

    private func generateContent() -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                badge(text: item)
                    .padding([.horizontal, .vertical], 2)
                    .alignmentGuide(.leading, computeValue: { d in
                        if abs(width - d.width) > UIScreen.main.bounds.width - 100 {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        width -= d.width
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        return result
                    })
            }
        }
    }

    private func badge(text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .semibold))
            Text(text)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundColor(tint)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
        }
        .onPreferenceChange(HeightPreferenceKey.self) { height in
            binding.wrappedValue = height
        }
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

#Preview {
    let text = """
    Jane Appleseed • (555) 123-9876, +1-555-000-1111 • jane@apple.com
    John Doe • (555) 222-3333 • john.doe@example.com, jd@example.org
    Alex   • alex@example.com
    (No Name)
    """
    let msg = ChatMessage(message: text, participant: .llm)
    return MobileContactsToolView(message: msg)
        .padding()
}

