# 빈 `xcshareddata/` · `project.xcworkspace/` 는 git 추적 안 됨 — share scheme 누락 함정

## 상황 / 의도

`MdirX.xcodeproj` 를 수동/스크립트로 생성한 뒤 `git add MdirX.xcodeproj` 했더니 `project.pbxproj` 만 스테이지되고 같이 만든 `xcshareddata/` 와 `project.xcworkspace/` 는 빠졌다. `.gitignore` 에 잡힌 것도 아닌데 빠짐.

## 잘못된 접근

"`.gitignore` 가 잘못된 것 아닌가" 의심 → `git check-ignore` 로 확인했으나 무시되지 않음.

## 올바른 해결

git 은 **빈 디렉터리를 추적하지 않는다.** 두 디렉터리 모두 내용물이 없으면 add 대상이 아니다. 다음 시점에 자동으로 채워지므로 그때 함께 커밋:

- `xcshareddata/xcschemes/MdirX.xcscheme` — Xcode 에서 스킴을 **Manage Schemes → Shared** 체크하면 생성. 이게 없으면 다른 머신 / CI 에서 "MdirX 스킴이 안 보임" 으로 빌드 불가.
- `project.xcworkspace/contents.xcworkspacedata` — Xcode 가 워크스페이스 메타데이터를 처음 저장할 때.

→ 후속 작업(M3 명령 팔레트, CI 도입)에서 다른 머신/CI 빌드가 깨지면 가장 먼저 share scheme 누락을 의심한다.

## 참고

- 커밋 `49f908b`
- `xcodebuild -list` 출력에 `MdirX` 스킴이 나오는지로 한 줄 진단
