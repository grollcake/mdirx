# MdirX

> **Mdir, reborn on macOS.**
> NexusFile 호환 키바인딩과 듀얼 패널 워크플로우를 macOS 15+ 네이티브로.

[![status](https://img.shields.io/badge/status-planning-yellow)]()
[![platform](https://img.shields.io/badge/platform-macOS%2015%2B-blue)]()
[![swift](https://img.shields.io/badge/Swift-6-orange)]()
[![ui](https://img.shields.io/badge/UI-SwiftUI-purple)]()

---

## 소개

MdirX는 macOS용 듀얼 패널 파일 매니저입니다. DOS 시절의 **Mdir / NCD** 와 Windows의 **NexusFile** 을 사용해 온 파워유저가 macOS에서 동일한 키보드 중심 워크플로우를 그대로 쓸 수 있도록 설계됩니다.

- 좌우 듀얼 패널 + 패널별 독립 탭
- F10 폴더 점프 (NCD/MCD 스타일 퍼지 검색)
- F11 즐겨찾기
- 고급 이름변경 (정규식·번호매김·라이브 프리뷰)
- ZIP 압축/해제, 지능형 해제
- QuickLook · FSEvents 실시간 갱신
- 사용자 정의 함수키(F1~F12)
- 라이트/다크 스킨

> ⚠️ 현재 **기획 단계**입니다. 코드는 아직 없으며, 본 저장소는 계획·요구사항 문서로 시작합니다.

---

## 상태

| 항목 | 상태 |
|---|---|
| 단계 | 기획 (Planning) |
| 다음 마일스톤 | M1 — 듀얼 패널·탭·FS 작업·키보드 네비게이션 |
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
- **빌드**: Xcode 16 + Swift Package Manager
- **테스트**: Swift Testing, XCUITest

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
| 선택 반전 | `⌥U` |
| QuickLook | `Space` |
| 듀얼/단일 토글 | `⌘\` |

전체 매핑은 [PLAN.md §3](PLAN.md) 참고.

---

## 저장소 구조 (현재)

```
mdirx/  (일부)
├── README.md              # 이 문서
├── AGENTS.md               # 에이전트 작업 규칙 ([CLAUDE.md](CLAUDE.md)와 동일 내용 하드링크)
├── PLAN.md                 # 기술 계획 (아키텍처·키맵·마일스톤)
├── TODO.md                 # PLAN 기준 작업 목록 (체크박스)
├── DONE.md                 # 완료 요약
├── LICENSE                 # MIT
├── .plan/
│   ├── README.md           # 계획 문서 규격(정본)
│   ├── STATUS.md           # 계획별 진행 한눈에 보기
│   └── *.todo.md …         # 계획 본문 (파일명 규칙은 .plan/README 참고)
└── docs/
    ├── PRD.md              # 제품 요구사항 문서
    └── learnings/          # 실수·올바른 해결 (영역별, 인덱스: learnings/README.md)
```

코드는 M1 킥오프와 함께 추가됩니다.

---

## 작업·계획 문서 규격

구현·리팩터에 앞서 **계획 문서부터** 쓴다. 세부 규칙·템플릿은 **[`.plan/README.md`](.plan/README.md)** 가 정본이다.

| 항목 | 요지 |
|------|------|
| 위치 | `.plan/` **루트만** (하위 폴더 없음) |
| 파일명 | `{mmdd}-{hhmm}-{요구사항요약}.{상태}.md` — `{상태}`는 `todo`·`doing`·`done`만, 요약 **최대 20자** |
| 본문 | **사용자 요구 (정제)** → 개요 → 요구사항 → 수도 코드 → 아키텍처 → 통과 조건 → 체크리스트 → 테스트 |
| 상태 | `done`은 **사용자 검증·OK** 이후에만 파일명·본문에 반영 |
| 종합 표 | 새 계획·상태 변경 시 **[`.plan/STATUS.md`](.plan/STATUS.md)** 를 같은 턴에 맞춘다 |

에이전트/자동화는 **[`AGENTS.md`](AGENTS.md)** 를 따른다.

---

## 로드맵

| 마일스톤 | 기간 | 산출물 |
|---|---|---|
| **M1** | 2주 | 듀얼 패널·탭·기본 FS 작업·키보드 네비게이션 |
| **M2** | 2주 | F10 점프·F11 즐겨찾기·고급 이름변경·검색 |
| **M3** | 2주 | ZIP·QuickLook·FSEvents·함수키 카탈로그 |
| **M4** | 1.5주 | 스킨/테마·환경설정·import/export |
| **M5 (1.0)** | 1주 | 베타·서명·공증·DMG 배포 |

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
- [`.plan/README.md`](.plan/README.md) — **계획 문서 규격**(파일명, 템플릿, 상태, `STATUS` 동기화)
- [`.plan/STATUS.md`](.plan/STATUS.md) — 계획별 진행 요약 표
- [`AGENTS.md`](AGENTS.md) — 에이전트 작업 순서(계획 우선 등)
- [PLAN.md](PLAN.md) — 기술 계획, 아키텍처, 데이터 모델, 키맵 전체
- [docs/learnings/README.md](docs/learnings/README.md) — 작업 중 실수·해결 정리(영역별)
- [docs/PRD.md](docs/PRD.md) — 제품 요구사항, 페르소나, 사용자 스토리, 성공 지표

---

## 라이선스

**MIT License** — 전문은 [`LICENSE`](LICENSE) 파일 참고.

## 면책

MdirX는 NexusFile(xiles.app)의 비공식 호환 클론입니다. 원작의 상표·코드·리소스를 사용하지 않으며, 키바인딩과 기능 체계의 호환성만 제공합니다.
