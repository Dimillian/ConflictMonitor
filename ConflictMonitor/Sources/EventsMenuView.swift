import SwiftUI

struct EventsMenuView: View {
    @ObservedObject var store: EventStore
    @State private var expandedEventID: String?
    @State private var selectedCategory: CategoryFilter = .all
    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let websiteURL = URL(string: "https://monitor-the-situation.com")!

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            categoryFiltersBar

            Group {
                if store.events.isEmpty {
                    emptyState
                } else if filteredEvents.isEmpty {
                    filteredEmptyState
                } else {
                    eventsList
                }
            }

            footer
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
        .task {
            await store.refreshIfNeeded(force: true)
        }
        .onReceive(refreshTimer) { _ in
            Task {
                await store.refreshIfNeeded()
            }
        }
        .onChange(of: selectedCategory) { _ in
            collapseExpandedIfFilteredOut()
        }
        .onChange(of: store.events.map(\.id)) { _ in
            collapseExpandedIfFilteredOut()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Latest Conflict Events")
                    .font(.system(size: 13, weight: .semibold))
                Text(headerSubtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if store.isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            Button(liveButtonTitle) {
                store.toggleLive()
            }
            .controlSize(.small)
            .buttonStyle(.bordered)
            .tint(liveButtonColor)

            Button("Refresh") {
                Task { await store.refreshIfNeeded(force: true) }
            }
            .controlSize(.small)
        }
    }

    private var eventsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { index, event in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            expandedEventID = expandedEventID == event.id ? nil : event.id
                        }
                    } label: {
                        EventRowView(
                            event: event,
                            isExpanded: expandedEventID == event.id
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < filteredEvents.count - 1 {
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            if store.isLoading {
                Text("Loading latest events...")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                Button("Try Again") {
                    Task { await store.refreshIfNeeded(force: true) }
                }
                .controlSize(.small)
            } else {
                Text("No events available right now.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
    }

    private var filteredEmptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No \(selectedCategory.title.lowercased()) events right now.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
    }

    private var categoryFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(CategoryFilter.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            if category != .all {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 7, height: 7)
                            }
                            Text(category.title)
                                .font(.system(size: 11, weight: .medium))
                            Text("\(categoryCount(for: category))")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(selectedCategory == category ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.15))
                        )
                        .overlay(
                            Capsule().stroke(selectedCategory == category ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var footer: some View {
        HStack {
            Text("monitor-the-situation.com")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            Spacer()

            Link("Open Website", destination: websiteURL)
                .font(.system(size: 10, weight: .medium))
        }
    }

    private var headerSubtitle: String {
        let prefix: String
        if let lastUpdatedAt = store.lastUpdatedAt {
            prefix = "Updated \(lastUpdatedAt.formatted(date: .omitted, time: .shortened))"
        } else {
            prefix = "Not updated yet"
        }
        return "\(prefix) • \(itemsCountText)"
    }

    private var liveButtonTitle: String {
        store.isLiveEnabled ? "Live" : "Live Off"
    }

    private var liveButtonColor: Color {
        store.isLiveEnabled ? .green : .gray
    }

    private var itemsCountText: String {
        let count = store.events.count
        return count == 1 ? "1 item" : "\(count) items"
    }

    private var filteredEvents: [ConflictEvent] {
        guard selectedCategory != .all else { return store.events }
        return store.events.filter { event in
            event.category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == selectedCategory.rawValue
        }
    }

    private func categoryCount(for category: CategoryFilter) -> Int {
        guard category != .all else { return store.events.count }
        return store.events.reduce(into: 0) { partialResult, event in
            let normalized = event.category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if normalized == category.rawValue {
                partialResult += 1
            }
        }
    }

    private func collapseExpandedIfFilteredOut() {
        guard let expandedEventID else { return }
        let stillVisible = filteredEvents.contains { $0.id == expandedEventID }
        if !stillVisible {
            self.expandedEventID = nil
        }
    }
}

private enum CategoryFilter: String, CaseIterable, Identifiable {
    case all
    case conflict
    case political
    case humanitarian
    case economic
    case disaster

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .conflict:
            return "Conflict"
        case .political:
            return "Political"
        case .humanitarian:
            return "Humanitarian"
        case .economic:
            return "Economic"
        case .disaster:
            return "Disaster"
        }
    }

    var color: Color {
        switch self {
        case .all:
            return .gray
        case .conflict:
            return .red
        case .political:
            return .purple
        case .humanitarian:
            return .teal
        case .economic:
            return .green
        case .disaster:
            return .orange
        }
    }
}
