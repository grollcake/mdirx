# Nexus 룩앤필 — 정밀 일치 (재시도)

## 사용자 요구 (정제)

- **원문 뉘앙스:** ".plan 에 이미지 파일이 3개가 있어. 이거랑 UI를 똑같이 완전히 똑같이 만들고 싶어. 캡처 붙여넣기는 현재 구현 수준이야. 달라도 너무 달라."
- **정제:** `.plan/Nexus Capture 1.png` `Nexus Capture 2.png` `Nexus Capture 3.png` 와 **두 패널의 시각 결과가 픽셀·색·폰트·정보 컬럼 단위로 같아 보이도록** 한다. 직전 [0516-1732-nexusfile-look-remediation.done.md](0516-1732-nexusfile-look-remediation.done.md) (폐기) 는 명세가 있었음에도 결과 캡처 `.plan/MdirX Current.png` 가 크게 어긋났다 — 본 계획은 그 **어긋난 항목만 콕 집어 다시** 일치시킨다.
- **의도 보존:** 데이터·서비스 레이어는 그대로. 새 모델/서비스 만들지 않음. **View·포맷·치수 조정**만.
- **비포함(사용자 지시):** Description 컬럼 텍스트 내용(`Markdown File`/`JSON 원본 파일` 등), 상단 TAB 바, 자체 메뉴 바 — 별도 계획으로.

## 개요

`.plan/MdirX Current.png` 를 Nexus 캡처와 직접 비교했을 때 어긋난 10개 지점 중, 사용자가 선택한 8개를 본 계획에서 처리한다. 핵심은 **(a) Attrs/Description 컬럼 복원**, **(b) Name 컬럼 좌측 잘림 원인 제거**, **(c) 시간을 24h 로**, **(d) 볼륨 행이 표 안에서 capsule + "남음" 으로 보이도록**, **(e) 행 밀도를 Nexus 수준으로 축소**.

---

## 어긋남 → 수정 사양 (한 표로 통제)

