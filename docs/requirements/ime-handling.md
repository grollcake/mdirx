# IME 처리 요건 (한글 중심)

## 개요

macOS 입력 소스가 한글일 때도 단축키·텍스트 입력·키 라우팅이 영문 상태와 동일하게 동작해야 한다. 향후 일본어·중국어 IME가 추가되어도 같은 정규화 인프라로 흡수할 수 있어야 한다.

[`shortcuts.md`](shortcuts.md)는 단축키 라우팅 규칙에 집중, 이 문서는 IME 횡단 관심사를 다룬다.

---

## 핵심 요건

### R1. 단축키 IME-불변 발화
- 모든 modifier+문자 단축키는 입력 소스(영문/한글)와 무관하게 같은 동작.
- 상세 규칙·정규화 의무: [`shortcuts.md`](shortcuts.md) R1·R2 참조.

### R2. 한글 자모 → QWERTY 역매핑 (영구 매핑표)
- 표준 2-set 한글 자판 33자 매핑 (단자음·모음 26 + 쌍자음·복모음 7).
- 구현: [`Features/DualPane/KoreanShortcutNormalizer.swift`](../../Features/DualPane/KoreanShortcutNormalizer.swift)의 `hangulToQwerty: [Unicode.Scalar: Character]`.
- **매핑 변경 금지** — 입력 표준이므로 임의 수정 시 사용자 단축키가 깨진다. 추가는 다른 IME 확장 시.

| 행 | 매핑 |
|----|------|
| 윗줄 (q~p) | ㅂ→q, ㅈ→w, ㄷ→e, ㄱ→r, ㅅ→t, ㅛ→y, ㅕ→u, ㅑ→i, ㅐ→o, ㅔ→p |
| 중간 (a~l) | ㅁ→a, ㄴ→s, ㅇ→d, ㄹ→f, ㅎ→g, ㅗ→h, ㅓ→j, ㅏ→k, ㅣ→l |
| 아랫줄 (z~m) | ㅋ→z, ㅌ→x, ㅊ→c, ㅍ→v, ㅠ→b, ㅜ→n, ㅡ→m |
| 쌍 (shift) | ㅃ→Q, ㅉ→W, ㄸ→E, ㄲ→R, ㅆ→T, ㅒ→O, ㅖ→P |

### R3. TextField 내 한글 합성 보존
- NameEdit 모달과 주소 popover가 활성일 때 전역 `.onKeyPress` 핸들러는 **`.ignored`** 를 반환해 TextField가 IME 합성 이벤트를 받게 한다.
- 활성 중 명시적으로 처리하는 키만 가로채기:
  - 주소 popover: `Esc`(닫기), `↑`/`↓`(리스트 탐색), `Enter`(리스트 항목 선택 또는 입력 경로 navigate).
  - NameEdit 모달: `Esc`(취소), `Enter`(commit).
- 그 외 모든 키는 TextField로 양보 → 한글/영문 입력 모두 정상.

### R4. 한글 IME 상태에서 정규화 없이도 OK인 키
정규화 헬퍼를 거치지 않아도 한글 IME에서 동작이 깨지지 않는 키들:
- **펑션 키(F2~F12)** — IME가 자모로 변환하지 않음. 단 `.onKeyPress(keys:)` 오버로드에 등록해야 클로저로 라우팅됨 ([`shortcuts.md`](shortcuts.md) R2).
- **빌트인 `KeyEquivalent`** (`Tab`, `Return`, `Space`, `Escape`, `.upArrow`, `.downArrow`) — IME 영향 없음.
- **modifier 없는 ASCII 구두점** (`.`, `/`, `\` 등) — 한글 IME는 ASCII 구두점을 변환하지 않음.

→ 위 카테고리만 사용하는 단축키는 정규화 없이 안전.
→ **modifier + 문자(a~z) 조합은 반드시 정규화**해야 한다.

### R5. 한글 입력 합성 중 단축키 동작 (현재 미해결)
- 사용자가 합성 미완 자모(예: `ㄱ`만 누른 상태)에서 단축키를 누를 때의 동작이 명시되지 않음.
- 통상 macOS는 합성을 강제 커밋한 뒤 단축키를 전달한다. 실제 동작은 사용자 보고가 들어오면 검증·명시.
- 현재 코드는 합성 상태를 별도 감지하지 않으며, OS 기본 동작에 위임한다.

### R6. 다른 IME 확장 정책
- 일본어·중국어·러시아어 등 새 IME 지원 시:
  - `KoreanShortcutNormalizer`에 해당 입력 자모 → QWERTY 매핑 테이블만 추가.
  - 헬퍼 인터페이스(`qwertyCharacter(for:)` / `normalize(character:modifiers:)`)는 유지.
  - 새 IME 매핑 단위 테스트 추가.
- 단일 헬퍼로 모든 IME를 흡수 — 호출 사이트(DualPaneView 등)는 변경 불필요.

### R7. 회귀 방지
- IME 관련 코드를 변경(헬퍼 / DualPaneView 키 라우팅 / TextField 입력 흐름 / 신규 단축키)할 때 다음을 통과 조건에 명시:
  - 영문 IME에서 영향받는 모든 단축키·텍스트 입력 수동 검증.
  - 한글 IME에서 같은 시나리오 수동 검증.
- 매핑 표 변경 시 [`KoreanShortcutNormalizerTests`](../../Tests/UnitTests/KoreanShortcutNormalizerTests.swift)에 케이스 추가.

---

## 안티패턴 (하지 말 것)

- **한글 IME 상태에서 `press.key == KeyEquivalent("l")` 직접 비교** — 자모(`ㅣ`)와 비교해 매칭 실패. 반드시 `KoreanShortcutNormalizer`를 거칠 것.
- **펑션 키를 메인 `.onKeyPress(action:)` 클로저에 등록** — 클로저로 라우팅되지 않아 system beep만 발생.
- **NameEdit/주소 popover 등 텍스트 입력 활성 중 전역 핸들러가 `.handled` 반환** — IME 합성 입력이 막혀 한글이 안 찍힘.
- **자모 매핑 테이블 임의 변경/축소** — 사용자 단축키가 한순간에 깨진다.

---

## 참고

- 코드: [`Features/DualPane/KoreanShortcutNormalizer.swift`](../../Features/DualPane/KoreanShortcutNormalizer.swift)
- 테스트: [`Tests/UnitTests/KoreanShortcutNormalizerTests.swift`](../../Tests/UnitTests/KoreanShortcutNormalizerTests.swift)
- 학습 노트: [`docs/learnings/swiftui/onkeypress-character-becomes-hangul-jamo-under-korean-ime.md`](../learnings/swiftui/onkeypress-character-becomes-hangul-jamo-under-korean-ime.md)
- 단축키 라우팅 요건: [`shortcuts.md`](shortcuts.md)
- 모달 격리: [`name-edit-modal.md`](name-edit-modal.md) R5, [`address-bar-history.md`](address-bar-history.md) R5
