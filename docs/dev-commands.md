# 개발·검증 표준 명령

작업 후 보고에 `xcodebuild` 결과를 인용할 때는 **여기 적힌 형태를 그대로 사용한다.**
단축형으로 줄여 적으면 다음 작업자가 동일 명령으로 재현하지 못한다 (이미 [learnings/xcode-spm/test-host-deriveddata-mismatch-with-custom-build-dir.md](learnings/xcode-spm/test-host-deriveddata-mismatch-with-custom-build-dir.md)에 기록된 함정).

## 빌드

```bash
xcodebuild build \
  -scheme MdirX \
  -destination 'platform=macOS' \
  -derivedDataPath dist \
  -quiet
```

빌드 산출물은 `dist/` 아래로 배치된다. 이 디렉터리는 단위 테스트의 `TEST_HOST`로도 사용된다.

## 단위 테스트 (MdirXTests만)

```bash
xcodebuild test \
  -scheme MdirX \
  -destination 'platform=macOS' \
  -derivedDataPath .build/derived \
  CONFIGURATION_BUILD_DIR=$(pwd)/dist \
  -only-testing:MdirXTests
```

- `-derivedDataPath`만 주고 `CONFIGURATION_BUILD_DIR`을 빼면 `@testable import MdirX` 단계에서 모듈 해석 실패. 두 인자를 항상 함께 줄 것.
- `-only-testing:MdirXTests` 없이 돌리면 UI test runner도 함께 실행되어 환경에 따라 hang 가능.

## 앱 재실행

빌드 성공 후:

```bash
killall MdirX 2>/dev/null; sleep 0.5; open dist/MdirX.app
```

CLAUDE.md 프로젝트 규칙: `xcodebuild build` 성공 시 자동 재실행.

## pbxproj 재생성

새 Swift 파일을 추가했을 때:

```bash
python3 scripts/gen_xcode_pbx.py
```

`App/`, `Core/`, `Features/`, `DesignSystem/`, `Tests/{Unit,UI}Tests/` 하위 `*.swift`를 walk해 자동 등록. 리소스 4건(Assets/entitlements/en+ko Localizable)만 하드코딩.

## 커밋 메시지에 검증 결과를 적을 때

다음 형식 유지:

```
검증
- xcodebuild build ✓
- xcodebuild test (CONFIGURATION_BUILD_DIR=$(pwd)/dist) → N passed / 0 failed
```

전체 명령을 인용하면 본문이 길어지므로 본 문서를 참고로 짧게 적어도 OK — 단, "테스트 통과" 같은 모호한 표현은 금지. 통과한 명령 형태와 케이스 수를 명확히 한다.
