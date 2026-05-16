import SwiftUI

struct PaneSummaryView: View {
    @Bindable var state: PaneState

    private var countableEntries: [DirectoryEntry] {
        state.entries.filter { !$0.isParentLink && !$0.isMountedVolume }
    }

    private var folderCount: Int {
        countableEntries.filter(\.isDirectory).count
    }

    private var fileCount: Int {
        countableEntries.filter { !$0.isDirectory }.count
    }

    private var totalFileBytes: Int64 {
        countableEntries.reduce(into: Int64(0)) { acc, e in
            if !e.isDirectory { acc += e.size }
        }
    }

    private var sizeString: String {
        ByteCountFormatter.string(fromByteCount: totalFileBytes, countStyle: .file)
    }

    private var selectionSize: Int64 {
        countableEntries.reduce(into: Int64(0)) { acc, e in
            if state.selection.contains(e.id), !e.isDirectory {
                acc += e.size
            }
        }
    }

    private var selectionSizeString: String {
        ByteCountFormatter.string(fromByteCount: selectionSize, countStyle: .file)
    }

    @ViewBuilder
    private var summaryText: some View {
        if state.selection.isEmpty {
            Text("\(folderCount) 폴더, \(fileCount) 파일 (\(sizeString))")
                .foregroundStyle(Color(white: 0.62))
        } else {
            Text("선택정보: \(state.selection.count) 항목 (총 \(selectionSizeString))")
                .foregroundStyle(.yellow)
        }
    }

    var body: some View {
        summaryText
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 24)
            .padding(.leading, 12)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
            }
            .accessibilityIdentifier("pane.\(state.slot.rawValue).summary")
    }
}
