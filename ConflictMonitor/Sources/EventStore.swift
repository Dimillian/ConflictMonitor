import Foundation

@MainActor
final class EventStore: ObservableObject {
    enum LiveStatus: Equatable {
        case disconnected
        case connecting
        case connected
        case failed
    }

    @Published private(set) var events: [ConflictEvent] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdatedAt: Date?
    @Published private(set) var isLiveEnabled = true
    @Published private(set) var liveStatus: LiveStatus = .disconnected
    @Published private(set) var signalsByEventID: [String: [ConflictSignal]] = [:]
    @Published private(set) var signalsLoadingEventIDs: Set<String> = []
    @Published private(set) var signalErrorsByEventID: [String: String] = [:]

    private let client: EventsClient
    private let realtimeClient: RealtimeClient
    private let minimumRefreshInterval: TimeInterval = 20
    private var lastRefreshAttempt: Date?
    private var realtimeRefreshTask: Task<Void, Never>?

    init(
        client: EventsClient = EventsClient(),
        realtimeClient: RealtimeClient = RealtimeClient()
    ) {
        self.client = client
        self.realtimeClient = realtimeClient
        bindRealtimeCallbacks()
        realtimeClient.connect()
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
            events = try await client.fetchLatestEvents()
            lastUpdatedAt = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleLive() {
        isLiveEnabled.toggle()
        if isLiveEnabled {
            realtimeClient.connect()
        } else {
            realtimeClient.disconnect()
            liveStatus = .disconnected
        }
    }

    func loadSignals(for eventID: String, force: Bool = false) async {
        if !force, signalsByEventID[eventID] != nil {
            return
        }
        if signalsLoadingEventIDs.contains(eventID) {
            return
        }

        signalsLoadingEventIDs.insert(eventID)
        signalErrorsByEventID[eventID] = nil

        defer {
            signalsLoadingEventIDs.remove(eventID)
        }

        do {
            signalsByEventID[eventID] = try await client.fetchSignals(for: eventID)
        } catch {
            signalErrorsByEventID[eventID] = error.localizedDescription
        }
    }

    private func bindRealtimeCallbacks() {
        realtimeClient.onStateChange = { [weak self] state in
            guard let self else { return }
            Task { @MainActor in
                switch state {
                case .disconnected:
                    if self.isLiveEnabled {
                        self.liveStatus = .connecting
                    } else {
                        self.liveStatus = .disconnected
                    }
                case .connecting:
                    self.liveStatus = .connecting
                case .connected:
                    self.liveStatus = .connected
                case .failed:
                    self.liveStatus = .failed
                }
            }
        }

        realtimeClient.onMessage = { [weak self] message in
            guard let self else { return }
            Task { @MainActor in
                self.handleRealtimeMessage(message)
            }
        }
    }

    private func handleRealtimeMessage(_ message: RealtimeMessage) {
        guard isLiveEnabled else { return }

        // The websocket events are table/action notifications (no full payload),
        // so we debounce and refresh from REST when relevant tables change.
        let watchedTables: Set<String> = [
            "all_events",
            "all_signals"
        ]

        guard watchedTables.contains(message.table) else { return }

        realtimeRefreshTask?.cancel()
        realtimeRefreshTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard let self else { return }
            self.signalsByEventID.removeAll()
            self.signalErrorsByEventID.removeAll()
            await self.refreshIfNeeded(force: true)
        }
    }
}
