import SwiftUI

enum FileColorToken {
    static let folder = Color(.sRGB, red: 0.98, green: 0.55, blue: 0.20)
    static let document = Color.primary
    static let spreadsheet = Color(.sRGB, red: 0.55, green: 0.80, blue: 0.40)
    static let image = Color(.sRGB, red: 0.95, green: 0.55, blue: 0.85)
    static let code = Color(.sRGB, red: 0.45, green: 0.85, blue: 0.95)
    static let archive = Color.yellow
    static let media = Color(.sRGB, red: 0.45, green: 0.65, blue: 0.95)
    static let diskImage = Color(.sRGB, red: 0.45, green: 0.85, blue: 0.85)

    static let selectionActiveBackground = Color.yellow.opacity(0.45)
    static let selectionInactiveBackground = Color.gray.opacity(0.12)
    static let markedBackground = Color(.sRGB, red: 0.31, green: 0.14, blue: 0.14, opacity: 1.0)

    static let panelBackground = Color(white: 0.07)
    static let neutralBackground = Color(white: 0.15)

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
        default: return .primary
        }
    }
}
