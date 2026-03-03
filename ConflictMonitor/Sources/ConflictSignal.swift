import Foundation

struct ConflictSignal: Identifiable, Decodable {
    let id: String
    let sourceType: String
    let sourceName: String
    let title: String?
    let content: String?
    let url: String?
    let timestamp: String
    let accountHandle: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sourceType = "source_type"
        case sourceName = "source_name"
        case title
        case content
        case url
        case timestamp
        case accountHandle = "account_handle"
    }

    var timestampDate: Date {
        Self.timestampFormatter.date(from: timestamp) ?? .distantPast
    }

    var urlValue: URL? {
        guard let url, let value = URL(string: url), !url.isEmpty else { return nil }
        return value
    }

    var displayText: String {
        if let title, !title.isEmpty {
            return title
        }
        if let content, !content.isEmpty {
            return content
        }
        return sourceName
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

