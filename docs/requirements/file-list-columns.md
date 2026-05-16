# 파일리스트 컬럼 UI

파일 목록 행의 컬럼 구성·정렬·간격·행 유형별 표시 규칙을 정의한다.
구현·리팩터 시 이 규칙이 훼손되지 않도록 유의한다.

---

## 컬럼 구성

- **▶·아이콘·이름** 좌측 그룹: `HStack(spacing: 8)`
- **이름↔ext** 및 **ext~description** 우측 그룹 사이: `HStack(spacing: 12)`
- 우측 그룹 내부(ext·size·date·time·attrs·desc): `HStack(spacing: 12)`

| | ▶ (12pt) | 아이콘 (14pt) | 이름 (동적) | ext (52pt) | size (56pt) | date (70pt) | time (36pt) | attrs (36pt) | description (동적) |
|---|---|---|---|---|---|---|---|---|---|
| **정렬** | 가운데 | 가운데 | 왼쪽 | 왼쪽 | 오른쪽 | 왼쪽 | 왼쪽 | 왼쪽 | 왼쪽 |
| **간격** | 8pt→ | 8pt→ | 8pt→ | 8pt→ | 8pt→ | 8pt→ | 8pt→ | 8pt→ | |
| **`..` (부모)** | — | `arrow.turn.left.up` | `..` | *(빈 칸)* | *(빈 칸)* | *(빈 칸)* | *(빈 칸)* | *(빈 칸)* | *(빈 칸)* |
| **폴더** | 선택 시 ▶ | `folder.fill` | displayName | *(빈 칸)* | `[폴더]` dim | 상대·달력 날짜 | `HH:mm` | `rwxr` 등 | *(빈 칸)* |
| **일반 파일** | 선택 시 ▶ | 확장자별 아이콘 | displayName | 확장자 문자열 | `533 B` / `1.5 KB` / `2.1 MB` | 상대·달력 날짜 | `HH:mm` | `rwxr` 등 | *(빈 칸)* |
| **볼륨** | — | 드라이브 종류별 | volume.name | 사용량 바차트 | ← `12.4 GB 남음` (size+date+time+attrs 합산 222pt) →→→ | | | *(빈 칸)* |

### 이름·description 동적 폭 계산

- 가용 폭(`forFlexible`) = 전체 폭 − 외부 패딩 − 고정 컬럼 합계(276pt) − 간격(64pt)
- 실제 이름 폭: 현재 패널의 모든 행 `displayName` / `volume.name` 을 `NSFont.systemFont(ofSize: 12)` 기준으로 측정 → 최대값 + 12pt 여백
- `dateWidth` = **70pt** 고정 (`"yyyy-MM-dd"` 실측 67pt + 3pt 여백 기준).
- **날짜 표기 규칙** (`relativeOrCalendarDate`): 오늘 → `오늘`, 1~10일 전 → `N일 전`, 11일 이상 → `yyyy-MM-dd`. 폴더·파일 동일 적용.
- `nameWidth = max(90, min(실측 최대값 + 12, forFlexible × 0.75))`
- `descriptionWidth = max(0, forFlexible − nameWidth)`
- 이름이 짧은 디렉터리에서는 description 컬럼이 넓어진다. 반대로 이름이 길면 최대 75% 까지만 늘어난다.

### 비고

- `..` (부모) 와 볼륨은 selection 불가 — ▶ 마커 없음.
- 볼륨의 사용량 바차트(`VolumeUsageBar`)는 부모 컬럼 폭(52pt)을 상속받아 렌더링. 고정 폭 사용 금지.
- 볼륨의 size~attrs 4개 컬럼은 하나의 프레임(56+8+70+8+36+8+36 = **222pt**)으로 합산해 여유 공간 텍스트를 표시.

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
