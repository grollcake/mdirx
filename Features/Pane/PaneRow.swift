import Foundation

struct PaneRow: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case file(DirectoryEntry)
        case volume(MountedVolume)
    }

    let id: URL
    let rowNumber: Int
    let kind: Kind
}

extension PaneState {
    var paneRows: [PaneRow] {
        // Dedup: entries 안에 mountedVolumes 와 URL 이 겹치는 항목(예: ~/OrbStack 심볼릭)
        // 이 있으면 폴더 표현은 버리고 볼륨 표현만 남긴다. 그 후 1..N 으로 연속 번호 재부여.
        let volumeIDs = Set(mountedVolumes.map(\.id))
        var rows: [PaneRow] = []
        var n = 0
        for entry in entries where !volumeIDs.contains(entry.id) {
            n += 1
            rows.append(PaneRow(id: entry.id, rowNumber: n, kind: .file(entry)))
        }
        for volume in mountedVolumes {
            n += 1
            rows.append(PaneRow(id: volume.id, rowNumber: n, kind: .volume(volume)))
        }
        return rows
    }
}
