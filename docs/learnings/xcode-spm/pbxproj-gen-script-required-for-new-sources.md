# 신규 Swift 소스는 `scripts/gen_xcode_pbx.py` 재실행 필수

## 상황 / 의도

`Features/Pane/*.swift`, `DesignSystem/Tokens.swift` 등 신규 소스 파일을 추가한 뒤 `xcodebuild build` 실행. 동일 모듈 안의 타입이 분명히 존재하는데도 컴파일러가 `cannot find 'PaneHeaderView' in scope`, `cannot find 'FileColorToken' in scope` 같이 보고했다.

## 잘못된 접근

- 타입 정의 파일을 다시 열어 `struct`/`enum` 선언이 누락됐는지 의심.
- import 누락·접근 제어자 차이·동일 모듈 분리 단위 의심.
- `let layout = FileListLayout.available(...)` 같은 사용처를 수정해서 회피하려 함.

## 올바른 해결

- 네이티브 Xcode 프로젝트는 `*.swift` 파일이 디스크에 존재해도 `MdirX.xcodeproj/project.pbxproj` 의 `PBXFileReference`/`PBXBuildFile`/Sources phase 에 등록되지 않으면 **컴파일 대상에서 빠진다**. 그래서 다른 파일에서는 `cannot find ... in scope`로 보인다 — 파일 자체가 빠졌다는 단서가 컴파일 메시지에 없다.
- 본 저장소는 `scripts/gen_xcode_pbx.py` 가 디스크의 파일을 스캔해 `project.pbxproj` 를 재생성한다. **소스 추가/이동/삭제 직후** 반드시 한 번 실행한다:
  ```bash
  python3 scripts/gen_xcode_pbx.py
  ```
- 빌드 에러가 "타입 못 찾음" 으로 보이면 먼저 `grep "<TypeName>" MdirX.xcodeproj/project.pbxproj` 로 등록 여부부터 확인한다.

## 참고

- 빌드 에러 메시지 자체가 미등록 사실을 숨기기 때문에 학습 가치가 큰 함정.
- `.plan/0516-1855-nexus-look-exact.done.md` 진행 중 30분 손실 → 한 번 겪으면 다음 추가 사이클에서 자동 반사로 굳히기 위해 기록.
