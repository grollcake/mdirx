import Foundation

func splitFileNameExtension(_ name: String) -> (String, String) {
    if name.isEmpty { return ("", "") }
    if name == "." || name == ".." { return (name, "") }
    guard let dot = name.lastIndex(of: ".") else { return (name, "") }
    if dot == name.startIndex {
        return (name, "")
    }
    let base = String(name[..<dot])
    let ext = String(name[name.index(after: dot)...]).lowercased()
    return (base, ext)
}

func defaultDirectoryEntryOrder(_ a: DirectoryEntry, _ b: DirectoryEntry) -> Bool {
    if a.isDirectory != b.isDirectory { return a.isDirectory }
    return a.displayName.localizedCaseInsensitiveCompare(b.displayName) == .orderedAscending
}

actor FileSystemActor {
    func listDirectory(at url: URL, includeHidden: Bool) async throws -> [DirectoryEntry] {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .nameKey,
            .isWritableKey,
            .isHiddenKey,
            .isSystemImmutableKey,
            .contentTypeKey,
        ]
        let options: FileManager.DirectoryEnumerationOptions = includeHidden ? [] : [.skipsHiddenFiles]
        let urls = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: options
        )
        var entries: [DirectoryEntry] = []
        entries.reserveCapacity(urls.count)
        for u in urls {
            let r = try u.resourceValues(forKeys: keys)
            let name = r.name ?? u.lastPathComponent
            let isDir = r.isDirectory ?? false
            let isLink = r.isSymbolicLink ?? false
            let (base, ext): (String, String) = if isDir {
                (name, "")
            } else {
                splitFileNameExtension(name)
            }
            let kindDescription = DirectoryEntry.makeKindDescription(
                isDirectory: isDir,
                ext: ext,
                contentType: r.contentType
            )
            entries.append(DirectoryEntry(
                id: u,
                url: u,
                displayName: base,
                ext: ext,
                isDirectory: isDir,
                isSymlink: isLink,
                size: Int64(r.fileSize ?? 0),
                modificationDate: r.contentModificationDate ?? .distantPast,
                isWritable: r.isWritable ?? true,
                isSystemImmutable: r.isSystemImmutable ?? false,
                isHiddenFlag: r.isHidden ?? false,
                kindDescription: kindDescription,
                isParentLink: false,
                isMountedVolume: false
            ))
        }
        entries.sort(by: defaultDirectoryEntryOrder)

        let parent = url.deletingLastPathComponent()
        if parent.path != url.path {
            let parentKeys: Set<URLResourceKey> = [.contentModificationDateKey]
            let parentRes = try? parent.resourceValues(forKeys: parentKeys)
            let parentDesc = Bundle.main.localizedString(
                forKey: DirectoryEntry.parentLinkKindKey,
                value: "Parent directory",
                table: nil
            )
            let parentEntry = DirectoryEntry(
                id: parent,
                url: parent,
                displayName: "..",
                ext: "",
                isDirectory: true,
                isSymlink: false,
                size: 0,
                modificationDate: parentRes?.contentModificationDate ?? .distantPast,
                isWritable: true,
                isSystemImmutable: false,
                isHiddenFlag: false,
                kindDescription: parentDesc,
                isParentLink: true,
                isMountedVolume: false
            )
            entries.insert(parentEntry, at: 0)
        }

        return entries
    }
}
