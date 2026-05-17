# DONE

> 완료된 작업만 요약. 상세는 Git·`.plan/*.done.md`·[`docs/learnings/`](docs/learnings/).  
> **기록은 `- [x]` 형식만 사용한다.**

---

## 주소 popover 키보드 탐색 포커스·스크롤 수정

**완료 일시**: 2026-05-17 22:12:44

- [x] **키 포커스 복구**: TextField에서 히스토리 리스트로 내려간 뒤 리스트 컨테이너가 실제 키보드 focus를 받아 `↑`/`↓` 반복 입력이 system beep 없이 계속 동작.
- [x] **스크롤 동기화**: highlight index 변경 시 `ScrollViewReader.scrollTo`로 선택 행이 보이는 영역을 따라가도록 수정.
- [x] **회귀 기록**: 기존 구현의 잘못된 가정(highlight 상태만으로 focus/scroll이 따라온다는 가정)을 learnings에 기록.

---

## 파일리스트 컬럼 폭 자동 조정

**완료 일시**: 2026-05-17 22:00:59

- [x] **이름 실측 폭 적용**: 현재 rows 최대 이름 폭까지만 이름 컬럼을 잡아 ext/size/date/time/attrs 가 이름 뒤에 붙도록 조정.
- [x] **description 잔여폭 복구**: 남는 공간은 description 컬럼이 흡수하고, 좁은 패널에서는 spacing 축소·attrs/ext 숨김으로 이름 가시성을 우선.
- [x] **요건·learnings 갱신**: 파일리스트 컬럼 요구사항과 SwiftUI custom row 레이아웃 학습 기록 추가.

---

- [x] 라이선스 **MIT** 확정 (`PLAN.md` §0·§10, 루트 README 반영)
- [x] 로컬 작업 디렉터리 **`mdirx`** 로 정리 (`PLAN.md` §0)
- [x] **Xcode 16** 설치·사용 가능 확인
- [x] **듀얼 패널 셸** — 좌우 분할·Tab 활성 토글·홈 경로 헤더 ([`.plan/0516-1642-dualpane-shell.done.md`](.plan/0516-1642-dualpane-shell.done.md))
