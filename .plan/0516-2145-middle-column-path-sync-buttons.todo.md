# 중간 컬럼 경로 동기화 버튼

## 사용자 요구 (정제)

- **원문:** "최상단 액션 아이콘 2개 넣자. 경로 동기화 버튼이야. --> : 좌측 팬의 경로를 오른쪽 팬의 경로에 반영 / <-- : 오른쪽 팬의 경로를 좌측 팬의 경로에 반영"
- **정제:** 두 패널 사이 중간 컬럼 최상단에 경로 동기화 버튼 2개를 세로로 배치한다.
  - `→` : 좌→우 (왼쪽 패널 currentURL을 오른쪽 패널에 navigate)
  - `←` : 우→좌 (오른쪽 패널 currentURL을 왼쪽 패널에 navigate)

## 개요

`DualPaneView.swift`의 중간 컬럼 `Rectangle`을 `VStack` 컨테이너로 교체하고, 상단에 버튼 2개를 배치한다. `BrowserSession`에 경로 동기화 메서드 2개를 추가한다.

## 요구사항

- 버튼은 중간 컬럼 최상단에 세로로 2개 배치
- 버튼 아이콘: SF Symbols `arrow.right` / `arrow.left`
- 버튼 크기: 컬럼 폭(20pt)에 맞게, 탭 가능 영역 충분히
- 버튼 색상: 비활성 상태는 `Color.white.opacity(0.5)`, 호버/클릭 시 `.white`
- 배경: 기존 `Color.white.opacity(0.08)` 유지
- 나머지 영역(버튼 아래)은 빈 공간

## 수도 코드

```
// BrowserSession.swift 에 추가:
func syncLeftToRight(via fs: FileSystemActor) async {
    right.currentURL = left.currentURL
    await right.load(via: fs)
}
func syncRightToLeft(via fs: FileSystemActor) async {
    left.currentURL = right.currentURL
    await left.load(via: fs)
}

// DualPaneView.swift 중간 컬럼 교체:
ZStack {
    Rectangle().fill(Color.white.opacity(0.08))
    VStack(spacing: 4) {
        Button { Task { await session.syncLeftToRight(via: session.fs) } } label: {
            Image(systemName: "arrow.right")
        }
        Button { Task { await session.syncRightToLeft(via: session.fs) } } label: {
            Image(systemName: "arrow.left")
        }
        Spacer()
    }
    .padding(.top, 6)
}
.frame(width: 20)
```

## 아키텍처

- **수정 파일**
  - `Features/DualPane/BrowserSession.swift` — `syncLeftToRight` / `syncRightToLeft` 추가
  - `Features/DualPane/DualPaneView.swift` — 중간 컬럼 Rectangle → ZStack+버튼

## 통과 조건

- [ ] 빌드 0 error / 0 warning
- [ ] `→` 버튼 클릭 시 오른쪽 패널이 왼쪽 패널과 같은 경로로 이동
- [ ] `←` 버튼 클릭 시 왼쪽 패널이 오른쪽 패널과 같은 경로로 이동
- [ ] 버튼 탭 후 키보드 포커스 유지 (DualPaneView의 키 핸들링 깨지지 않음)
- [ ] 기존 테스트 전부 통과

## 구현 체크리스트

- [ ] `BrowserSession` sync 메서드 2개 추가
- [ ] `DualPaneView` 중간 컬럼 교체
- [ ] 빌드·앱 재실행·수동 확인
- [ ] STATUS.md 갱신

---

**상태:** `todo`
