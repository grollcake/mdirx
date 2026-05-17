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
