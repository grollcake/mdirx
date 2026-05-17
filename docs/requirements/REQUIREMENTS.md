# 중요 요건 (Requirements)

이 디렉터리에는 프로젝트 전체 생명주기 동안 유지되어야 하는 **핵심 요건**을 정의한다.
구현·리팩터·버그 수정 등 어떤 작업을 하더라도 아래 요건이 훼손되지 않도록 유의한다.

---

## 요건 목록

| 파일 | 기능 | 핵심 요약 |
|------|------|-----------|
| [select-all-toggle.md](select-all-toggle.md) | 전체 선택 토글 (alt+u) | 3단계 순환(파일→파일+폴더→해제), 드라이브 항목 항상 제외 |
| [file-list-columns.md](file-list-columns.md) | 파일리스트 컬럼 UI | 행 유형별 컬럼 구성·정렬·간격, 사이즈 표기법(533 B / 1.5 KB …) |
| [shortcuts.md](shortcuts.md) | 단축키 IME-불변 | modifier+문자 단축키는 한글 IME에서도 동작 — `KoreanShortcutNormalizer`로 정규화 후 비교 |
| [dual-pane-activation.md](dual-pane-activation.md) | 듀얼 패널 활성/포커스 | Tab 토글, 단일 클릭 활성, 더블클릭 항목 유형별 라우팅, F5/F6 source/target |
| [file-ops-preflight.md](file-ops-preflight.md) | 파일 작업 안전성 | copy/move preflight 충돌, 부모/볼륨 제외, 자동 덮어쓰기 금지 |
| [address-bar-history.md](address-bar-history.md) | 주소창·경로 히스토리 | 절대경로·tilde 검증, frequent(top5 알파벳)·recent split, 패널별 20개 prune |
| [pane-rows-composition.md](pane-rows-composition.md) | 패널 행 구성 | parent link row 0, volumeIDs URL 집합 dedup, 순차 행 번호 |
| [name-edit-modal.md](name-edit-modal.md) | 이름 편집 모달 | F2/⌥K/⌃N sheet, 인라인 검증, IME 비차단, rename selection 정합성 |
| [breadcrumb-interaction.md](breadcrumb-interaction.md) | Breadcrumb 상호작용 | 세그먼트 클릭 이동, 더블클릭/⌘L 주소 모드, 마운트 볼륨 루트 라벨, history 버튼 양쪽 모드 |
