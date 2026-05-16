import SwiftUI

struct VolumeBadgeView: View {
    let currentURL: URL
    let mountedVolumes: [MountedVolume]
    let paneSlot: PaneSlot

    private var matchingVolume: MountedVolume? {
        let standardized = currentURL.standardizedFileURL
        return mountedVolumes
            .filter { standardized.path.hasPrefix($0.id.standardizedFileURL.path) }
            .max { $0.id.path.count < $1.id.path.count }
    }

    private var freeSpace: (free: Int64, total: Int64)? {
        VolumeService.freeSpace(forVolumeContaining: currentURL)
    }

    private var usedRatio: Double {
        guard let freeSpace, freeSpace.total > 0 else { return 0 }
        return max(0, min(1, 1 - Double(freeSpace.free) / Double(freeSpace.total)))
    }

    var body: some View {
        if let freeSpace {
            HStack(spacing: 6) {
                Text(matchingVolume?.name ?? currentURL.pathComponents.first ?? "/")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.78))
                    .lineLimit(1)

                VolumeUsageBar(usedRatio: usedRatio)

                Text("\(ByteCountFormatter.string(fromByteCount: freeSpace.free, countStyle: .file)) 남음")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(Color(white: 0.78))
                    .lineLimit(1)
            }
            .accessibilityIdentifier("pane.\(paneSlot.rawValue).volume.\(sanitizedName)")
        }
    }

    private var sanitizedName: String {
        let raw = matchingVolume?.name ?? currentURL.pathComponents.first ?? "volume"
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let mapped = raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        return String(mapped)
    }
}

struct VolumeUsageBar: View {
    let usedRatio: Double

    var body: some View {
        Capsule()
            .fill(Color.white.opacity(0.18))
            .frame(width: 60, height: 6)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 60 * usedRatio, height: 6)
            }
    }
}
