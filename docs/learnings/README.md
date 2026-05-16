# 학습·실수 기록 (`docs/learnings`)

작업 중 겪은 **실수·오해**와 **올바른 해결**만 짧게 남긴다. `.plan/` 의 “하기 전 계획”과 구분한다.

## 완료 승인과 함께

작업 **완료에 대한 사용자 OK** 이후, 에이전트는 **learnings 후보**(새로 배운 것·헤매다 해결한 것·같은 식으로 반복될 수 있는 것)를 사용자에게 **제안**한다. **사용자가 추가를 승인한 항목만** 여기에 문서로 반영한다. 승인 없이 저장소에 쓰지 않는다. 절차·역할은 [`AGENTS.md`](../../AGENTS.md) 와 [`.plan/README.md`](../../.plan/README.md) 의 `done` 조건을 본다.

## 영역

| 디렉터리 | 용도 |
|----------|------|
| [swift/](swift/) | 언어·동시성·표준 라이브러리 |
| [swiftui/](swiftui/) | SwiftUI 뷰·상태·macOS 특이점 |
| [xcode-spm/](xcode-spm/) | Xcode, SPM, 빌드 설정 |
| [git-ci/](git-ci/) | Git, CI, 훅 |
| [macos-sandbox/](macos-sandbox/) | 샌드박스·권한·보안 스코프(필요 시) |

필요하면 디렉터리를 더 둔다.

## 파일명

- `{영역}-{짧은주제}.md` 또는 `YYYY-MM-DD-{주제}.md`
- **한 파일 = 한 주제** (실수 하나 + 해결)

## 본문 최소 뼈대

```markdown
# 제목

## 상황 / 의도
## 잘못된 접근 (선택)
## 올바른 해결
## 참고 (커밋·링크, 선택)
```

새 문서를 추가하면 아래 **목록**에 한 줄만 적는다.

## 목록

- [xcode-spm/swift6-strict-concurrency-default.md](xcode-spm/swift6-strict-concurrency-default.md) — Swift 6 + strict concurrency 를 초기부터 켜도 SwiftUI placeholder 는 추가 표기 없이 무경고
- [xcode-spm/xcodeproj-empty-subdirs-not-tracked.md](xcode-spm/xcodeproj-empty-subdirs-not-tracked.md) — 빈 `xcshareddata/`·`project.xcworkspace/` 미추적 → share scheme 누락으로 다른 머신 빌드 깨질 수 있음
- [macos-sandbox/hardened-runtime-adhoc-sign-note.md](macos-sandbox/hardened-runtime-adhoc-sign-note.md) — `Disabling hardened runtime with ad-hoc codesigning` note 는 정상, Hardened Runtime ON 통과 조건 위반 아님
- [git-ci/gitignore-xcodeproj-pitfall.md](git-ci/gitignore-xcodeproj-pitfall.md) — `.gitignore` 의 `*.xcodeproj` 는 네이티브 Xcode 프로젝트 저장소에서 반드시 제거
