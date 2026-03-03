import Foundation

struct EventsClient {
    private let session: URLSession
    private let endpoint = URL(string: "https://monitor-the-situation.com/api/events")!

    init(session: URLSession = .eventsSession) {
        self.session = session
    }

    func fetchLatestEvents() async throws -> [ConflictEvent] {
        var request = URLRequest(url: endpoint)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw APIError.httpStatus(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let events = try decoder.decode([ConflictEvent].self, from: data)
        return events.sorted(by: { $0.createdAtDate > $1.createdAtDate })
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .httpStatus(let statusCode):
            return "Request failed with HTTP \(statusCode)."
        }
    }
}

private extension URLSession {
    static let eventsSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 15
        return URLSession(configuration: configuration)
    }()
}
