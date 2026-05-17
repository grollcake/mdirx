import Foundation

enum AddressPathError: Error, Equatable {
    case notAbsolutePath
    case folderNotFound

    var userMessage: String {
        switch self {
        case .notAbsolutePath:
            return "절대 경로를 입력하세요"
        case .folderNotFound:
            return "폴더를 찾을 수 없습니다"
        }
    }
}

enum AddressPathValidator {
    static func expandAndNormalize(_ raw: String) -> Result<URL, AddressPathError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .failure(.folderNotFound)
        }

        let path = NSString(string: trimmed).expandingTildeInPath

        if !path.hasPrefix("/") {
            return .failure(.notAbsolutePath)
        }

        let url = URL(fileURLWithPath: path, isDirectory: true)
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        if !exists || !isDir.boolValue {
            return .failure(.folderNotFound)
        }

        return .success(url.standardizedFileURL)
    }
}
