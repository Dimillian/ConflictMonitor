import Foundation

struct ConflictEvent: Identifiable, Decodable {
    let id: String
    let title: String
    let summary: String?
    let category: String
    let subtype: String?
    let severity: Int
    let locationName: String?
    let country: String?
    let region: String?
    let confidence: Int?
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let sourceTypes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case category
        case subtype
        case severity
        case locationName = "location_name"
        case country
        case region
        case confidence
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case sourceTypes = "source_types"
    }

    var createdAtDate: Date {
        Self.timestampFormatter.date(from: createdAt) ?? .distantPast
    }

    var shortLocation: String {
        if let locationName, !locationName.isEmpty {
            return locationName
        }
        if let country, !country.isEmpty {
            return country
        }
        if let region, !region.isEmpty {
            return region
        }
        return "Unknown location"
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

