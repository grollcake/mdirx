# 듀얼 패널 활성화·포커스 요건

## 개요

두 패널 중 정확히 하나만 "활성(active)" 상태이며, 활성 패널이 모든 키 단축키와 F5/F6 같은 패널 작업의 **출처(source)** 가 된다. 반대 패널은 자동으로 **대상(target)** 이 된다.

---

## 핵심 요건

### R1. 활성 패널은 항상 하나
- `BrowserSession.activePane`은 `.left` 또는 `.right` 중 하나만 가질 수 있다.
- 앱 시작 시 기본값은 `.left`.

### R2. Tab 키로 좌↔우 토글
- `Tab`은 `activePane`을 반대편으로 바꾼다 (양방향).
- 토글 시 양 패널의 `cursorID`·`selection`·`currentURL`은 보존된다 (포커스만 이동).

### R3. 단일 클릭으로 활성화
- 패널 어느 영역(헤더/리스트 행/빈 공간/상태바)을 단일 클릭하면 그 패널이 활성화된다.
- 리스트 행을 클릭한 경우 cursor를 그 행으로 이동시킨다.
- 클릭 한 번으로는 selection을 변경하지 않는다(Shift/Cmd modifier가 없을 때).

### R4. 더블클릭 라우팅은 항목 유형에 따라 분기
[`PaneState.inspectPrimaryMouseDoubleClick`](../../Features/DualPane/PaneState.swift) 기준:

| 항목 유형 | 동작 |
|----------|------|
| 부모 링크 `..` | 부모 디렉터리로 ascend |
| 마운트 볼륨 | 해당 볼륨 루트로 navigate |
| 디렉터리 | 디렉터리 진입 |
| 파일 | `NSWorkspace.open(_:)` |
| 선택 없음 | no-op |

### R5. F5/F6의 source/target 규칙
- F5(복사)·F6(이동)은 활성 패널을 source로, 반대 패널의 `currentURL`을 target으로 사용한다.
- selection이 비어 있으면 cursor 1개를 사용한다. 부모 링크·마운트 볼륨은 선택 불가 행으로 제외.

---

## 안티패턴 (하지 말 것)

- 활성 패널이 아닌 곳에서 단축키가 발화 — 모든 키 단축키는 `session.current`를 통해 활성 패널에 적용해야 한다.
- 키보드로 패널 전환했다고 cursor를 재설정 — Tab은 포커스만 이동, cursor 유지.
- 마운트 볼륨 행을 더블클릭했을 때 `NSWorkspace.open` 호출 — 폴더 진입처럼 navigate 해야 한다.

## 참고
- [`.plan/0516-1726-mouse-activation-and-doubleclick.done.md`](../../.plan/0516-1726-mouse-activation-and-doubleclick.done.md)
- [`Features/DualPane/BrowserSession.swift`](../../Features/DualPane/BrowserSession.swift)
- [`Features/DualPane/PaneState.swift`](../../Features/DualPane/PaneState.swift)
