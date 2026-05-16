# `.gitignore` 의 `*.xcodeproj` 라인은 Xcode 프로젝트 도입 전에 제거

## 상황 / 의도

기획 단계에서 받아쓴 초기 `.gitignore` 에 `*.xcodeproj` 가 들어 있었다. M1 스캐폴딩에서 `MdirX.xcodeproj` 를 만들었더니 통째로 무시되어 `git status` 에 표시되지 않음.

## 잘못된 접근

"Untracked 가 안 뜨는 건 권한 문제 아닌가" 식으로 디렉터리·소유권을 먼저 의심.

## 올바른 해결

`git check-ignore -v MdirX.xcodeproj` 한 줄이면 즉시 원인이 드러난다. SwiftPM-only 저장소를 가정한 일부 템플릿이 `*.xcodeproj` 를 ignore 에 포함시켜 두는데, Xcode 네이티브 프로젝트(`.xcodeproj`)를 쓰는 저장소에서는 이 라인을 **반드시 제거**해야 한다.

대신 추적에서 빼야 하는 것은:
- `xcuserdata/`
- `*.xcuserstate`
- `DerivedData/`
- (선택) `*.xcworkspace/xcuserdata/`

→ `.xcodeproj` 자체는 추적, 그 내부의 사용자별 상태만 ignore 가 원칙.

## 참고

- 커밋 `49f908b` 의 `.gitignore` diff: `-*.xcodeproj`
- `git check-ignore -v <path>` 로 어느 규칙이 잡는지 한 번에 확인
