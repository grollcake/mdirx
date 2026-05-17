import AppKit
import SwiftUI

// MARK: - 파일 리스트 스크롤 뷰포트 동기화 (글로벌 좌표)

private enum FileListViewportGlobalPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect { .zero }
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next.width > 1, next.height > 1 { value = next }
    }
}

private enum FileListRowGlobalFramesPreferenceKey: PreferenceKey {
    static var defaultValue: [URL: CGRect] { [:] }
    static func reduce(value: inout [URL: CGRect], nextValue: () -> [URL: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, n in n })
    }
}

struct FileListView: View {
    @Bindable var state: PaneState
    let isActive: Bool
    let onActivate: @MainActor () -> Void
    let onRowDoubleClick: @MainActor () -> Void

    /// ScrollView 가시 영역(글로벌). 배경 GeometryReader.preference 로 갱신.
    @State private var viewportGlobalRect: CGRect = .zero
    /// Lazy 로 올려진 행만 측정된다.
    @State private var rowFramesGlobalByID: [URL: CGRect] = [:]

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
                    let rows = state.paneRows
                    let layout = FileListLayout.available(in: proxy.size.width, rows: rows)
                    VStack(spacing: 0) {
                        ScrollViewReader { scrollProxy in
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 0) {
                                    ForEach(rows) { row in
                                        FileListRow(
                                            state: state,
                                            row: row,
                                            isActive: isActive,
                                            sanitizedBasename: sanitizedBasename(row.id),
                                            layout: layout,
                                            onActivate: onActivate,
                                            onRowDoubleClick: onRowDoubleClick
                                        )
                                        .background(
                                            GeometryReader { geo in
                                                Color.clear.preference(
                                                    key: FileListRowGlobalFramesPreferenceKey.self,
                                                    value: [row.id: geo.frame(in: .global)]
                                                )
                                            }
                                        )
                                        .id(row.id)
                                    }
                                }
                                .padding(.leading, FileListLayout.outerPadding)
                                .padding(.trailing, FileListLayout.trailingPadding)
                                .padding(.vertical, 6)
                            }
                            .background(
                                GeometryReader { viewportGeo in
                                    Color.clear.preference(
                                        key: FileListViewportGlobalPreferenceKey.self,
                                        value: viewportGeo.frame(in: .global)
                                    )
                                }
                            )
                            .onPreferenceChange(FileListViewportGlobalPreferenceKey.self) { viewportGlobalRect = $0 }
                            .onPreferenceChange(FileListRowGlobalFramesPreferenceKey.self) { rowFramesGlobalByID = $0 }
                            .onChange(of: state.cursorID) { oldID, newID in
                                revealCursorIfNeeded(
                                    with: scrollProxy,
                                    oldCursorID: oldID,
                                    newCursorID: newID,
                                    paneRowsSnapshot: rows
                                )
                            }
                            .onChange(of: isActive) { _, active in
                                if active {
                                    revealCursorIfNeeded(
                                        with: scrollProxy,
                                        oldCursorID: nil,
                                        newCursorID: state.cursorID,
                                        paneRowsSnapshot: rows
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(FileColorToken.panelBackground)
    }

    /// 포커스 행이 뷰포트 안에 세로로 온전히 들어오면 스크롤 안 함.
    /// 맨 아래/맨 위에 붙었을 때만 한 줄 단위 감각에 가깝게 `scrollTo` (각각 `.bottom` / `.top`).
    private func revealCursorIfNeeded(
        with proxy: ScrollViewProxy,
        oldCursorID: URL?,
        newCursorID: URL?,
        paneRowsSnapshot: [PaneRow]
    ) {
        guard isActive, let id = newCursorID else { return }
        Task { @MainActor in
            await Task.yield()
            scrollToCursorIfVerticallyClipped(
                proxy: proxy,
                cursorID: id,
                oldCursorID: oldCursorID,
                paneRowsSnapshot: paneRowsSnapshot,
                viewportGlobal: viewportGlobalRect,
                rowFramesGlobalByID: rowFramesGlobalByID
            )
        }
    }

    private func scrollToCursorIfVerticallyClipped(
        proxy: ScrollViewProxy,
        cursorID: URL,
        oldCursorID: URL?,
        paneRowsSnapshot: [PaneRow],
        viewportGlobal: CGRect,
        rowFramesGlobalByID: [URL: CGRect]
    ) {
        let slack: CGFloat = 1

        guard viewportGlobal.width > 10, viewportGlobal.height > FileListLayout.rowHeight else {
            let down = prefersScrollDownReveal(oldCursorID: oldCursorID, newCursorID: cursorID, rows: paneRowsSnapshot)
            proxy.scrollTo(cursorID, anchor: down ? .bottom : .top)
            return
        }

        if let rowRect = rowFramesGlobalByID[cursorID], rowRect.height >= 8 {
            if rowRect.minY >= viewportGlobal.minY - slack, rowRect.maxY <= viewportGlobal.maxY + slack {
                return
            }
            if rowRect.minY < viewportGlobal.minY - slack {
                proxy.scrollTo(cursorID, anchor: .top)
                return
            }
            if rowRect.maxY > viewportGlobal.maxY + slack {
                proxy.scrollTo(cursorID, anchor: .bottom)
                return
            }
            return
        }

        let down = prefersScrollDownReveal(oldCursorID: oldCursorID, newCursorID: cursorID, rows: paneRowsSnapshot)
        proxy.scrollTo(cursorID, anchor: down ? .bottom : .top)
    }

    private func prefersScrollDownReveal(oldCursorID: URL?, newCursorID: URL, rows: [PaneRow]) -> Bool {
        guard let old = oldCursorID,
              let o = rows.firstIndex(where: { $0.id == old }),
              let n = rows.firstIndex(where: { $0.id == newCursorID }),
              n != o
        else { return true }
        return n > o
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
    /// 우측은 macOS 스크롤바와 겹치지 않도록 추가 여백.
    static let trailingPadding: CGFloat = 18
    static let rowHeight: CGFloat = 20

    // 고정 컬럼 폭 (단위 pt) — 표는 docs/requirements/file-list-columns.md 참고
    static let selectionMarkerWidth: CGFloat = 6
    static let iconWidth: CGFloat = 14
    // ext는 보통 2~4자 (".swift" 등). 좁은 패널에서 이름 공간을 더 주기 위해 축소.
    static let extWidth: CGFloat = 36
    static let sizeWidth: CGFloat = 52
    static let timeWidth: CGFloat = 32
    static let attrsWidth: CGFloat = 30

    static let leftGroupSpacing: CGFloat = 8
    static let regularGroupSpacing: CGFloat = 12
    static let compactGroupSpacing: CGFloat = 8
    static let minimumNameWidth: CGFloat = 90
    static let nameWidthPadding: CGFloat = 20
    static let minimumDescriptionWidth: CGFloat = 48

    // dateWidth: "yyyy-MM-dd" 문자열을 monospacedDigit size 11 로 한 번만 측정
    static let dateWidth: CGFloat = {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        ]
        return ceil(("2026-05-17" as NSString).size(withAttributes: attrs).width) + 4
    }()

    let showsExt: Bool
    let showsAttrs: Bool
    let showsDescription: Bool
    let groupSpacing: CGFloat
    let rightGroupSpacing: CGFloat
    var selectionMarkerWidth: CGFloat { Self.selectionMarkerWidth }
    var iconWidth: CGFloat { Self.iconWidth }
    var extWidth: CGFloat { Self.extWidth }
    var sizeWidth: CGFloat { Self.sizeWidth }
    var dateWidth: CGFloat { Self.dateWidth }
    var timeWidth: CGFloat { Self.timeWidth }
    var attrsWidth: CGFloat { Self.attrsWidth }
    let nameWidth: CGFloat
    let descriptionWidth: CGFloat

    static func available(in totalWidth: CGFloat, rows: [PaneRow]) -> FileListLayout {
        let preferredNameWidth = preferredNameWidth(for: rows)

        let regular = make(
            totalWidth: totalWidth,
            preferredNameWidth: preferredNameWidth,
            showsExt: true,
            showsAttrs: true,
            spacing: regularGroupSpacing
        )
        if regular.nameWidth >= preferredNameWidth {
            return regular
        }

        let compact = make(
            totalWidth: totalWidth,
            preferredNameWidth: preferredNameWidth,
            showsExt: true,
            showsAttrs: true,
            spacing: compactGroupSpacing
        )
        if compact.nameWidth >= preferredNameWidth {
            return compact
        }

        let withoutAttrs = make(
            totalWidth: totalWidth,
            preferredNameWidth: preferredNameWidth,
            showsExt: true,
            showsAttrs: false,
            spacing: compactGroupSpacing
        )
        if withoutAttrs.nameWidth >= preferredNameWidth {
            return withoutAttrs
        }

        return make(
            totalWidth: totalWidth,
            preferredNameWidth: preferredNameWidth,
            showsExt: false,
            showsAttrs: false,
            spacing: compactGroupSpacing
        )
    }

    private static func preferredNameWidth(for rows: [PaneRow]) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .regular)
        ]
        let maxContent = rows.map { row -> CGFloat in
            let name: String
            switch row.kind {
            case let .file(entry): name = entry.displayName
            case let .volume(volume): name = volume.name
            }
            return (name as NSString).size(withAttributes: attrs).width
        }.max() ?? 0
        return max(minimumNameWidth, ceil(maxContent) + nameWidthPadding)
    }

    private static func make(
        totalWidth: CGFloat,
        preferredNameWidth: CGFloat,
        showsExt: Bool,
        showsAttrs: Bool,
        spacing: CGFloat
    ) -> FileListLayout {
        let rightColumnCount = 3 + (showsExt ? 1 : 0) + (showsAttrs ? 1 : 0)
        let fixedWidth = selectionMarkerWidth
            + iconWidth
            + (showsExt ? extWidth : 0)
            + sizeWidth
            + dateWidth
            + timeWidth
            + (showsAttrs ? attrsWidth : 0)
        let totalSpacing = leftGroupSpacing * 2
            + spacing
            + spacing * CGFloat(max(0, rightColumnCount - 1))
        let forFlexible = max(0, totalWidth - outerPadding - trailingPadding - fixedWidth - totalSpacing)
        let nameWidth = max(minimumNameWidth, min(preferredNameWidth, forFlexible))
        let descriptionCandidateWidth = forFlexible - nameWidth - spacing
        let descriptionWidth = max(0, descriptionCandidateWidth)
        let showsDescription = descriptionWidth >= minimumDescriptionWidth
        return FileListLayout(
            showsExt: showsExt,
            showsAttrs: showsAttrs,
            showsDescription: showsDescription,
            groupSpacing: spacing,
            rightGroupSpacing: spacing,
            nameWidth: nameWidth,
            descriptionWidth: showsDescription ? descriptionWidth : 0
        )
    }
}

