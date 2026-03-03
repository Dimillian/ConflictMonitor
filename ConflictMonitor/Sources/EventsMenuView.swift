import SwiftUI

struct EventsMenuView: View {
    @ObservedObject var store: EventStore
    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let websiteURL = URL(string: "https://monitor-the-situation.com")!

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            Group {
                if store.events.isEmpty {
                    emptyState
                } else {
                    eventsList
                }
            }

            footer
        }
        .padding(12)
        .task {
            await store.refreshIfNeeded(force: true)
        }
        .onReceive(refreshTimer) { _ in
            Task {
                await store.refreshIfNeeded()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Latest Conflict Events")
                    .font(.system(size: 13, weight: .semibold))
                Text("monitor-the-situation.com")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if store.isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            Button("Refresh") {
                Task { await store.refreshIfNeeded(force: true) }
            }
            .controlSize(.small)
        }
    }

    private var eventsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(Array(store.events.enumerated()), id: \.element.id) { index, event in
                    EventRowView(event: event)
                    if index < store.events.count - 1 {
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 460)
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

    private var footer: some View {
        HStack {
            if let lastUpdatedAt = store.lastUpdatedAt {
                Text("Updated \(lastUpdatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            } else {
                Text("Not updated yet")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Link("Open Website", destination: websiteURL)
                .font(.system(size: 10, weight: .medium))
        }
    }
}

