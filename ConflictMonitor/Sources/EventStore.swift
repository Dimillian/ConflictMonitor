import Foundation

@MainActor
final class EventStore: ObservableObject {
    @Published private(set) var events: [ConflictEvent] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdatedAt: Date?

    private let client: EventsClient
    private let minimumRefreshInterval: TimeInterval = 20
    private var lastRefreshAttempt: Date?

    init(client: EventsClient = EventsClient()) {
        self.client = client
    }

    func refreshIfNeeded(force: Bool = false) async {
        if !force,
           let lastRefreshAttempt,
           Date().timeIntervalSince(lastRefreshAttempt) < minimumRefreshInterval {
            return
        }

        await refresh()
    }

    func refresh() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        lastRefreshAttempt = Date()

        defer { isLoading = false }

        do {
            events = try await client.fetchLatestEvents(limit: 25)
            lastUpdatedAt = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

