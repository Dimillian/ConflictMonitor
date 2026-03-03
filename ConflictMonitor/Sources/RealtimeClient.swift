import Foundation

struct RealtimeMessage: Decodable {
    let table: String
    let action: String
}

final class RealtimeClient {
    enum State: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(String)
    }

    var onMessage: ((RealtimeMessage) -> Void)?
    var onStateChange: ((State) -> Void)?

    private let socketURL = URL(string: "wss://monitor-the-situation.com/ws")!
    private let session: URLSession

    private var socketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    private var reconnectTask: DispatchWorkItem?
    private var reconnectAttempt = 0
    private var shouldReconnect = false

    init(session: URLSession = .shared) {
        self.session = session
    }

    func connect() {
        shouldReconnect = true
        guard socketTask == nil else { return }
        openSocket()
    }

    func disconnect() {
        shouldReconnect = false
        reconnectTask?.cancel()
        reconnectTask = nil
        stopPing()
        socketTask?.cancel(with: .normalClosure, reason: nil)
        socketTask = nil
        onStateChange?(.disconnected)
    }

    private func openSocket() {
        onStateChange?(.connecting)
        let task = session.webSocketTask(with: socketURL)
        socketTask = task
        task.resume()
        startPing(for: task)
        receiveLoop(for: task)
    }

    private func receiveLoop(for task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            guard let self else { return }
            guard self.socketTask === task else { return }

            switch result {
            case .success(let message):
                self.reconnectAttempt = 0
                self.onStateChange?(.connected)
                self.handleMessage(message)
                self.receiveLoop(for: task)
            case .failure(let error):
                self.handleFailure(error, for: task)
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        let payloadData: Data?
        switch message {
        case .data(let data):
            payloadData = data
        case .string(let string):
            payloadData = string.data(using: .utf8)
        @unknown default:
            payloadData = nil
        }

        guard let payloadData,
              let parsed = try? JSONDecoder().decode(RealtimeMessage.self, from: payloadData) else {
            return
        }

        onMessage?(parsed)
    }

    private func handleFailure(_ error: Error, for task: URLSessionWebSocketTask) {
        guard socketTask === task else { return }
        stopPing()
        socketTask = nil
        onStateChange?(.failed(error.localizedDescription))

        guard shouldReconnect else {
            onStateChange?(.disconnected)
            return
        }

        scheduleReconnect()
    }

    private func scheduleReconnect() {
        reconnectTask?.cancel()

        let baseDelay = min(pow(2.0, Double(reconnectAttempt)), 30.0)
        let jitteredDelay = baseDelay * Double.random(in: 0.8 ... 1.2)
        reconnectAttempt += 1

        let task = DispatchWorkItem { [weak self] in
            guard let self, self.shouldReconnect else { return }
            self.openSocket()
        }

        reconnectTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + jitteredDelay, execute: task)
    }

    private func startPing(for task: URLSessionWebSocketTask) {
        stopPing()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard self.socketTask === task else { return }
            task.sendPing { [weak self] error in
                guard let self else { return }
                if let error {
                    self.handleFailure(error, for: task)
                } else {
                    self.onStateChange?(.connected)
                }
            }
        }
    }

    private func stopPing() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
}

