# 파일 작업 안전성 요건 (preflight·충돌·제외)

## 개요

F5(복사)·F6(이동) 같은 파일 작업은 시작 전 **모든 대상 경로를 확인**하고, 충돌이 있으면 **자동 덮어쓰기 없이 실패**한다. 부모 링크·마운트 볼륨처럼 의미상 작업 대상이 아닌 행은 자동으로 제외된다.

---

## 핵심 요건

### R1. Preflight: 작업 전 모든 destination 검증
[`FileSystemActor.preflightDestinations(for:in:)`](../../Core/FileSystem/FileSystemActor.swift) 가 단일 진입점.
- 대상 디렉터리가 실제 폴더인지 확인. 아니면 `NSFileNoSuchFileError` throw.
- 각 source URL이 destination에서 같은 이름으로 이미 존재하면 `NSFileWriteFileExistsError` throw.
- 어떤 파일도 복사·이동을 시작하지 않은 상태에서 실패해야 한다 (atomic-or-throw 의도).

### R2. 자동 덮어쓰기 절대 금지
- 같은 이름의 destination이 하나라도 있으면 작업 전체가 시작되지 않는다 (부분 진행 금지).
- 향후 "덮어쓰기" 정책이 필요해도 별도 UI 명시 선택을 거쳐야 하고, 기본 동작은 거부.

### R3. 작업 대상은 selectable 행만
[`PaneState.operationItemURLs`](../../Features/DualPane/PaneState.swift) 기준:
- 부모 링크(`..`), 마운트 볼륨 행은 작업 대상에서 제외.
- selection이 있으면 selection 전체, 비어 있으면 cursor 항목 1개.
- cursor가 부모/볼륨이면 결과는 빈 배열 → 작업 no-op.

### R4. 성공 시 양 패널 reload
- 작업 성공 시 source/destination 패널을 병렬 `load(via:)`로 갱신.
- `PaneState.load`의 `selection.formIntersection(alive)`로 사라진 항목의 selection 자동 정리.

### R5. 실패 시 source.error에 메시지 흘리기
- 실패는 `source.error`에 사용자 친화 메시지를 채워 상태바 등에 노출. 앱 크래시 금지.

---

## 안티패턴 (하지 말 것)

- preflight 통과 후 중간 항목에서 실패했는데 이미 처리된 destination을 그대로 두기 (현재는 미해결 — 후속 큐/Undo 계획 대상이지만, 이번 범위 외 변경 금지).
- 부모 링크나 볼륨 행을 작업 대상에 포함시키기.
- `FileManager.copyItem`/`moveItem`을 `preflightDestinations` 우회해서 직접 호출.

## 참고
- [`.plan/0517-0919-f5-f6-file-ops.done.md`](../../.plan/0517-0919-f5-f6-file-ops.done.md)
- [`Core/FileSystem/FileSystemActor.swift`](../../Core/FileSystem/FileSystemActor.swift)
