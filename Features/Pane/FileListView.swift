import AppKit
import SwiftUI

struct FileListView: View {
    @Bindable var state: PaneState
    let isActive: Bool
    let onActivate: @MainActor () -> Void
    let onRowDoubleClick: @MainActor () -> Void

    var body: some View {
        Group {
            if let err = state.error {
                ContentUnavailableView(
                    "열 수 없음",
                    systemImage: "lock.fill",
                    description: Text(err)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { proxy in
                    let layout = FileListLayout.available(in: proxy.size.width, rows: state.paneRows)
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(state.paneRows) { row in
                                    FileListRow(
                                        state: state,
                                        row: row,
                                        isActive: isActive,
                                        sanitizedBasename: sanitizedBasename(row.id),
                                        layout: layout,
                                        onActivate: onActivate,
                                        onRowDoubleClick: onRowDoubleClick
                                    )
                                }
                            }
                            .padding(.horizontal, FileListLayout.outerPadding)
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
        .background(FileColorToken.panelBackground)
    }

    private func sanitizedBasename(_ url: URL) -> String {
        let name = url.lastPathComponent
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let mapped = name.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        let s = String(mapped)
        return s.isEmpty ? "item" : s
    }
}

private struct FileListLayout {
    static let outerPadding: CGFloat = 6
    static let rowHeight: CGFloat = 20

    // dateWidth: "yyyy-MM-dd" 문자열을 monospacedDigit size 11 로 한 번만 측정
    static let dateWidth: CGFloat = {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        ]
        return ceil(("2026-05-17" as NSString).size(withAttributes: attrs).width) + 4
    }()

    let selectionMarkerWidth: CGFloat = 12
    let iconWidth: CGFloat = 14
    let extWidth: CGFloat = 52
    let sizeWidth: CGFloat = 56
    var dateWidth: CGFloat { Self.dateWidth }
    let timeWidth: CGFloat = 36
    let attrsWidth: CGFloat = 36
    let nameWidth: CGFloat
    let descriptionWidth: CGFloat

    static func available(in totalWidth: CGFloat, rows: [PaneRow]) -> FileListLayout {
        // fixed = 12+14+52+56+dateWidth+36+36
        // spacing: left-group 2×8=16, mid 1×12=12, right-group 5×12=60 → 88
        let fixed = 12 + 14 + 52 + 56 + Self.dateWidth + 36 + 36
        let spacing: CGFloat = 88
        let forFlexible = max(0, totalWidth - outerPadding * 2 - fixed - spacing)

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .regular)
        ]
        let maxContent = rows.map { row -> CGFloat in
            let name: String
            switch row.kind {
            case let .file(entry): name = entry.displayName
            case let .volume(volume): name = volume.name
            }
            return (name as NSString).size(withAttributes: nameAttrs).width
        }.max() ?? 0

        let maxAllowed = forFlexible * 0.75
        let nameWidth = max(90, min(maxContent + 12, maxAllowed))
        return FileListLayout(
            nameWidth: nameWidth,
            descriptionWidth: max(0, forFlexible - nameWidth)
        )
    }
}

private struct FileListHeader: View {
    let layout: FileListLayout

    var body: some View {
        HStack(spacing: 8) {
            Text("").frame(width: layout.selectionMarkerWidth, alignment: .center)
            Text("").frame(width: layout.iconWidth, alignment: .center)
            Text("Name").frame(width: layout.nameWidth, alignment: .leading)
            Text("Ext").frame(width: layout.extWidth, alignment: .leading)
            Text("Size").frame(width: layout.sizeWidth, alignment: .trailing)
            Text("Date").frame(width: layout.dateWidth, alignment: .leading)
            Text("Time").frame(width: layout.timeWidth, alignment: .leading)
            Text("Attrs").frame(width: layout.attrsWidth, alignment: .leading)
            Text("Description").frame(width: layout.descriptionWidth, alignment: .leading)
        }
        .font(.system(size: 11).monospacedDigit())
        .lineLimit(1)
        .foregroundStyle(Color(white: 0.45))
        .padding(.horizontal, FileListLayout.outerPadding)
        .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
    }
}

