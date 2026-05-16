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
                    let layout = FileListLayout.available(in: proxy.size.width)
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

    let selectionMarkerWidth: CGFloat = 12
    let iconWidth: CGFloat = 14
    let extWidth: CGFloat = 52
    let sizeWidth: CGFloat = 56
    let dateWidth: CGFloat = 70
    let timeWidth: CGFloat = 36
    let attrsWidth: CGFloat = 36
    let nameWidth: CGFloat
    let descriptionWidth: CGFloat

    static func available(in totalWidth: CGFloat) -> FileListLayout {
        // fixed = 12+14+52+56+70+36+36 = 276, spacing = 8*8 = 64
        let fixed: CGFloat = 276
        let spacing: CGFloat = 64
        let forFlexible = max(0, totalWidth - outerPadding * 2 - fixed - spacing)
        return FileListLayout(
            nameWidth: max(90, forFlexible * 0.75),
            descriptionWidth: max(0, forFlexible * 0.25)
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
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
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

            Text(ext)
                .font(.system(size: 12))
                .foregroundStyle(nameColor)
                .frame(width: layout.extWidth, alignment: .leading)

            Text(size)
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(sizeColor)
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

            descriptionView
                .frame(width: layout.descriptionWidth, alignment: .leading)
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

    private var ext: String {
        switch row.kind {
        case let .file(entry):
            if entry.isParentLink { return "" }
            if entry.isDirectory { return "[폴더]" }
            return entry.ext
        case .volume:
            return "[드라이브]"
        }
    }

    private var size: String {
        switch row.kind {
        case let .file(entry):
            if entry.isParentLink || entry.isDirectory { return "" }
            return ByteCountFormatter.string(fromByteCount: entry.size, countStyle: .file)
        case .volume:
            return ""
        }
    }

    private var date: String {
        switch row.kind {
        case let .file(entry):
            entry.relativeOrCalendarDate()
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
            Self.timeFormatter.string(from: entry.modificationDate)
        case .volume:
            ""
        }
    }

    private var attrs: String {
        switch row.kind {
        case let .file(entry): entry.attrsFourCharacter
        case .volume: "____"
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

    private var sizeColor: Color {
        switch row.kind {
        case let .file(entry):
            entry.isParentLink || entry.isDirectory ? Color(white: 0.45) : Color(white: 0.85)
        case .volume:
            Color(white: 0.45)
        }
    }

    @ViewBuilder
    private var descriptionView: some View {
        switch row.kind {
        case .file:
            EmptyView()
        case let .volume(volume):
            HStack(spacing: 6) {
                VolumeUsageBar(usedRatio: usedRatio(for: volume))
                Text("\(ByteCountFormatter.string(fromByteCount: volume.freeBytes, countStyle: .file)) 남음")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(Color(white: 0.78))
            }
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
