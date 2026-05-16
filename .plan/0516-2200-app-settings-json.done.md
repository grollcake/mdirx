# 앱 설정 JSON 파일 관리

## 사용자 요구 (정제)

- **원문:** "앱 설정을 관리할 json 파일 계획문서 작성해. 지금은 특히 요소별 컬러 설정이 들어가게 될꺼야"
- **정제:** 앱 설정(우선 UI 요소별 컬러)을 JSON 파일로 관리한다. 앱 시작 시 파일을 읽어 색상 토큰에 반영하고, 파일이 없거나 항목이 빠지면 내장 기본값으로 폴백한다. 향후 키맵·동작 설정 등 다른 설정도 같은 파일로 확장할 수 있는 구조.

## 개요

설정 파일 위치는 환경에 따라 다르다.
- **개발 단계**: `{project_root}/dist/settings.json` — 빌드 결과물(`dist/MdirX.app`)과 나란히 위치해 편집·확인이 쉽다.
- **배포 단계**: `~/Library/Application Support/MdirX/settings.json`

앱은 시작 시 번들 옆(`Bundle.main.bundleURL` 기준 상위 디렉터리)에 `settings.json`이 있으면 그것을 우선 사용하고, 없으면 App Support 경로로 폴백한다.
앱 기동 시 `AppSettings` 싱글턴이 파일을 읽어 `@Observable` 프로퍼티로 제공하고, SwiftUI 뷰가 이를 환경 객체로 참조해 색상 토큰을 동적으로 적용한다.

---

## 요구사항

### 파일 위치

| 환경 | 경로 |
|------|------|
| 개발 (debug build) | `{project_root}/dist/settings.json` |
| 배포 (release) | `~/Library/Application Support/MdirX/settings.json` |

탐색 순서: 번들 상위 디렉터리(`Bundle.main.bundleURL.deletingLastPathComponent()`) → App Support.

- 파일이 없으면 기본값으로 동작 (첫 실행 시 자동 생성 불필요)
- 잘못된 JSON이면 기본값으로 폴백, 에러 로그만 출력

### JSON 구조 (초기)

```json
{
  "version": 1,
  "colors": {
    "panelBackground":     "#121212",
    "neutralBackground":   "#262626",
    "selectionActive":     "#FFFF0073",
    "selectionInactive":   "#80808020",
    "markedBackground":    "#4F2424",
    "folder":              "#FA8C33",
    "document":            "#FFFFFF",
    "spreadsheet":         "#8CCC66",
    "image":               "#F28CD9",
    "code":                "#73D9F2",
    "archive":             "#FFFF00",
    "media":               "#73A6F2",
    "diskImage":           "#73D9D9",
    "paneBorder":          "#FFFFFF1E",
    "middleColumn":        "#262626"
  }
}
```

- 색상 형식: `#RRGGBB` 또는 `#RRGGBBAA` (alpha 포함)
- 항목이 빠지면 해당 항목만 내장 기본값 사용
- `version` 필드로 향후 마이그레이션 대비

### 로딩 흐름
1. 앱 시작 → `AppSettings.shared.load()`
2. 파일 읽기 → JSON 디코딩 → `ColorSettings` 구조체에 저장
3. 실패·항목 누락 → 내장 `ColorSettings.defaults` 폴백
4. `FileColorToken`의 동적 컬러 프로퍼티가 `AppSettings.shared.colors`를 참조

### 런타임 리로드 (1단계에서는 제외)
- 추후 파일 감시(`DispatchSource` 또는 `FSEvent`)로 핫 리로드 가능하게 구조 유지

---

## 수도 코드

```swift
// Core/Settings/ColorSettings.swift
struct ColorSettings: Codable {
    var panelBackground:   String?
    var neutralBackground: String?
    var selectionActive:   String?
    // ... 나머지 항목
    
    static let defaults = ColorSettings(
        panelBackground:   "#121212",
        neutralBackground: "#262626",
        // ...
    )
    
    func color(for key: String) -> Color {
        // key에 해당하는 값 or defaults 값 파싱
    }
}

// Core/Settings/AppSettings.swift
@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()
    private(set) var colors: ColorSettings = .defaults

    func load() {
        guard let url = settingsURL,
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(SettingsFile.self, from: data)
        else { return }
        colors = decoded.colors ?? .defaults
    }
    
    private var settingsURL: URL? {
        // 1순위: 번들 옆 (개발 단계 dist/ 디렉터리)
        let nextToBundle = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("settings.json")
        if FileManager.default.fileExists(atPath: nextToBundle.path) {
            return nextToBundle
        }
        // 2순위: App Support (배포)
        return FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MdirX/settings.json")
    }
}

// SettingsFile (최상위 래퍼)
struct SettingsFile: Codable {
    let version: Int
    let colors: ColorSettings?
}

// FileColorToken 수정
enum FileColorToken {
    static var panelBackground: Color {
        AppSettings.shared.colors.resolved(.panelBackground)
    }
    // ...
}

// App 시작점
@main struct MdirXApp: App {
    init() { AppSettings.shared.load() }
}
```

