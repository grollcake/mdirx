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

    func rename(at url: URL, to newName: String) async throws -> URL {
        let dest = url.deletingLastPathComponent().appendingPathComponent(newName)
        try FileManager.default.moveItem(at: url, to: dest)
        return dest
    }

    func copyItems(_ urls: [URL], to destinationDirectory: URL) async throws -> [URL] {
        let destinations = try preflightDestinations(for: urls, in: destinationDirectory)
        for (source, destination) in zip(urls, destinations) {
            try FileManager.default.copyItem(at: source, to: destination)
        }
        return destinations
    }

    func moveItems(_ urls: [URL], to destinationDirectory: URL) async throws -> [URL] {
        let destinations = try preflightDestinations(for: urls, in: destinationDirectory)
        for (source, destination) in zip(urls, destinations) {
            try FileManager.default.moveItem(at: source, to: destination)
        }
        return destinations
    }

    private func preflightDestinations(for urls: [URL], in destinationDirectory: URL) throws -> [URL] {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: destinationDirectory.path, isDirectory: &isDir), isDir.boolValue else {
            throw NSError(
                domain: NSCocoaErrorDomain,
                code: NSFileNoSuchFileError,
                userInfo: [NSLocalizedDescriptionKey: "대상 폴더를 찾을 수 없습니다"]
            )
        }

        let destinations = urls.map { source in
            destinationDirectory.appendingPathComponent(source.lastPathComponent)
        }
        for destination in destinations where FileManager.default.fileExists(atPath: destination.path) {
            throw NSError(
                domain: NSCocoaErrorDomain,
                code: NSFileWriteFileExistsError,
                userInfo: [NSLocalizedDescriptionKey: "같은 이름의 항목이 이미 있습니다: \(destination.lastPathComponent)"]
            )
        }
        return destinations
    }

    func createDirectory(at parent: URL, name: String) async throws -> URL {
        let dest = parent.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: false)
        return dest
    }

    func createEmptyFile(at parent: URL, name: String) async throws -> URL {
        let dest = parent.appendingPathComponent(name, isDirectory: false)
        guard FileManager.default.createFile(atPath: dest.path, contents: nil) else {
            throw NSError(
                domain: NSCocoaErrorDomain,
                code: NSFileWriteUnknownError,
                userInfo: [NSLocalizedDescriptionKey: "파일 생성 실패"]
            )
        }
        return dest
    }
}
