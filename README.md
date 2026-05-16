# MdirX

> **Mdir, reborn on macOS.**
> NexusFile 호환 키바인딩과 듀얼 패널 워크플로우를 macOS 15+ 네이티브로.

[![status](https://img.shields.io/badge/status-M1%20in%20progress-green)]()
[![platform](https://img.shields.io/badge/platform-macOS%2015%2B-blue)]()
[![swift](https://img.shields.io/badge/Swift-6-orange)]()
[![ui](https://img.shields.io/badge/UI-SwiftUI-purple)]()

---

## 소개

MdirX는 macOS용 듀얼 패널 파일 매니저입니다. DOS 시절의 **Mdir / NCD** 와 Windows의 **NexusFile** 을 사용해 온 파워유저가 macOS에서 동일한 키보드 중심 워크플로우를 그대로 쓸 수 있도록 설계됩니다.

- 좌우 듀얼 패널 (패널별 독립 탭은 후속 Phase 4)
- F10 폴더 점프 (NCD/MCD 스타일 퍼지 검색)
- F11 즐겨찾기
- 고급 이름변경 (정규식·번호매김·라이브 프리뷰)
- ZIP 압축/해제, 지능형 해제
- QuickLook · FSEvents 실시간 갱신
- 사용자 정의 함수키(F1~F12)
- 라이트/다크 스킨

> **M1 진행 중.** 듀얼 패널·파일 목록·경로 복원·`..` 부모 행·NexusFile 룩 UI·다중 선택(3단계 토글)·마우스 활성화·경로 동기화 버튼 등 핵심 기능 완료. 다음 작업은 [.plan/STATUS.md](.plan/STATUS.md) 의 `todo` 행을 따름.

---

## 상태

| 항목 | 상태 |
|---|---|
| 다음 마일스톤 | [.plan/STATUS.md](.plan/STATUS.md) 의 `doing`/`todo` (Nexus 룩 보완·다중 선택·이름변경/새 항목 등) |
| 최소 macOS | 15.0 Sequoia |
| 아키텍처 | Universal (Apple Silicon + Intel) |
| 배포 채널 | Developer ID 서명 + Notarization, 직접 배포 (App Store 미지원) |

---

## 기술 스택

- **언어**: Swift 6 (strict concurrency)
- **UI**: SwiftUI + AppKit interop (`NSViewRepresentable`)
- **상태**: `@Observable` (Observation 프레임워크)
- **영속화**: SwiftData
- **압축**: AppleArchive (ZIP)
- **검색**: NSMetadataQuery (Spotlight)
- **미리보기**: QuickLookUI
- **변경 감지**: FSEvents
- **빌드**: Xcode 프로젝트 `MdirX.xcodeproj` (재생성: `python3 scripts/gen_xcode_pbx.py`). SwiftPM 패키지 분리는 후속.
- **테스트**: Swift Testing, XCUITest

---

## 개발 빌드 및 실행

### 요구 환경

| 항목 | 버전 |
|---|---|
| macOS | 15.0 Sequoia 이상 |
| Xcode | 26 이상 |
| Swift | 6.3 이상 |

### 빌드

```bash
# Debug 빌드 (개발용)
xcodebuild \
  -project MdirX.xcodeproj \
  -scheme MdirX \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath dist \
  build

# Release 빌드
xcodebuild \
  -project MdirX.xcodeproj \
  -scheme MdirX \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath dist \
  build
```

### 실행

```bash
# 빌드 후 앱 직접 실행
open dist/Build/Products/Debug/MdirX.app

# 또는 Release
open dist/Build/Products/Release/MdirX.app
```

Xcode에서 열어 실행하려면 `MdirX.xcodeproj`를 열고 `⌘R`.

### Xcode 프로젝트 재생성

`project.pbxproj`는 스크립트로 생성됩니다. 소스 파일을 추가/삭제한 뒤에는 다시 실행해야 합니다.

```bash
python3 scripts/gen_xcode_pbx.py
```

### 테스트

```bash
# 단위 테스트
xcodebuild \
  -project MdirX.xcodeproj \
  -scheme MdirX \
  -destination 'platform=macOS' \
  test
```

---

## NexusFile → MdirX 키맵 요약

| 기능 | MdirX |
|---|---|
| 폴더 점프 다이얼로그 | `F10` |
| 즐겨찾기 | `F11` |
| 단축키 도움말 | `F12` |
| 다른 패널로 복사/이동 | `F5` / `F6` |
| 패널 전환 | `Tab` |
| 고급 이름변경 | `⇧⌥R` |
| ZIP 해제 / 지능형 해제 | `⌘E` / `⌥Q` |
| 전체 선택 토글 (파일→파일+폴더→해제) | `⌥U` |
| QuickLook | `Space` |
| 듀얼/단일 토글 | `⌘\` |

전체 매핑은 [PLAN.md §3](PLAN.md) 참고.

---

## 저장소 구조 (현재)

```
mdirx/  (일부)
├── MdirX.xcodeproj/        # Xcode 프로젝트 (project.pbxproj ← scripts/gen_xcode_pbx.py)
├── App/                    # MdirXApp.swift
├── Features/               # DualPane, Pane 등 화면 단위
├── Core/                   # FileSystemActor, Settings 등 도메인 로직
├── DesignSystem/           # Tokens.swift (색상·폰트 토큰)
├── PlatformBridge/
├── Resources/
├── Tests/
├── MdirX/                  # MdirX.entitlements
├── scripts/
├── dist/                   # 빌드 출력 (xcodebuild -derivedDataPath dist) + settings.json (개발용)
├── README.md               # 이 문서
├── AGENTS.md               # 에이전트 작업 규칙
├── PLAN.md                 # 기술 계획 (아키텍처·키맵·마일스톤)
├── TODO.md                 # PLAN 기준 작업 목록 (체크박스)
├── DONE.md                 # 완료 요약
├── LICENSE                 # MIT
├── .plan/
│   ├── PLAN.md             # 계획 문서 규격 (정본)
│   ├── STATUS.md           # 계획별 진행 한눈에 보기
│   └── *.todo.md …         # 계획 본문 (파일명 규칙은 .plan/PLAN.md 참고)
└── docs/
    ├── PRD.md              # 제품 요구사항 문서
    ├── requirements/       # 프로젝트 전체 생명주기 중요 요건 (REQUIREMENTS.md 등)
    └── learnings/          # 실수·올바른 해결 (영역별, 인덱스: learnings/learnings.md)
```

> 로컬 검증(예): `swift 6.3.2`, `xcodebuild` — SDK macOS 15 타깃으로 `xcodebuild -project MdirX.xcodeproj -scheme MdirX -destination 'platform=macOS' -derivedDataPath dist build` 가 통과하면 됩니다.

---

## 작업·계획 문서 규격

구현·리팩터에 앞서 **계획 문서부터** 쓴다. 세부 규칙·템플릿은 **[`.plan/PLAN.md`](.plan/PLAN.md)** 가 정본이다.

| 항목 | 요지 |
|------|------|
| 위치 | `.plan/` **루트만** (하위 폴더 없음) |
| 파일명 | `{mmdd}-{hhmm}-{요구사항요약}.{상태}.md` — `{상태}`는 `todo`·`doing`·`done`만, 요약 **최대 20자** |
| 본문 | **사용자 요구 (정제)** → 개요 → 요구사항 → 수도 코드 → 아키텍처 → 통과 조건 → 체크리스트 → 테스트 |
| 상태 | `done`은 **사용자 검증·OK** 이후에만 파일명·본문에 반영 |
| 종합 표 | 새 계획·상태 변경 시 **[`.plan/STATUS.md`](.plan/STATUS.md)** 를 같은 턴에 맞춘다 |

에이전트/자동화는 **[`AGENTS.md`](AGENTS.md)** 를 따른다.

---

## 비목표 (1.0 범위 밖)

- FTP / SFTP / WebDAV
- 7z·rar·tar.gz 등 ZIP 외 압축 포맷
- iOS / iPadOS / Windows / Linux
- 클라우드 동기화 자체 구현 (감지·표시는 OK)
- 미디어 뷰어/편집기 (QuickLook 위임)
- App Store 배포

---

## 문서

- [`TODO.md`](TODO.md) — [`PLAN.md`](PLAN.md) 항목 추출·체크박스 목록
- [`DONE.md`](DONE.md) — 완료 작업 요약
- [`.plan/PLAN.md`](.plan/PLAN.md) — **계획 문서 규격**(파일명, 템플릿, 상태, `STATUS` 동기화)
- [`.plan/STATUS.md`](.plan/STATUS.md) — 계획별 진행 요약 표
- [`AGENTS.md`](AGENTS.md) — 에이전트 작업 순서(계획 우선 등)
- [PLAN.md](PLAN.md) — 기술 계획, 아키텍처, 데이터 모델, 키맵 전체
- [docs/learnings/learnings.md](docs/learnings/learnings.md) — 작업 중 실수·해결 정리(영역별)
- [docs/PRD.md](docs/PRD.md) — 제품 요구사항, 페르소나, 사용자 스토리, 성공 지표

---

## 라이선스

**MIT License** — 전문은 [`LICENSE`](LICENSE) 파일 참고.

## 면책

MdirX는 NexusFile(xiles.app)의 비공식 호환 클론입니다. 원작의 상표·코드·리소스를 사용하지 않으며, 키바인딩과 기능 체계의 호환성만 제공합니다.
