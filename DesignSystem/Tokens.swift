import SwiftUI

@MainActor
enum FileColorToken {
    static var folder:                      Color { AppSettings.shared.colors.folder }
    static var document:                    Color { AppSettings.shared.colors.document }
    static var spreadsheet:                 Color { AppSettings.shared.colors.spreadsheet }
    static var image:                       Color { AppSettings.shared.colors.image }
    static var code:                        Color { AppSettings.shared.colors.code }
    static var archive:                     Color { AppSettings.shared.colors.archive }
    static var media:                       Color { AppSettings.shared.colors.media }
    static var diskImage:                   Color { AppSettings.shared.colors.diskImage }
    static var selectionActiveBackground:   Color { AppSettings.shared.colors.selectionActive }
    static var selectionInactiveBackground: Color { AppSettings.shared.colors.selectionInactive }
    static var markedBackground:            Color { AppSettings.shared.colors.markedBackground }
    static var panelBackground:             Color { AppSettings.shared.colors.panelBackground }
    static var neutralBackground:           Color { AppSettings.shared.colors.neutralBackground }

    static func color(for entry: DirectoryEntry) -> Color {
        if entry.isDirectory { return folder }
        switch entry.ext {
        case "md", "txt", "rtf": return document
        case "xlsx", "xls", "csv": return spreadsheet
        case "png", "jpg", "jpeg", "gif", "heic", "webp": return image
        case "swift", "py", "ts", "tsx", "js", "jsx", "rs", "go", "c", "h", "cpp", "hpp": return code
        case "zip", "tar", "gz", "tgz", "bz2", "xz", "7z": return archive
        case "mp4", "mov", "m4v", "mp3", "wav", "aac", "flac": return media
        case "iso", "dmg": return diskImage
        default: return document
        }
    }
}