| # | 어긋남 (현재) | 수정 사양 (목표) | 변경 파일 | 검증 |
|---|---|---|---|---|
| **G1** | 컬럼 7개 (#, 아이콘, Name, Ext, Size, Date, Time) | **컬럼 9개** — 끝에 `Attrs` (폭 48, leading, `.system(size: 11).monospaced()`, `Color(white: 0.55)`), `Description` (min 100, flexible, leading, `.system(size: 11)`, `FileColorToken.color(for: row)`) 추가 | `Features/Pane/FileListView.swift` | grep: `TableColumn(`/커스텀 row 컬럼 정의에 "Attrs", "Description" 라벨 각 1건 |
| **G2** | 시간 셀이 `오전 10:25` 한국 로캘 AM/PM | `21:53` **24h** — `DateFormatter` 에 `dateFormat = "HH:mm"`, `locale = Locale(identifier: "en_US_POSIX")` (또는 `.dateTime.hour(.twoDigits(amPM: .omitted)).minute()` 시도 후 결과 확인) | `Features/Pane/PaneRow.swift` 또는 row 포맷 헬퍼 (현 위치 grep 으로 결정) | UI test: 임의 행 1개의 Time 셀이 정규식 `^[0-2]\d:[0-5]\d$` 매치, AM/PM 한글 단어 0건 |
| **G3** | 상태바 attrs 가 `___` (3자) | `____` `A___` `_R__` 등 정확 **4자** | `Features/Pane/PaneStatusBar.swift` + `Core/FileSystem/DirectoryEntry.swift` 의 `attrsFourCharacter` 보강 | 단위 test: 빈 attrs → `"____"`, R+H 조합 → `"_RH_"` 등 |
| **G4** | Name 셀 내용 좌측이 잘려 `lications`, `ktop`, `uments`… 처럼 보임 | 풀네임(`Applications`, `Desktop`, `Documents`) 그대로 표시. **`truncationMode(.tail)`** 또는 잘림 없음. 셀 컨테이너 padding/`frame` 음수 제거. 아이콘은 별도 컬럼(폭 22 고정)으로 분리되어 Name 영역을 침범하지 않게 | `Features/Pane/FileListView.swift`, `Features/Pane/PaneRow.swift` 의 row view | (a) grep: `truncationMode(.head)` 0건. (b) UI test: 좌측 패널 첫 폴더 행의 `staticTexts` 에 `"Applications"` (정확 일치) 존재 |
| **G5** | 볼륨 행이 일반 행과 동일하게 표시 — Ext에 `[드라이브]`, 다른 컬럼 비어 있음. capsule 없음 | 볼륨 행: `#` (rowNumber), 아이콘(`internaldrive.fill` 등), Name=`volume.name`, Ext=`[드라이브]`, Size=빈문자, Date/Time/Attrs 빈문자, **Description = `HStack { Capsule(60×6) · Text("\(humanFree) 남음").monospacedDigit() }`** | `Features/Pane/FileListView.swift` 의 row 분기, 새 `Features/Pane/VolumeRowDescription.swift` (작아서 inline 도 OK) | UI test: 좌측 패널 Table 마지막 N 행 중 적어도 1개의 Description 라벨이 `"남음"` 으로 끝남 |
| **G7** | 행 높이 ~28pt, 폰트 13pt — 정보 밀도 낮음 | 행 높이 **20pt** 고정. Name/Ext/Description 폰트 **`.system(size: 12)`**, 숫자·시간 컬럼 **`.system(size: 11).monospacedDigit()`**. 셀 수직 padding 0, 수평 padding 6. 헤더 폰트 `.system(size: 11)`, `Color(white: 0.5)` | `Features/Pane/FileListView.swift` row view, 컬럼 헤더 | grep: 행 컨테이너에 `frame(height: 20)` 또는 `.frame(minHeight: 20, maxHeight: 20)`. 파일 안에 `size: 13` 잔존 0건 |
| **G9** | cursor 행 배경이 `Color.yellow.opacity(0.25)` — 너무 흐림 | 활성 패널 cursor: `Color.yellow.opacity(0.45)` (= `FileColorToken.selectionActiveBackground` 상수 조정). 비활성: `Color.white.opacity(0.12)`. 토큰 자체를 수정(다른 호출자 영향 확인). | `DesignSystem/Tokens.swift` (`FileColorToken.selectionActiveBackground` / `selectionInactiveBackground`) | grep: 토큰 정의 값이 `opacity(0.45)` / `opacity(0.12)` 로 변경됨 |
| **G10** | 상태바 형식은 거의 OK 지만 attrs 자릿수 + 동일 흐름에 `|` 양옆 공백 점검 | `\n<bytesOrDash> | <yyyy-MM-dd HH:mm> | <attrs4> | <fullName>` — `|` 양옆 공백 정확히 1칸. attrs4 는 항상 4자 | `Features/Pane/PaneStatusBar.swift` | 단위 test (이미 0516-1732 에 정의됨, 그대로 사용): 파일 cursor 정규식 `^[\d,]+ \| \d{4}-\d{2}-\d{2} \d{2}:\d{2} \| [A_][R_][H_][S_] \| .+$` 매치 |

> **포함 안 함 (사용자 지시):**
> - G6 — Description 텍스트(`Markdown File` 등 kind 문자열). 본 계획에서 Description 컬럼은 **볼륨 행에만** 콘텐츠가 들어가고 일반 파일·폴더는 빈문자.
> - G11/G12 — 상단 TAB 바, 자체 메뉴 바.

---

## 자료/포맷 헬퍼 — 명세

### F1. 시간 24h 포맷 (G2)
```swift
private static let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "HH:mm"
    return f
}()
extension DirectoryEntry {
    var timeHHmm: String { Self.timeFormatter.string(from: modificationDate) }
}
```

### F2. attrs 4자 (G3)
```swift
extension DirectoryEntry {
    var attrsFourCharacter: String {
        // 순서 고정: A, R, H, S — 각 비어 있으면 '_'
        var out = ""
        out.append(isArchive ? "A" : "_")
        out.append(isReadOnly ? "R" : "_")
        out.append(isHidden ? "H" : "_")
        out.append(isSystem ? "S" : "_")
        return out
    }
}
```
(현재 `DirectoryEntry` 가 이 4 비트를 갖고 있는지 grep 후 없으면 단순화: `_` 로 채우고 read-only 만 `R` 로. 구현 단계에서 결정 후 본 절 갱신.)

### F3. Name 잘림 원인 후보 (G4) — 구현 단계에서 확인 순서
1. row view 의 Name `Text(...)` 에 `.truncationMode(.head)` 잔존 여부 — grep `truncationMode\(\.head\)` → 발견 시 `.tail` 로 교체.
2. row view 가 `HStack` 안에서 아이콘과 Name 을 같은 셀로 묶고 `frame(width: ...)` 가 잡혀 있는지 — 분리해 별도 컬럼으로.
3. `LazyVStack` row 컨테이너에 `padding(.leading, -N)` 같은 음수 padding 잔존 — 제거.
4. macOS 26 Tahoe / 15 Sequoia 모두에서 동일하게 잘리는지 확인(특정 OS 만이면 위 1~3 외 다른 원인).

### F4. 컬럼 폭 (G1 + G7)
| 컬럼 | 폭 | 정렬 |
|---|---|---|
| `#` | 32 고정 | trailing |
| icon | 22 고정 | center |
| `Name` | min 120, ideal 220, max .infinity | leading |
| `Ext` | 56 고정 | leading |
| `Size` | 80 고정 | trailing |
| `Date` | 90 고정 | leading |
| `Time` | 48 고정 | leading |
| `Attrs` | 48 고정 | leading |
| `Description` | min 100, max .infinity | leading |

---

## 비범위

- Description 컬럼 텍스트(파일 kind 문자열). 후속 계획에서.
- 상단 TAB 바, 메뉴 바. 별도 계획.
- 컬럼 너비 사용자 조정·드래그 정렬.
- 다중 선택 시 강조(별도 계획 `0516-1722-multi-selection.todo.md`).

---

## 통과 조건 — 측정 가능

### A. 빌드
- [ ] `xcodebuild -project MdirX.xcodeproj -scheme MdirX -destination 'platform=macOS' build` 0 error, 0 warning (`grep -ciE "warning:"` 결과 0).

### B. 소스 grep (구조 검증)
- [ ] `FileListView.swift` 안에 `"Attrs"` 와 `"Description"` 라벨 각 1건 이상.
- [ ] `FileListView.swift` 안에 `truncationMode(.head)` 0건.
- [ ] `FileListView.swift` 안에 row 컨테이너 `frame(...height: 20...)` 또는 동등한 고정 높이 1건 이상.
- [ ] `FileListView.swift` 안에 폰트 리터럴 `size: 13` 0건 (전부 11 또는 12로 통일됐는지). `size: 12` 와 `size: 11` 각 1건 이상.
- [ ] `Features/Pane/PaneStatusBar.swift` 안에 `attrsFourCharacter` 호출 1건 이상.
- [ ] `DesignSystem/Tokens.swift` 안에 `opacity(0.45)` 와 `opacity(0.12)` (또는 G9 합의된 최종 값) 각 1건 이상.
- [ ] 시간 포맷 코드: `DateFormatter` + `"HH:mm"` 1건 이상, `en_US_POSIX` 1건 이상.

### C. 단위 테스트 (`Tests/UnitTests/`)
- [ ] `AttrsFourCharacterTests.swift` — 빈 → `"____"`, R 만 → `"_R__"`, A+R+H+S → `"ARHS"`.
- [ ] `TimeHHmmFormatTests.swift` — 자정 `00:00`, 오후 9시 53분 `21:53`, 정오 `12:00`.
- [ ] `StatusBarFormatTests.swift` (직전 계획에서 정의 — 없으면 신규):
  - 파일 cursor (size 12345, attrs `A___`, name `foo.txt`, date 2026-05-13 21:53) → `"12,345 | 2026-05-13 21:53 | A___ | foo.txt"`.
  - 폴더 cursor → 첫 자리 `—`.
  - 볼륨 cursor → 첫 자리 `<free> / <total>`.
  - cursor 없음 → `"— | — | ____ | —"`.

### D. UI 테스트 (`Tests/UITests/NexusLookExactTests.swift`)
- [ ] 컬럼 헤더 텍스트가 정확히 다음 순서: `#`, (빈/icon), `Name`, `Ext`, `Size`, `Date`, `Time`, `Attrs`, `Description`.
- [ ] 좌측 패널 첫 폴더 행의 라벨 컬렉션에 `"Applications"` (잘리지 않은 풀네임) 존재.
- [ ] 시간 셀 임의 1개가 정규식 `^[0-2]\d:[0-5]\d$` 매치, `"오전"`/`"오후"` 단어 0건.
- [ ] 좌측 패널 Table 마지막 N 행 중 Description 라벨이 `"남음"` 으로 끝나는 행 1개 이상 (마운트 볼륨 인라인 표시).
- [ ] (가능하면) 임의 행 클릭 후 상태바 텍스트가 정규식 `^([\d,]+|—) \| \d{4}-\d{2}-\d{2} \d{2}:\d{2} \| [A_][R_][H_][S_] \| .+$` 매치.

### E. 시각 (수동) 비교
**구현 완료 시 다음 캡처 1장 첨부**: 두 패널 모두 표시, 좌측 패널이 활성 상태.

캡처 위에서 사용자가 체크:
- [ ] Nexus 캡처들과 **행 밀도** 비교 시 ±2px 이내 (행 높이 약 20pt).
- [ ] 컬럼 9개가 머리부터 끝까지 보임.
- [ ] Name 셀이 좌측 잘림 없이 풀네임으로 표시.
- [ ] 시간 셀이 `21:53` 형식 (한글 AM/PM 미사용).
- [ ] 볼륨 행 Description 에 capsule bar + `〈X GB〉 남음` 텍스트.
- [ ] 활성 패널 cursor 행 배경이 Nexus 캡처와 비슷한 진하기로 보임 (이전보다 명확히 진함).
- [ ] 상태바 attrs 가 4자.

### F. 사용자 OK
- [ ] A~E 통과 후 본 문서·파일명을 `done` 으로.

---

## 구현 체크리스트

- [ ] `DirectoryEntry.attrsFourCharacter` 보강 (없으면 신규)
- [ ] `DirectoryEntry.timeHHmm` 또는 동등한 24h 포맷 헬퍼
- [ ] `Features/Pane/FileListView.swift`:
  - [ ] 컬럼 9개 정의 (위 §F4 폭/정렬/폰트/색 적용)
  - [ ] 행 컨테이너 높이 20pt 고정, 폰트 통일
  - [ ] Name 셀 `truncationMode(.tail)`, 아이콘과 분리
  - [ ] 볼륨 분기 Description 에 capsule + `남음` HStack
- [ ] `Features/Pane/PaneStatusBar.swift`: attrs4 호출, `|` 양옆 공백 정렬
- [ ] `DesignSystem/Tokens.swift`: cursor 배경 불투명도 조정
- [ ] `Tests/UnitTests/AttrsFourCharacterTests.swift` 신규
- [ ] `Tests/UnitTests/TimeHHmmFormatTests.swift` 신규
- [ ] `Tests/UnitTests/StatusBarFormatTests.swift` (없으면 신규)
- [ ] `Tests/UITests/NexusLookExactTests.swift` 신규
- [ ] `MdirX.xcodeproj` 신규 소스 반영 (`python3 scripts/gen_xcode_pbx.py`)
- [ ] 캡처 1장 첨부 (E 항목용) — `.plan/MdirX After.png` 로 같은 경로에 저장
- [ ] `.plan/STATUS.md` 행 추가/갱신
- [ ] 커밋: `fix(pane): nexus look exact (9 cols, 24h time, attrs4, volume capsule)`

---

## 3회 실패 가드

본 계획의 통과 조건 중 **B (소스 grep) 또는 D (UI 테스트)** 가 같은 항목으로 **3회** 실패하면 즉시 중단하고 사용자에게:
① 어떤 통과 조건이 어떤 에러로 실패했는지(스택/로그 인용),
② 3회 각각의 시도 차이,
③ 남은 가설 2~3개 (예: SwiftUI Table vs 커스텀 LazyVStack, macOS 버전별 텍스트 렌더링 차이),
④ 처분 요청 (가설 선택 / 범위 축소 / 통과 조건 재정의).

---

**상태:** `done` (2026-05-16 20:12) — Nexus 룩앤필 정밀 일치(재시도). G1·G2·G3·G4·G5·G7·G9·G10 8개 항목 모두 구현·캡처 비교 완료. 남은 차이(G6 Description kind 텍스트, G11 탭 바, G12 자체 메뉴 바)는 본 계획 비범위로 별도 계획 필요.
