import SwiftUI

struct EventRowView: View {
    let event: ConflictEvent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(event.shortLocation)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(event.category.capitalized)
                    Text(event.createdAtDate, style: .relative)
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text("S\(event.severity)")
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(severityColor.opacity(0.2))
                .foregroundStyle(severityColor)
                .clipShape(Capsule())
        }
    }

    private var severityColor: Color {
        switch event.severity {
        case 5:
            return .red
        case 4:
            return .orange
        case 3:
            return .yellow
        case 2:
            return .mint
        default:
            return .green
        }
    }
}

