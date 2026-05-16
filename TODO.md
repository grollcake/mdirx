# TODO

> [`PLAN.md`](PLAN.md) 기준 옮김. 실행 단위 계획은 `.plan/`, 한 줄 진행은 `.plan/STATUS.md`. **아래 목록은 모두 `- [ ]` / `- [x]` 할 일 목록 형식만 사용한다.**

## 즉시 (PLAN §10)

- [x] 라이선스: **MIT** 확정
- [x] 작업 디렉터리: **`mdirx`** 로 반영됨
- [x] Xcode 16: 설치·사용 가능 확인됨
- [ ] M1 킥오프 — 프로젝트 스캐폴딩

## 마일스톤 (PLAN §9)

- [ ] **M1** (2주): 듀얼 패널·탭·기본 FS 작업·키보드 네비게이션, FS actor, ViewModel 기반
- [ ] **M2** (2주): F10 점프·F11 즐겨찾기·고급 이름변경·검색·주소표시줄 히스토리
- [ ] **M3** (2주): ZIP 압축/해제·QuickLook·FSEvents·함수키 카탈로그·명령 팔레트
- [ ] **M4** (1.5주): 스킨/테마·환경설정·설정 영속화·import/export
- [ ] **M5** (1주): 베타·서명·공증·DMG 배포 채널

## Phase 1 — Core, M1~M2 (PLAN §2)

- [ ] 단일/듀얼 패널 토글
- [ ] 패널별 독립 탭 (NSTabView 스타일)
- [ ] 폴더 트리 사이드바
- [ ] 주소표시줄 + 경로 히스토리 드롭다운
- [ ] 파일 작업: 복사·이동·붙여넣기·이름변경·새폴더
- [ ] 3단계 삭제: 휴지통 / 완전삭제 / 0-덮어쓰기
- [ ] 선택: 전체·역선택·패턴(글롭/정규식)
- [ ] 키보드 네비게이션 (Vim-like + macOS 표준 동시 지원)
- [ ] 작업폴더(워킹 디렉터리) 지정
- [ ] 폴더 점프 다이얼로그 (F10) — NCD/MCD 스타일 퍼지 검색
- [ ] 즐겨찾기 (F11)
- [ ] 고급 이름변경 (⇧⌥R) — 패턴·정규식·번호·대소문자
- [ ] 폴더 내 검색 (⌘F) + Spotlight 글로벌 검색

## Phase 2 — Power, M3~M4 (PLAN §2)

- [ ] ZIP 압축/해제 (⌘E), 지능형 해제 (⌥Q)
- [ ] 아카이브 내부 탐색 (가상 폴더처럼)
- [ ] QuickLook 미리보기 (Space)
- [ ] FSEvents 실시간 갱신
- [ ] 사용자 정의 함수키 (F1~F12)
- [ ] 경로 복사 옵션: 전체경로·파일명·폴더경로
- [ ] 심볼릭 링크 표시·해석
- [ ] 스킨/테마 (라이트/다크 + 컬러 토큰 커스텀)
- [ ] 설정 영속화·import/export

## Phase 3 — macOS 통합, M5 이후 (PLAN §2)

- [ ] Finder 태그 통합
- [ ] iCloud Drive 인식 표시
- [ ] AppleScript / Shortcuts 지원
- [ ] 서비스 메뉴 등록

## 단축키·UX (PLAN §3 원칙)

- [ ] NexusFile 단축키 1차 + macOS 보조 바인딩 (표 전체 구현)
- [ ] 사용자 커스터마이즈 가능하도록 설계

## 키 디자인 결정 (PLAN §7)

- [ ] F10 트리 점프: 모달 오버레이, 퍼지 매칭·↑↓·Enter
- [ ] 고급 이름변경: Live Preview 표 + 정규식 그룹 캡처
- [ ] 함수키 = 명령 팔레트(⌘⇧P)와 동일 명령 카탈로그 공유
- [ ] 압축 해제: 백그라운드 큐 + 진행률 상태바
- [ ] 0-덮어쓰기 삭제: 확인 다이얼로그 + 「다시 묻지 않기」

## 아키텍처·인프라 (PLAN §4 요지)

- [ ] 디렉터리 구조 (App / Features / Core / DesignSystem / PlatformBridge / Tests) 스캐폴딩
- [ ] `FileSystemActor` + `OperationQueue` + `@MainActor` ViewModel/`@Observable` 패턴 확립
- [ ] SwiftData 모델: Favorite, PathHistoryEntry, FunctionKeyBinding, ThemeProfile, PaneSnapshot (§5)

## 데이터·UI 참고 (PLAN §5·§6)

- [ ] §5 모델 코드 기준으로 스키마 반영
- [ ] §6 레이아웃 스케치 기준 UI 골격 (툴바·사이드바·듀얼 패널·상태바)

## 리스크 대응 (PLAN §8)

- [ ] 비샌드박스 / Full Disk Access 온보딩·딥링크
- [ ] M1 초기 Swift 6 동시성 패턴 가이드(내부 문서)
- [ ] 대용량 리스트 성능 전략 (`LazyVStack` 등, 필요 시 NSTableView interop)
- [ ] NexusFile 사용자용 키맵 마이그레이션 가이드·프리셋
- [ ] M5 베타 전 Notarization 사전 검증

## 확정 결정사항 준수 (PLAN §1)

- [ ] 비샌드박스·Finder 수준 자유도 전제 유지
- [ ] 최소 macOS 15 전제 유지
- [ ] 압축은 ZIP만(AppleArchive), 기타 포맷 제외 전제 유지
- [ ] FTP/SFTP 제외 전제 유지
- [ ] Swift 6 + SwiftUI(AppKit은 interop만) 전제 유지
- [ ] 상태: `@Observable`, 영속화: SwiftData 전제 유지
- [ ] FS 작업: actor 격리, UI는 `@MainActor` 전제 유지
