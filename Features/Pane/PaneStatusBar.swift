import SwiftUI

struct PaneStatusBar: View {
    @Bindable var state: PaneState

    private static let barDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.usesGroupingSeparator = true
        return f
    }()

    private var statusText: String {
        guard let id = state.cursorID else {
            return "— | — | ____ | —"
        }
        if let volume = state.mountedVolumes.first(where: { $0.id == id }) {
            return "\(Self.decimal(volume.freeBytes)) / \(Self.decimal(volume.totalBytes)) | — | ____ | \(volume.name)"
        }
        guard let entry = state.entries.first(where: { $0.id == id }) else {
            return "— | — | ____ | —"
        }
        let bytes = entry.isDirectory ? "—" : Self.decimal(entry.size)
        let date = Self.barDateFormatter.string(from: entry.modificationDate)
        return "\(bytes) | \(date) | \(entry.attrsFourCharacter) | \(fullName(entry))"
    }

    var body: some View {
        Text(statusText)
            .font(.system(size: 12).monospacedDigit())
            .foregroundStyle(Color(white: 0.7))
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 24)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.05))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
            }
            .accessibilityIdentifier("pane.\(state.slot.rawValue).statusbar")
    }

    private static func decimal(_ value: Int64) -> String {
        decimalFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func fullName(_ entry: DirectoryEntry) -> String {
        if entry.isParentLink { return ".." }
        if entry.ext.isEmpty { return entry.displayName }
        return "\(entry.displayName).\(entry.ext)"
    }
}
