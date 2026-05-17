# 파일리스트 컬럼 UI

파일 목록 행의 컬럼 구성·정렬·간격·행 유형별 표시 규칙을 정의한다.
구현·리팩터 시 이 규칙이 훼손되지 않도록 유의한다.

---

## 컬럼 구성

- **▶·아이콘·이름** 좌측 그룹: `HStack(spacing: 8)` — `.layoutPriority(1)` 적용, 창이 좁아질 때 우측 컬럼보다 먼저 공간 확보
- **이름↔우측 그룹** 사이: 기본 `HStack(spacing: 12)`, 좁은 패널에서는 `8pt`
- 우측 그룹 내부(ext·size·date·time·attrs·description): 기본 `HStack(spacing: 12)`, 좁은 패널에서는 `8pt`

| | ▶ (6pt) | 아이콘 (14pt) | 이름 (동적) | ext (36pt) | size (52pt) | date (70pt) | time (32pt) | attrs (30pt) | description (동적) |
|---|---|---|---|---|---|---|---|---|---|
| **정렬** | 가운데 | 가운데 | 왼쪽 | 왼쪽 | 오른쪽 | 왼쪽 | 왼쪽 | 왼쪽 | 왼쪽 |
| **간격** | 8pt→ | 8pt→ | 12pt/8pt→ | 12pt/8pt→ | 12pt/8pt→ | 12pt/8pt→ | 12pt/8pt→ | 12pt/8pt→ | |
| **`..` (부모)** | — | `arrow.turn.left.up` | `..` | *(빈 칸)* | *(빈 칸)* | *(빈 칸)* | *(빈 칸)* | *(빈 칸)* | *(빈 칸)* |
| **폴더** | 선택 시 ▶ | `folder.fill` | displayName | *(빈 칸)* | `[폴더]` dim | 상대·달력 날짜 | `HH:mm` | `rwxr` 등 | kindDescription |
| **일반 파일** | 선택 시 ▶ | 확장자별 아이콘 | displayName | 확장자 문자열 | `533 B` / `1.5 KB` / `2.1 MB` | 상대·달력 날짜 | `HH:mm` | `rwxr` 등 | kindDescription |
| **볼륨** | — | 드라이브 종류별 | volume.name | 사용량 바차트 | ← `12.4 GB 남음` (size+date+time+attrs 합산) →→→ | | | *(빈 칸)* |

### 이름·description 컬럼 동적 폭 계산

- `preferredNameWidth` = 현재 패널의 모든 행 `displayName` / `volume.name` 을 `NSFont.systemFont(ofSize: 12)` 기준으로 측정한 최대값 + 20pt 여백. 단, 최소 90pt.
- `forFlexible` = 전체 폭 − 좌측 패딩(6pt) − 우측 패딩(18pt, 스크롤바 클리어런스) − 현재 표시 중인 고정 컬럼 합계 − 현재 간격 합계.
- `dateWidth` = **70pt** 고정 (`"yyyy-MM-dd"` 실측 67pt + 3pt 여백 기준).
- **날짜 표기 규칙** (`relativeOrCalendarDate`): 오늘 → `오늘`, 1일 전 → `어제`, 2~10일 전 → `N일 전`, 11일 이상 → `yyyy-MM-dd`. 폴더·파일 동일 적용.
- `nameWidth = max(90, min(preferredNameWidth, forFlexible))` — 기본적으로 가장 긴 이름 뒤에 ext부터 붙고, 이름이 너무 길 때만 가능한 폭까지 확장한 뒤 tail truncate.
  - 측정값 기반 폭은 SwiftUI Text 렌더 여유분으로 20pt를 더한다. 마지막 1~2글자가 잘리면 이 padding을 먼저 조정한다.
  - `.frame(maxWidth: .infinity)` 방식은 HStack 분배 시 이름 컬럼이 0pt로 압축되는 결함이 있어 사용 안 함.
- `descriptionWidth = max(0, forFlexible − nameWidth − 현재 spacing)`. 48pt 미만이면 description 컬럼은 숨겨 불필요한 간격을 만들지 않는다.
- ext/size/time/attrs 폭은 좁은 패널에서 이름 공간을 확보하기 위해 축소됨 (52→36, 56→52, 36→32, 36→30).
- 좁은 패널에서 이름 컬럼을 우선한다. `preferredNameWidth`가 확보되면 5개 우측 컬럼을 모두 보이고, 부족하면 순서대로 다음 밀도 조정을 적용한다.
  1. 이름↔우측 그룹 및 우측 그룹 내부 간격을 12pt에서 8pt로 축소.
  2. 그래도 부족하면 attrs 컬럼을 숨김.
  3. 그래도 부족하면 ext 컬럼도 숨김.
- header와 row는 동일한 `FileListLayout`의 `showsExt` / `showsAttrs` / `showsDescription` / spacing 값을 사용한다. 따라서 표시되는 컬럼의 좌표는 모든 행에서 동일하게 유지된다.

### 비고

- `..` (부모) 와 볼륨은 selection 불가 — ▶ 마커 없음.
- 볼륨의 사용량 바차트(`VolumeUsageBar`)는 부모 컬럼 폭(52pt)을 상속받아 렌더링. 고정 폭 사용 금지.
- 볼륨의 사용량 바차트는 ext 컬럼이 표시될 때 ext 컬럼에, ext 컬럼이 숨겨진 초협폭 모드에서는 size 컬럼에 표시한다.
- 볼륨의 여유 공간 텍스트는 사용량 바차트 뒤에 남은 표시 컬럼을 합산한 프레임으로 표시한다.
- description 컬럼은 남는 공간 흡수용이다. 이름과 ext 사이를 벌리는 데 쓰면 안 된다.

---

## 사이즈 표기법

숫자와 단위 사이 **스페이스 1칸**, 1000 진수 기준.

| 범위 | 형식 | 예시 |
|------|------|------|
| 1 KB 미만 | `N B` | `533 B` |
| 1 KB ~ 10 KB | `N.N KB` | `1.5 KB` |
| 10 KB ~ 1 MB | `N KB` | `84 KB` |
| 1 MB ~ 10 MB | `N.N MB` | `2.1 MB` |
| 10 MB ~ 1 GB | `N MB` | `340 MB` |
| 1 GB ~ 10 GB | `N.N GB` | `4.7 GB` |
| 10 GB 이상 | `N GB` | `128 GB` |
| TB급 동일 적용 | `N.N TB` / `N TB` | `1.2 TB` |

구현 위치: `FileListRow.formatBytes(_:)` (static, `FileListView.swift`).
