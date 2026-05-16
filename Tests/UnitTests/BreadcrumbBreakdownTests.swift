import Foundation
import Testing
@testable import MdirX

@Test
func breadcrumbBreaksPathIntoPrefixSegments() throws {
    let url = URL(fileURLWithPath: "/Users/rollcake/lab/mdirx", isDirectory: true)
    let segments = breadcrumbSegments(for: url, mountedVolumes: [])

    #expect(segments.last?.label == "mdirx")
    #expect(segments.count >= 4)
    #expect(segments.map(\.label).prefix(2) == ["/", "Users"])
    #expect(segments.last?.url.path == "/Users/rollcake/lab/mdirx")
}

@Test
func breadcrumbRootIsSingleSlashSegment() throws {
    let segments = breadcrumbSegments(for: URL(fileURLWithPath: "/", isDirectory: true), mountedVolumes: [])

    #expect(segments.count == 1)
    #expect(segments.first?.label == "/")
    #expect(segments.first?.url.path == "/")
}
