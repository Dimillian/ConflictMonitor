import SwiftUI

struct EventRowView: View {
    let event: ConflictEvent
    let isExpanded: Bool
    let signals: [ConflictSignal]
    let isSignalsLoading: Bool
    let signalsError: String?
    let onToggleExpanded: () -> Void
    let onOpenEventInBrowser: () -> Void
    let onOpenSignal: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                onToggleExpanded()
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        HStack(spacing: 4) {
                            Text(categoryBadgeLabel)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(categoryBadgeColor.opacity(0.2))
                                .foregroundStyle(categoryBadgeColor)
                                .clipShape(Capsule())

                            separatorDot

                            Text(event.shortLocation)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            if let confidenceText {
                                separatorDot
                                Text(confidenceText)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            separatorDot

                            Text(shortRelativeTime)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        if let summaryText {
                            Text(summaryText)
                                .font(.system(size: 11))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("No summary available.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.12))
                    )

                    HStack(spacing: 10) {
                        Button("Open") {
                            onOpenEventInBrowser()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Text(signalsCountText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)

                        Spacer()
                    }

                    if isSignalsLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading signals...")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    } else if let signalsError {
                        Text(signalsError)
                            .font(.system(size: 10))
                            .foregroundStyle(.red)
                    } else if signals.isEmpty {
                        Text("No signals available.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(signals.prefix(6)) { signal in
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    if let url = signal.urlValue {
                                        Button {
                                            onOpenSignal(url)
                                        } label: {
                                            signalSourcePill(signal.sourceName)
                                        }
                                        .buttonStyle(.plain)
                                        .help(url.absoluteString)
                                    } else {
                                        signalSourcePill(signal.sourceName)
                                    }

                                    Text(signal.displayText)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)

                                    Spacer(minLength: 6)
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isExpanded)
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

    private var normalizedCategory: String {
        event.category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var categoryBadgeLabel: String {
        switch normalizedCategory {
        case "conflict":
            return "Conflict"
        case "political":
            return "Political"
        case "humanitarian":
            return "Humanitarian"
        case "economic":
            return "Economic"
        case "disaster":
            return "Disaster"
        default:
            return event.category.capitalized
        }
    }

    private var categoryBadgeColor: Color {
        switch normalizedCategory {
        case "conflict":
            return .red
        case "political":
            return .purple
        case "humanitarian":
            return .teal
        case "economic":
            return .green
        case "disaster":
            return .orange
        default:
            return .gray
        }
    }

    private var shortRelativeTime: String {
        let seconds = max(0, Int(Date().timeIntervalSince(event.createdAtDate)))
        if seconds < 60 {
            return "\(seconds)s"
        }
        if seconds < 3600 {
            return "\(seconds / 60)m"
        }
        if seconds < 86_400 {
            return "\(seconds / 3600)h"
        }
        return "\(seconds / 86_400)d"
    }

    private var confidenceText: String? {
        guard let confidence = event.confidence else { return nil }
        let normalized = min(max(confidence, 0), 100)
        return "Conf \(normalized)%"
    }

    private var summaryText: String? {
        guard let summary = event.summary?.trimmingCharacters(in: .whitespacesAndNewlines),
              !summary.isEmpty else { return nil }
        return summary
    }

    private var separatorDot: some View {
        Text("•")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.secondary.opacity(0.7))
    }

    private var signalsCountText: String {
        let count = signals.count
        return count == 1 ? "1 signal" : "\(count) signals"
    }

    private func signalSourcePill(_ name: String) -> some View {
        Text(name)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.14))
            .clipShape(Capsule())
    }
}