---

## 아키텍처

### 신규 파일
| 파일 | 역할 |
|------|------|
| `Core/Settings/AppSettings.swift` | 싱글턴, load(), settingsURL |
| `Core/Settings/ColorSettings.swift` | Codable 구조체 + defaults + resolved() |

### 수정 파일
| 파일 | 변경 내용 |
|------|-----------|
| `DesignSystem/Tokens.swift` | 정적 상수 → `AppSettings.shared.colors` 참조 동적 프로퍼티 |
| `App/MdirXApp.swift` | `init()`에서 `AppSettings.shared.load()` 호출 |

### 색상 키 목록 (초기)

| 키 | 현재 값 | 용도 |
|----|---------|------|
| `panelBackground` | `Color(white: 0.07)` | 파일 목록 배경 |
| `neutralBackground` | `Color(white: 0.15)` | 헤더·서머리·중간 컬럼 |
| `selectionActive` | `Color.yellow.opacity(0.45)` | 활성 커서 배경 |
| `selectionInactive` | `Color.gray.opacity(0.12)` | 비활성 커서 배경 |
| `markedBackground` | `Color(.sRGB, r:0.31, g:0.14, b:0.14)` | 선택(마크) 배경 |
| `folder` | `Color(.sRGB, r:0.98, g:0.55, b:0.20)` | 폴더 아이콘·텍스트 |
| `document` | `Color.primary` | 일반 문서 |
| `spreadsheet` | `Color(.sRGB, r:0.55, g:0.80, b:0.40)` | 스프레드시트 |
| `image` | `Color(.sRGB, r:0.95, g:0.55, b:0.85)` | 이미지 파일 |
| `code` | `Color(.sRGB, r:0.45, g:0.85, b:0.95)` | 코드 파일 |
| `archive` | `Color.yellow` | 압축 파일 |
| `media` | `Color(.sRGB, r:0.45, g:0.65, b:0.95)` | 미디어 파일 |
| `diskImage` | `Color(.sRGB, r:0.45, g:0.85, b:0.85)` | 디스크 이미지 |
| `paneBorder` | `white 0.12 opacity` | 패널 테두리 |
| `middleColumn` | `neutralBackground` | 중간 구분 컬럼 |

---

## 통과 조건

### A. 기본 동작
- [ ] `settings.json` 없을 때 기존과 동일하게 동작 (기본값 폴백)
- [ ] 잘못된 JSON 파일이 있어도 앱이 crash 없이 기본값으로 기동
- [ ] 빌드 0 error / 0 warning

### B. 색상 적용
- [ ] `settings.json`의 `colors.panelBackground` 값을 바꾸면 앱 재기동 시 파일 목록 배경이 변경됨
- [ ] `colors.folder` 값 변경 시 폴더 행 색상 변경됨
- [ ] 항목 누락 시 해당 항목만 기본값 유지, 나머지는 파일 값 반영

### C. 단위 테스트
- [ ] `ColorSettings.resolved(_:)` — 올바른 hex 파싱 → Color 반환
- [ ] 빈 JSON `{}` → 모든 항목이 defaults 값
- [ ] 잘못된 hex 문자열 → defaults 값 폴백

---

## 구현 체크리스트

- [ ] `dist/` 디렉터리 생성 및 xcodebuild 빌드 경로를 `{project_root}/dist/` 로 변경
- [ ] `Core/Settings/` 디렉터리 생성
- [ ] `ColorSettings.swift` — Codable + defaults + resolved()
- [ ] `AppSettings.swift` — 싱글턴 + load() + settingsURL
- [ ] `Tokens.swift` — 정적 상수 → 동적 참조로 교체
- [ ] `MdirXApp.swift` — init()에서 load() 호출
- [ ] `MdirX.xcodeproj` 신규 파일 등록 (`scripts/gen_xcode_pbx.py`)
- [ ] 단위 테스트 `Tests/UnitTests/AppSettingsTests.swift`
- [ ] 빌드·앱 재실행·수동 확인
- [ ] STATUS.md 갱신

---

**상태:** `todo`
