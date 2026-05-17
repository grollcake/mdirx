# 패널 행(`paneRows`) 구성 요건

## 개요

파일 리스트의 행 목록(`paneRows`)은 디렉터리 entries + parent link + mounted volumes를 합쳐 화면용 표시 순서로 구성한다. URL 중복·플래그 신뢰성 문제를 회피하기 위한 고정 규칙이 있다.

---

## 핵심 요건

### R1. 첫 행은 항상 부모 링크(`..`)
- 루트(`/`)나 마운트 볼륨 루트가 아닌 한, row 0은 `..` 부모 링크.
- 부모 링크는 선택 불가(`isParentLink == true`) — 다중 선택·F5/F6 대상에서 제외.

### R2. 마운트 볼륨 중복은 URL 집합으로 제거
- `mountedVolumes` 목록의 URL을 `Set`으로 모은 `volumeIDs`를 만들어 `entries`에서 ID 매치로 제외한다.
- **`isMountedVolume` 플래그는 신뢰하지 말 것** — 학습 노트 [`swiftui/ismountedvolume-flag-always-false-dedup-mismatch.md`](../learnings/swiftui/ismountedvolume-flag-always-false-dedup-mismatch.md) 참조.
- 같은 URL을 가진 심볼릭이 볼륨과 충돌하면 한쪽만 표시(중복 행 금지).

### R3. 행 번호는 dedup 후 1..N 순차
- 화면 좌측 행 번호는 dedup·정렬을 마친 최종 paneRows의 인덱스 기반.
- ForEach의 id 충돌 시 한쪽만 렌더되어 행 번호가 뒤죽박죽 되는 함정 회피 — 학습 노트 [`swiftui/foreach-duplicate-url-id-when-symlink-meets-mounted-volume.md`](../learnings/swiftui/foreach-duplicate-url-id-when-symlink-meets-mounted-volume.md) 참조.

### R4. selectable 정의
- "선택 가능"은 `!isParentLink && !isMountedVolume && volumeIDs에 없음` 의 교집합.
- `selectableEntries` / `selectableIDs` / `fileOnlyIDs` 모두 이 정의를 따른다.
- 전체 선택 토글·F5/F6·extendRange 등 모든 일괄 작업이 이 정의를 기준으로 한다.

---

## 안티패턴 (하지 말 것)

- `entries.filter { $0.isMountedVolume }` — 플래그가 항상 false라 무력.
- 마운트 볼륨을 entries 끝에 무조건 append (dedup 없음).
- 부모 링크를 selectableIDs에 포함.

## 참고
- [`Features/Pane/PaneRow.swift`](../../Features/Pane/PaneRow.swift)
- [`Features/DualPane/PaneState.swift`](../../Features/DualPane/PaneState.swift)
- 학습: [`swiftui/ismountedvolume-flag-always-false-dedup-mismatch.md`](../learnings/swiftui/ismountedvolume-flag-always-false-dedup-mismatch.md), [`swiftui/foreach-duplicate-url-id-when-symlink-meets-mounted-volume.md`](../learnings/swiftui/foreach-duplicate-url-id-when-symlink-meets-mounted-volume.md), [`swiftui/select-all-must-exclude-volumes-via-url-set.md`](../learnings/swiftui/select-all-must-exclude-volumes-via-url-set.md)
