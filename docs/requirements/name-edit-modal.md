# 이름 편집 모달 요건 (rename / new folder / new file)

## 개요

`F2`(이름 바꾸기), `⌥K`(새 폴더), `⌃N`(새 파일)는 단일 sheet 모달 [`NameEditModal`](../../Features/Pane/NameEditModal.swift)을 띄워 사용자가 이름을 입력·확정·취소할 수 있게 한다. 인라인 유효성 검증과 IME-안전 키 라우팅이 핵심.

---

## 핵심 요건

### R1. Sheet 트리거
- 단축키: F2 / ⌥K / ⌃N. F-키는 `.onKeyPress(keys:)` 오버로드로 등록 ([`shortcuts.md`](shortcuts.md) R2).
- `PaneState.editing`이 `.rename(URL)` / `.newFolder` / `.newFile` 중 하나로 설정되면 sheet가 자동으로 뜬다 (`PaneColumnView.sheet(item:)`).

### R2. 초기 상태
- rename: `editingDraft = displayName + ext`로 채우고 텍스트 전체 선택 + 포커스.
- new folder/file: `editingDraft = ""`로 시작.
- `editingError`는 `nil`로 초기화.

### R3. 인라인 유효성 검증 ([`PaneState.validateDraft`](../../Features/DualPane/PaneState.swift))
다음 케이스에 인라인 빨간 메시지를 띄우고 확정 버튼 비활성:
- 빈 문자열 → 에러 표시 없이 단순 비활성.
- `/` 또는 `\0` 포함 → "사용할 수 없는 문자: / 또는 NUL".
- `.` 또는 `..` → "이 이름은 사용할 수 없습니다".
- 같은 디렉터리에 같은 이름의 항목이 이미 있음 → "같은 이름의 항목이 이미 있습니다" (rename은 자기 자신 제외).

### R4. 확정·취소
- Enter → `commit(via:)` 호출. 검증 통과 시 FileSystemActor에 위임, 성공 시 sheet 닫고 새 URL로 cursor 이동.
- Esc → `cancelEditing()`, 변경 없음.
- 실패(권한·디스크) 시 `editingError`에 메시지 채워 모달 유지.

### R5. IME 비차단
- 모달이 열려 있는 동안 부모 `.onKeyPress`는 `.ignored` 반환 (TextField가 IME 합성을 받게).
- 학습 노트 [`swiftui/onkeypress-consumed-by-parent-when-sheet-is-open.md`](../learnings/swiftui/onkeypress-consumed-by-parent-when-sheet-is-open.md) 참조.

### R6. Rename 시 selection 정합성
- 기존 URL이 selection에 있었으면 새 URL로 교체. 그래야 일괄 작업이 깨지지 않음.

---

## 안티패턴 (하지 말 것)

- 검증 실패 시 sheet를 닫음 — 사용자가 입력을 잃음.
- 모달 안에서 전역 단축키(F5/F6 등)가 발화 — `editing != nil`일 때는 무시해야 한다.
- 같은 이름 충돌을 FileSystemActor 에러로만 처리 — 인라인으로 사전 검증해서 디스크 I/O 전에 알려야 한다.

## 참고
- [`.plan/0516-1746-rename-newfolder-newfile.done.md`](../../.plan/0516-1746-rename-newfolder-newfile.done.md)
- [`Features/Pane/NameEditModal.swift`](../../Features/Pane/NameEditModal.swift)
- [`Features/DualPane/PaneState.swift`](../../Features/DualPane/PaneState.swift)
