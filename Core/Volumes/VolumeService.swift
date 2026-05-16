import Foundation

struct MountedVolume: Identifiable, Hashable, Sendable {
    let id: URL
    let name: String
    let totalBytes: Int64
    let freeBytes: Int64

    enum IconKind: Sendable, Hashable {
        case internalDrive
        case external
        case network
        case cloud
    }

    let icon: IconKind
}

enum VolumeService: Sendable {
    static func mountedVolumes() -> [MountedVolume] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeLocalizedNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeIsInternalKey,
            .volumeIsRemovableKey,
            .volumeIsLocalKey,
        ]
        guard let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) else {
            return []
        }
        var result: [MountedVolume] = []
        result.reserveCapacity(urls.count)
        for url in urls {
            guard let r = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            let label = r.volumeLocalizedName ?? r.volumeName ?? url.lastPathComponent
            let total = Int64(r.volumeTotalCapacity ?? 0)
            let free = Int64(r.volumeAvailableCapacity ?? 0)
            let icon = iconKind(url: url, resource: r, label: label)
            result.append(MountedVolume(id: url, name: label, totalBytes: total, freeBytes: free, icon: icon))
        }
        return result
    }

    static func freeSpace(forVolumeContaining url: URL) -> (free: Int64, total: Int64)? {
        let keys: Set<URLResourceKey> = [.volumeAvailableCapacityKey, .volumeTotalCapacityKey]
        guard let r = try? url.resourceValues(forKeys: keys),
              let total = r.volumeTotalCapacity,
              let free = r.volumeAvailableCapacity
        else { return nil }
        return (Int64(free), Int64(total))
    }

    private static func iconKind(url: URL, resource r: URLResourceValues, label: String) -> MountedVolume.IconKind {
        let lower = label.lowercased()
        let path = url.path.lowercased()
        if lower.contains("icloud") || path.contains("icloud") {
            return .cloud
        }
        let internalVol = r.volumeIsInternal ?? false
        let removable = r.volumeIsRemovable ?? false
        let local = r.volumeIsLocal ?? true
        if internalVol && !removable { return .internalDrive }
        if removable { return .external }
        if !local { return .network }
        return .internalDrive
    }
}
