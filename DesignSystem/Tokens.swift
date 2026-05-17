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

    /// 상태 표시줄·헤더 보조 컨트롤 등 동일 톤의 읽기 쉬운 2차 레이블 색.
    static var mutedChromeForeground: Color { Color(white: 0.7) }

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

/// 파일 리스트 선택 행과 ⌘L 경로 목록 하이라이트 공통 스타일(시스템 accent, 연속 라운드).
enum ListAccentHighlight {
    static let cornerRadius: CGFloat = 6
    /// 파일 패널 행 폭 안쪽 들여줌(패널과 동일 패딩이면 과하게 꽉 찬 칩 모양 완화).
    static let fileListHorizontalInset: CGFloat = 4
    /// 주소 목록 행 등 “활성” 컨텍스트 선택.
    static var fill: Color { Color.accentColor.opacity(0.35) }
    /// 활성 패널이 아닐 때 패널에 남긴 커서 하이라이트는 한 단계 약하게.
    static var inactivePaneFill: Color { Color.accentColor.opacity(0.22) }
}
