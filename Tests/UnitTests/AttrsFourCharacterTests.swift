import Foundation
import Testing
@testable import MdirX

@Test func attrsEmpty() {
    let e = makeEntry(isWritable: true, isHiddenFlag: false, isSystemImmutable: false, isDirectory: false)
    #expect(e.attrsFourCharacter == "A___")
}

@Test func attrsReadOnly() {
    let e = makeEntry(isWritable: false, isHiddenFlag: false, isSystemImmutable: false, isDirectory: false)
    #expect(e.attrsFourCharacter == "AR__")
}

@Test func attrsHidden() {
    let e = makeEntry(isWritable: true, isHiddenFlag: true, isSystemImmutable: false, isDirectory: false)
    #expect(e.attrsFourCharacter == "A_H_")
}

@Test func attrsAll() {
    let e = makeEntry(isWritable: false, isHiddenFlag: true, isSystemImmutable: true, isDirectory: false)
    #expect(e.attrsFourCharacter == "ARHS")
}

@Test func attrsDirectory() {
    let e = makeEntry(isWritable: true, isHiddenFlag: false, isSystemImmutable: false, isDirectory: true)
    #expect(e.attrsFourCharacter == "____")
}

@Test func attrsParentLink() {
    let e = makeParentEntry()
    #expect(e.attrsFourCharacter == "____")
}

@Test func attrsFourCharsAlways() {
    let e = makeEntry(isWritable: false, isHiddenFlag: true, isSystemImmutable: false, isDirectory: false)
    #expect(e.attrsFourCharacter.count == 4)
}

// MARK: - helpers

private func makeEntry(isWritable: Bool, isHiddenFlag: Bool, isSystemImmutable: Bool, isDirectory: Bool) -> DirectoryEntry {
    let url = URL(fileURLWithPath: "/tmp/test.txt")
    return DirectoryEntry(
        id: url, url: url, displayName: "test", ext: "txt",
        isDirectory: isDirectory, isSymlink: false, size: 0,
        modificationDate: Date(), isWritable: isWritable,
        isSystemImmutable: isSystemImmutable, isHiddenFlag: isHiddenFlag,
        kindDescription: "", isParentLink: false, isMountedVolume: false
    )
}

private func makeParentEntry() -> DirectoryEntry {
    let url = URL(fileURLWithPath: "/tmp")
    return DirectoryEntry(
        id: url, url: url, displayName: "..", ext: "",
        isDirectory: true, isSymlink: false, size: 0,
        modificationDate: Date(), isWritable: true,
        isSystemImmutable: false, isHiddenFlag: false,
        kindDescription: "", isParentLink: true, isMountedVolume: false
    )
}