private struct FileListRow: View {
    @Bindable var state: PaneState
    let row: PaneRow
    let isActive: Bool
    let sanitizedBasename: String
    let layout: FileListLayout
    let onActivate: @MainActor () -> Void
    let onRowDoubleClick: @MainActor () -> Void

    @State private var lastTapAt: Date?
    @State private var lastTapRowID: URL?

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Text(isMarked ? "▶" : "")
                    .font(.system(size: 11).monospaced())
                    .foregroundStyle(.yellow)
                    .frame(width: layout.selectionMarkerWidth, alignment: .center)

                Image(systemName: iconName)
                    .font(.system(size: 11))
                    .foregroundStyle(iconColor)
                    .frame(width: layout.iconWidth, alignment: .center)

                Text(name)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(nameColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: layout.nameWidth, alignment: .leading)
                    .clipped()
            }

            HStack(spacing: 12) {
                extView
                    .frame(width: layout.extWidth, alignment: .leading)

                if case let .volume(volume) = row.kind {
                    Text("\(Self.formatBytes(volume.freeBytes)) 남음")
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(Color(white: 0.78))
                        .frame(
                            width: layout.sizeWidth + layout.dateWidth + layout.timeWidth + layout.attrsWidth + 3 * 12,
                            alignment: .leading
                        )
                } else {
                    sizeView
                        .frame(width: layout.sizeWidth, alignment: .trailing)

                    Text(date)
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(Color(white: 0.7))
                        .frame(width: layout.dateWidth, alignment: .leading)

                    Text(time)
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(Color(white: 0.7))
                        .frame(width: layout.timeWidth, alignment: .leading)

                    Text(attrs)
                        .font(.system(size: 11).monospaced())
                        .foregroundStyle(Color(white: 0.55))
                        .frame(width: layout.attrsWidth, alignment: .leading)
                }

                descriptionView
                    .frame(width: layout.descriptionWidth, alignment: .leading)
            }
        }
        .lineLimit(1)
        .truncationMode(.tail)
        .frame(maxWidth: .infinity, minHeight: FileListLayout.rowHeight, alignment: .leading)
        .background(rowBackground)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(rowIdentifier)
        .accessibilityValue(accessibilitySelectionValue)
        .onTapGesture {
            handleTap()
        }
    }

    private var isSelected: Bool {
        state.cursorID == row.id
    }

    private var isMarked: Bool {
        state.selection.contains(row.id)
    }

    @ViewBuilder
    private var rowBackground: some View {
        ZStack {
            if isMarked {
                Rectangle().fill(FileColorToken.markedBackground)
            }
            if isSelected {
                Rectangle()
                    .fill(isActive ? FileColorToken.selectionActiveBackground : FileColorToken.selectionInactiveBackground)
            }
        }
    }

    private var rowIdentifier: String {
        switch row.kind {
        case let .file(entry):
            return entry.isParentLink
                ? "pane.\(state.slot.rawValue).row.parent"
                : "pane.\(state.slot.rawValue).row.\(sanitizedBasename)"
        case .volume:
            return "pane.\(state.slot.rawValue).row.volume.\(sanitizedBasename)"
        }
    }

    private var accessibilitySelectionValue: String {
        guard isSelected else { return "not-selected" }
        return isActive ? "active-selected" : "inactive-selected"
    }

    private var name: String {
        switch row.kind {
        case let .file(entry): entry.displayName
        case let .volume(volume): volume.name
        }
    }

    @ViewBuilder
    private var extView: some View {
        switch row.kind {
        case let .file(entry):
            if entry.isParentLink || entry.isDirectory {
                Color.clear
            } else {
                Text(entry.ext)
                    .font(.system(size: 12))
                    .foregroundStyle(nameColor)
            }
        case let .volume(volume):
            VolumeUsageBar(usedRatio: usedRatio(for: volume))
        }
    }

    @ViewBuilder
    private var sizeView: some View {
        switch row.kind {
        case let .file(entry):
            if entry.isParentLink {
                Color.clear
            } else if entry.isDirectory {
                Text("[폴더]")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(Color(white: 0.45))
            } else {
                Text(Self.formatBytes(entry.size))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(Color(white: 0.85))
            }
        case let .volume(volume):
            Text("\(Self.formatBytes(volume.freeBytes)) 남음")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(Color(white: 0.78))
        }
    }

    private static func formatBytes(_ bytes: Int64) -> String {
        let b = Double(bytes)
        let units: [(Double, String)] = [
            (1_000_000_000_000, "TB"),
            (1_000_000_000, "GB"),
            (1_000_000, "MB"),
            (1_000, "KB"),
        ]
        for (threshold, unit) in units {
            if b >= threshold {
                let value = b / threshold
                return value < 10
                    ? String(format: "%.1f \(unit)", value)
                    : String(format: "%.0f \(unit)", value)
            }
        }
        return "\(bytes) B"
    }

    private var date: String {
        switch row.kind {
        case let .file(entry):
            entry.isParentLink ? "" : entry.relativeOrCalendarDate()
        case .volume:
            ""
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f
    }()

    private var time: String {
        switch row.kind {
        case let .file(entry):
            entry.isParentLink ? "" : Self.timeFormatter.string(from: entry.modificationDate)
        case .volume:
            ""
        }
    }

    private var attrs: String {
        switch row.kind {
        case let .file(entry): entry.isParentLink ? "" : entry.attrsFourCharacter
        case .volume: ""
        }
    }

    private var iconName: String {
        switch row.kind {
        case let .file(entry):
            if entry.isParentLink { return "arrow.turn.left.up" }
            if entry.isDirectory { return "folder.fill" }
            switch entry.ext.lowercased() {
            case "md", "txt", "rtf": return "doc.text"
            case "xlsx", "xls", "csv": return "tablecells"
            case "png", "jpg", "jpeg", "gif", "heic", "webp": return "photo"
            case "swift", "py", "ts", "tsx", "js", "jsx", "rs", "go", "c", "h", "cpp", "hpp":
                return "chevron.left.forwardslash.chevron.right"
            case "zip", "tar", "gz", "tgz", "bz2", "xz", "7z": return "archivebox"
            case "mp4", "mov", "m4v", "mp3", "wav", "aac", "flac": return "play.rectangle"
            case "iso", "dmg": return "opticaldisc"
            default: return "doc"
            }
        case let .volume(volume):
            switch volume.icon {
            case .internalDrive: return "internaldrive.fill"
            case .external: return "externaldrive.fill"
            case .network: return "network"
            case .cloud: return "icloud.fill"
            }
        }
    }

    private var iconColor: Color {
        switch row.kind {
        case let .file(entry): FileColorToken.color(for: entry)
        case .volume: Color(white: 0.85)
        }
    }

    private var nameColor: Color {
        switch row.kind {
        case let .file(entry): FileColorToken.color(for: entry)
        case .volume: Color(white: 0.85)
        }
    }


    @ViewBuilder
    private var descriptionView: some View {
        switch row.kind {
        case .file, .volume:
            Color.clear
        }
    }

    private func usedRatio(for volume: MountedVolume) -> Double {
        guard volume.totalBytes > 0 else { return 0 }
        return max(0, min(1, 1 - Double(volume.freeBytes) / Double(volume.totalBytes)))
    }

    private func handleTap() {
        let mods = NSEvent.modifierFlags
        if mods.contains(.shift) {
            state.extendRange(to: row.id)
            onActivate()
            lastTapAt = nil
            lastTapRowID = nil
            return
        }
        if mods.contains(.command) {
            state.toggleSingle(at: row.id)
            onActivate()
            lastTapAt = nil
            lastTapRowID = nil
            return
        }
        let now = Date()
        let limit = NSEvent.doubleClickInterval
        if lastTapRowID == row.id, let prev = lastTapAt, now.timeIntervalSince(prev) <= limit {
            lastTapAt = nil
            lastTapRowID = nil
            state.cursorID = row.id
            onActivate()
            onRowDoubleClick()
        } else {
            lastTapAt = now
            lastTapRowID = row.id
            state.cursorID = row.id
            onActivate()
        }
    }
}
