# CONFIGURATION_BUILD_DIR 커스텀 시 TEST_HOST DerivedData 불일치

## 상황 / 의도

`xcodebuild build` 에서 `CONFIGURATION_BUILD_DIR=dist` 를 지정해 `dist/MdirX.app` 에 빌드한다. 이어서 `xcodebuild test -scheme MdirX -only-testing:MdirXTests` 를 실행하면 단위 테스트가 **이전 빌드 아티팩트(stale)** 에 연결되어 실행되거나, `TEST_HOST` 가 DerivedData 기본 경로를 가리켜 **아예 다른 바이너리를 로드**한다.

## 잘못된 접근

테스트 단계에서만 `CONFIGURATION_BUILD_DIR` 를 지정하거나, build 와 test 단계의 `-derivedDataPath` 를 다르게 두면 두 아티팩트가 달라져 같은 문제가 반복된다.

## 올바른 해결

build 와 test 를 **같은 `-derivedDataPath` + `CONFIGURATION_BUILD_DIR`** 로 묶는다.

```bash
# 1. 빌드
xcodebuild build \
  -scheme MdirX \
  -configuration Debug \
  -derivedDataPath .build/derived \
  CONFIGURATION_BUILD_DIR=$(pwd)/dist

# 2. 단위 테스트 (같은 derivedDataPath + CONFIGURATION_BUILD_DIR)
xcodebuild test \
  -scheme MdirX \
  -only-testing:MdirXTests \
  -derivedDataPath .build/derived \
  CONFIGURATION_BUILD_DIR=$(pwd)/dist
```

두 호출이 동일한 `derivedDataPath` 를 공유하면 TEST_HOST 가 dist 빌드를 일관되게 참조한다.

## 참고

- 커밋: `feat(pane): rename / new folder / new file (F2 / ⌥K / ⌃N)`
- 관련: `xcodebuild test` 의 `TEST_HOST` 는 `CONFIGURATION_BUILD_DIR` 경로 기반으로 결정됨
