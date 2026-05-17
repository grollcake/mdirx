# 주소창·경로 히스토리 요건

## 개요

활성 패널 헤더에서 breadcrumb ↔ 주소 입력 모드를 전환하며, 입력은 **절대 경로(또는 `~` 확장)** 만 허용한다. 이동 성공 시 패널별 히스토리에 기록되고, "자주 방문"(top 5) + "최근 방문" 두 섹션 메뉴로 재사용할 수 있다.

---

## 핵심 요건

### R1. 주소 입력 검증
[`AddressPathValidator.expandAndNormalize`](../../Features/AddressBar/AddressPathValidation.swift):
- 입력 앞뒤 공백 trim.
- `~`는 home 디렉터리로 확장.
- 절대 경로가 아니면 `.notAbsolutePath` 실패.
- 경로가 존재하지 않거나 디렉터리가 아니면 `.folderNotFound` 실패.
- 성공 시 `standardizedFileURL` 반환.

### R2. 입력 모드 전환·이탈
- `⌘L` 또는 breadcrumb 영역 더블클릭으로 활성 패널만 주소 입력 모드 진입.
- 진입 시 TextField에 `currentURL.path`가 전체 선택된 채 표시.
- Enter → 검증·이동. 성공 시 모드 자동 종료. 실패 시 인라인 오류, 모드 유지.
- Esc → 이동 없이 즉시 breadcrumb 복귀.

### R3. 히스토리 저장 규칙
[`PathHistoryStore.recordVisit`](../../Core/Persistence/PathHistoryStore.swift):
- 이동 성공 시 `PathHistoryEntry`(SwiftData)에 upsert.
- 같은 (path, paneSlot) 행이 있으면 행을 추가하지 않고 `visitedAt = now`, `visitCount += 1` 갱신.
- 패널별로 최대 **20개** 유지. 초과 시 `visitedAt` 오래된 항목부터 prune.
- 앱 재시작 후에도 유지(persistent SwiftData container).

### R4. 메뉴 표시 규칙
[`PathHistoryStore.menuURLs`](../../Core/Persistence/PathHistoryStore.swift):
- "자주 방문" 섹션: `visitCount desc → visitedAt desc`로 top 5 선정 후 **경로 알파벳 오름차순(대소문자 무시)** 으로 표시(시각 안정성).
- "최근 방문" 섹션: 자주 방문에 든 경로를 제외한 나머지를 `visitedAt desc`로.
- 한쪽 섹션이 비면 해당 헤더도 표시하지 않음.

### R5. 텍스트 입력 격리
- 주소 편집 모드에서 전역 키 핸들러는 Esc/⌘L 외의 키를 `.ignored`로 반환해 TextField가 IME 합성을 받게 한다.
- NameEdit 모달과 동일 원칙 (요건은 [`name-edit-modal.md`](name-edit-modal.md) 참고).

---

## 안티패턴 (하지 말 것)

- 상대 경로 자동 보정(예: 현재 폴더 기준 join). 의도 모호 — 무조건 절대 경로만.
- 같은 경로 재방문에 새 행 insert (visitCount 누적 깨짐).
- 패널 구분 없이 단일 히스토리 사용 (좌/우 각각 다른 빈도가 의미).

## 참고
- [`.plan/0517-0938-addressbar-history.done.md`](../../.plan/0517-0938-addressbar-history.done.md)
- [`Features/AddressBar/`](../../Features/AddressBar/)
- [`Core/Persistence/PathHistoryStore.swift`](../../Core/Persistence/PathHistoryStore.swift)
