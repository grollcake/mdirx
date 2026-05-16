# DerivedData test bundle 오염 시 CodeSign 단계 실패

## 상황 / 의도

`xcodebuild -project MdirX.xcodeproj -scheme MdirX -destination 'platform=macOS' build` 실행. 모든 Swift 파일 컴파일은 성공한 뒤 마지막 CodeSign 단계에서만 실패:

```
/.../Build/Products/Debug/MdirX.app: bundle format unrecognized, invalid, or unsuitable
In subcomponent: /.../MdirX.app/Contents/PlugIns/MdirXTests.xctest
Command CodeSign failed with a nonzero exit code
```

`build` 만 했는데도 test bundle (`*.xctest`) 가 `PlugIns/` 아래로 들어가고, 그 번들이 깨져 있어 전체 서명 실패.

## 잘못된 접근

- 컴파일 에러를 다시 찾으려고 `grep "error:"` 반복. 사실 컴파일은 정상이라 결과 0건.
- entitlements/Info.plist 의심.

## 올바른 해결

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/MdirX-*
xcodebuild -project MdirX.xcodeproj -scheme MdirX -destination 'platform=macOS' build
```

오염은 보통 다음 시퀀스에서 생긴다:

1. 이전 `xcodebuild test` 시도 도중 컴파일·링크 에러로 중단.
2. 다음 `build` 가 같은 DerivedData 를 재사용 → 깨진 `MdirXTests.xctest` 가 그대로 남아 있음.
3. macOS 의 ad-hoc CodeSign 은 의존 번들까지 전부 검증하므로 거기서 멈춤.

따라서 다음 두 경우엔 의심 없이 DerivedData 부터 지운다:

- "build 자체는 다 됐는데 CodeSign 만 실패"
- 에러 메시지에 `In subcomponent: ...xctest` 가 들어 있음

## 참고

- 같은 함정: `xcodebuild test` 가 컴파일 에러로 중단된 뒤 곧바로 `xcodebuild build` 를 돌리면 같은 메시지를 다시 본다.
- `clean` 만으로는 부족할 때가 있다 (Xcode 의 incremental cache 가 별도 위치) — 위 `rm -rf` 가 가장 확실.
