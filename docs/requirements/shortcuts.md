# 단축키 요건

## 개요

파일 리스트 영역에서 정의된 모든 단축키는 **시스템 입력 소스(IME)와 무관하게 동작**해야 한다.
특히 한글 IME가 켜진 상태에서도 `⌘L`·`⌥K`·`⌃N`·`⌘A`·`⌥U`·`⌘Z` 같은 modifier+문자 단축키가 영문 상태와 동일하게 발화해야 한다.

---

## 핵심 요건

### R1. IME-불변 (IME-independent) 발화
- 모든 단축키는 macOS 입력 소스가 영문/한글/(향후 일본어 등) 어느 쪽이든 같은 동작을 보장한다.
- 한글 IME 상태에서 `press.key.character`가 한글 자모(예: `ㅣ`/`ㅏ`/`ㅁ`)로 들어와도 modifier가 함께 눌렸다면 QWERTY 위치 문자로 정규화 후 매칭한다.
- 정규화는 [`KoreanShortcutNormalizer`](../../Features/DualPane/KoreanShortcutNormalizer.swift)로 단일화 — 새 단축키도 같은 헬퍼를 통해 비교한다.

### R2. 신규 단축키 등록 규칙
- modifier+문자 비교는 **반드시 `KoreanShortcutNormalizer.qwertyCharacter(for:)` 결과로** 한다. 직접 `press.key == KeyEquivalent("k")` 비교는 한글 IME에서 깨지므로 금지.
- 펑션 키(F2~F12)는 별도 `.onKeyPress(keys: [...])` 오버로드에 등록한다 (`.onKeyPress(action:)` 클로저는 펑션 키를 라우팅하지 않음).
- modifier 없는 단일 문자(`.`, Space, Tab 등)는 빌트인 `KeyEquivalent` 상수 또는 ASCII 문자 비교로 둔다 (IME가 ASCII 구두점은 변환하지 않음).

### R3. 텍스트 입력 모드와의 격리
- NameEdit 모달과 주소창 편집 모드(`PaneState.editing`, `PaneState.addressEditing`)가 활성일 때 전역 키 핸들러는 `.ignored`를 반환해 TextField가 IME 합성을 정상적으로 받게 한다.
- 단, 모달/편집 모드 안에서도 의도된 키(예: 주소 모드의 Esc, NameEdit의 Return)는 명시적으로 처리한다.

### R4. 회귀 방지
- 새 단축키를 추가하거나 기존 비교 로직을 수정한 경우, **영문/한글 IME 양쪽에서 수동 검증**한 결과를 해당 계획 문서의 통과 조건에 기록한다.
- `KoreanShortcutNormalizer` 매핑 변경 시 단위 테스트([`KoreanShortcutNormalizerTests.swift`](../../Tests/UnitTests/KoreanShortcutNormalizerTests.swift))를 함께 업데이트한다.

---

## 현재 단축키 목록

| 키 | 동작 | IME 안전 처리 |
|----|------|---------------|
| `⌘L` | 활성 패널 주소 입력 모드 진입 | normalizer |
| `⌥K` | 새 폴더 만들기 | normalizer |
| `⌃N` | 새 파일 만들기 | normalizer |
| `⌘A` / `⌥U` | 전체 선택 3단계 토글 | normalizer |
| `⌘Z` / `⌥Z` | 숨김 파일 표시 토글 | normalizer |
| `.` | 부모 디렉터리로 이동 | ASCII 문자(IME 무관) |
| `⌘↑` | 부모 디렉터리로 이동 | 빌트인 `.upArrow` |
| `Tab` | 활성 패널 전환 | 빌트인 `.tab` |
| `Return` | 더블클릭 동작(폴더 진입/파일 열기) | 빌트인 `.return` |
| `Space` | 커서 항목 선택 토글 + 다음 행 | 빌트인 `.space` |
| `Esc` | 선택 해제 / 편집 모달 취소 / 주소 모드 취소 | 빌트인 `.escape` |
| `↑` / `↓` | 커서 이동 (Shift 동반 시 범위 선택) | 빌트인 방향키 |
| `F2` | 이름 바꾸기 | `.onKeyPress(keys:)` 오버로드 |
| `F5` | 반대 패널로 복사 | `.onKeyPress(keys:)` 오버로드 |
| `F6` | 반대 패널로 이동 | `.onKeyPress(keys:)` 오버로드 |

---

## 안티패턴 (하지 말 것)

- 한글 IME 상태에서 `press.key == KeyEquivalent("l")` 직접 비교 — 자모(`ㅣ` U+3163)와 비교하므로 매칭 실패, system beep 발생.
- 펑션 키를 메인 `.onKeyPress(action:)` 클로저 안에서 `KeyEquivalent(Character(Unicode.Scalar(0xF705)!))`로 비교 — 클로저로 라우팅되지 않음.
- 모달/주소 편집 활성 중에 전역 키 핸들러가 `.handled` 반환 — IME 합성·텍스트 입력이 깨진다.
