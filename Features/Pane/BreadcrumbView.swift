import SwiftUI

struct BreadcrumbSegment: Identifiable, Hashable {
    let id: URL
    let label: String
    let url: URL
}

func breadcrumbSegments(for url: URL, mountedVolumes: [MountedVolume]) -> [BreadcrumbSegment] {
    let standardized = url.standardizedFileURL
    let matchingVolume = mountedVolumes
        .filter { standardized.path.hasPrefix($0.id.standardizedFileURL.path) }
        .max { $0.id.path.count < $1.id.path.count }

    let components = standardized.pathComponents
    guard !components.isEmpty else {
        return [BreadcrumbSegment(id: URL(fileURLWithPath: "/"), label: "/", url: URL(fileURLWithPath: "/"))]
    }

    var segments: [BreadcrumbSegment] = []
    var current = URL(fileURLWithPath: "/", isDirectory: true)
    let rootLabel = matchingVolume?.name ?? "/"
    segments.append(BreadcrumbSegment(id: current, label: rootLabel, url: current))

    for component in components.dropFirst() {
        current.appendPathComponent(component, isDirectory: true)
        segments.append(BreadcrumbSegment(id: current, label: component, url: current))
    }
    return segments
}

struct BreadcrumbView: View {
    let currentURL: URL
    let mountedVolumes: [MountedVolume]
    let paneSlot: PaneSlot
    let onTap: @MainActor (URL) -> Void

    private var segments: [BreadcrumbSegment] {
        breadcrumbSegments(for: currentURL, mountedVolumes: mountedVolumes)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    Button {
                        onTap(segment.url)
                    } label: {
                        Text(segment.label)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(index == segments.count - 1 ? Color(white: 0.95) : Color(white: 0.78))
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("pane.\(paneSlot.rawValue).breadcrumb.\(index)")

                    if index < segments.count - 1 {
                        Text("›")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(white: 0.45))
                            .padding(.horizontal, 4)
                    }
                }
            }
        }
    }
}