private struct FileListHeader: View {
    let layout: FileListLayout

    var body: some View {
        HStack(spacing: layout.groupSpacing) {
            HStack(spacing: FileListLayout.leftGroupSpacing) {
                Text("").frame(width: layout.selectionMarkerWidth, alignment: .center)
                Text("").frame(width: layout.iconWidth, alignment: .center)
                Text("Name").frame(width: layout.nameWidth, alignment: .leading)
            }
            .layoutPriority(1)

            HStack(spacing: layout.rightGroupSpacing) {
                if layout.showsExt {
                    Text("Ext").frame(width: layout.extWidth, alignment: .leading)
                }
                Text("Size").frame(width: layout.sizeWidth, alignment: .trailing)
                Text("Date").frame(width: layout.dateWidth, alignment: .leading)
                Text("Time").frame(width: layout.timeWidth, alignment: .leading)
                if layout.showsAttrs {
                    Text("Attrs").frame(width: layout.attrsWidth, alignment: .leading)
                }
                if layout.showsDescription {
                    Text("Description").frame(width: layout.descriptionWidth, alignment: .leading)
                }
            }
        }
        .font(.system(size: 11).monospacedDigit())
        .lineLimit(1)
        .foregroundStyle(Color(white: 0.45))
        .padding(.leading, FileListLayout.outerPadding)
        .padding(.trailing, FileListLayout.trailingPadding)
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
        HStack(spacing: layout.groupSpacing) {
            HStack(spacing: FileListLayout.leftGroupSpacing) {
                Text(isMarked ? "▶" : "")
                    .font(.system(size: 11).monospaced())
                    .foregroundStyle(.yellow)
                    .frame(width: layout.selectionMarkerWidth, alignment: .center)

                Image(systemName: iconName)
                    .font(.system(size: 11))
                    .foregroundStyle(fgIcon)
                    .frame(width: layout.iconWidth, alignment: .center)

                Text(name)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(fgPrimaryName)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: layout.nameWidth, alignment: .leading)
                    .clipped()
            }
            .layoutPriority(1)

            HStack(spacing: layout.rightGroupSpacing) {
                if case let .volume(volume) = row.kind {
                    volumeColumns(volume)
                } else {
                    if layout.showsExt {
                        extView
                            .frame(width: layout.extWidth, alignment: .leading)
                    }

                    sizeView
                        .frame(width: layout.sizeWidth, alignment: .trailing)

                    Text(date)
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(fgDateTime)
                        .frame(width: layout.dateWidth, alignment: .leading)

                    Text(time)
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(fgDateTime)
                        .frame(width: layout.timeWidth, alignment: .leading)

                    if layout.showsAttrs {
                        Text(attrs)
                            .font(.system(size: 11).monospaced())
                            .foregroundStyle(fgAttrsMuted)
                            .frame(width: layout.attrsWidth, alignment: .leading)
                    }

                    if layout.showsDescription {
                        descriptionView
                            .frame(width: layout.descriptionWidth, alignment: .leading)
                    }
                }
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

    private var fgIcon: Color {
        if isSelected { return Color.white.opacity(isActive ? 0.9 : 0.78) }
        return iconColor
    }

    private var fgPrimaryName: Color {
        if isSelected { return Color.white.opacity(isActive ? 0.96 : 0.85) }
        return nameColor
    }

    private var fgDateTime: Color {
        if isSelected { return Color.white.opacity(isActive ? 0.76 : 0.62) }
        return Color(white: 0.7)
    }

    private var fgAttrsMuted: Color {
        if isSelected { return Color.white.opacity(isActive ? 0.58 : 0.48) }
        return Color(white: 0.55)
    }

    private var fgDescriptionMuted: Color {
        if isSelected { return Color.white.opacity(isActive ? 0.52 : 0.42) }
        return Color(white: 0.48)
    }

    private var fgSizeNumeric: Color {
        if isSelected { return Color.white.opacity(isActive ? 0.82 : 0.68) }
        return Color(white: 0.85)
    }

    private var fgFolderBracket: Color {
        if isSelected { return Color.white.opacity(isActive ? 0.55 : 0.44) }
        return Color(white: 0.45)
    }

    private var fgVolumeFreeCaption: Color {
        if isSelected { return Color.white.opacity(isActive ? 0.78 : 0.64) }
        return Color(white: 0.78)
    }

    @ViewBuilder
    private var rowBackground: some View {
        ZStack {
            if isMarked {
                Rectangle().fill(FileColorToken.markedBackground)
            }
            if isSelected {
                RoundedRectangle(cornerRadius: ListAccentHighlight.cornerRadius, style: .continuous)
                    .fill(isActive ? ListAccentHighlight.fill : ListAccentHighlight.inactivePaneFill)
                    .padding(.horizontal, ListAccentHighlight.fileListHorizontalInset)
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
    private func volumeColumns(_ volume: MountedVolume) -> some View {
        if layout.showsExt {
            extView
                .frame(width: layout.extWidth, alignment: .leading)

            Text("\(Self.formatBytes(volume.freeBytes)) 남음")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(fgVolumeFreeCaption)
                .frame(width: volumeFreeTextWidth(startingAfterExt: true), alignment: .leading)

            if layout.showsDescription {
                Color.clear
                    .frame(width: layout.descriptionWidth, alignment: .leading)
            }
        } else {
            VolumeUsageBar(usedRatio: usedRatio(for: volume))
                .frame(width: layout.sizeWidth, alignment: .leading)

            Text("\(Self.formatBytes(volume.freeBytes)) 남음")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(fgVolumeFreeCaption)
                .frame(width: volumeFreeTextWidth(startingAfterExt: false), alignment: .leading)

            if layout.showsDescription {
                Color.clear
                    .frame(width: layout.descriptionWidth, alignment: .leading)
            }
        }
    }

    private func volumeFreeTextWidth(startingAfterExt: Bool) -> CGFloat {
        var widths: [CGFloat] = startingAfterExt
            ? [layout.sizeWidth, layout.dateWidth, layout.timeWidth]
            : [layout.dateWidth, layout.timeWidth]
        if layout.showsAttrs {
            widths.append(layout.attrsWidth)
        }
        let spacing = layout.rightGroupSpacing * CGFloat(max(0, widths.count - 1))
        return widths.reduce(0, +) + spacing
    }

    @ViewBuilder
    private var descriptionView: some View {
        switch row.kind {
        case let .file(entry):
            if entry.isParentLink {
                Color.clear
            } else {
                Text(entry.kindDescription)
                    .font(.system(size: 11))
                    .foregroundStyle(fgDescriptionMuted)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        case .volume:
            Color.clear
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
                    .foregroundStyle(fgPrimaryName)
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
                    .foregroundStyle(fgFolderBracket)
            } else {
                Text(Self.formatBytes(entry.size))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(fgSizeNumeric)
            }
        case let .volume(volume):
            Text("\(Self.formatBytes(volume.freeBytes)) 남음")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(fgVolumeFreeCaption)
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
