# File list 이름 폭은 남는 폭이 아니라 현재 rows 최대 이름 폭으로 잡는다

## 상황 / 의도

SwiftUI custom file list 에서 header 와 모든 row 의 컬럼 정렬을 유지하면서, 좁은 패널에서도 긴 파일·폴더 이름이 가능한 한 보이게 해야 했다.

## 잘못된 접근

처음에는 패널 폭에서 고정 컬럼과 간격을 뺀 나머지 전체를 `nameWidth`로 줬다. 긴 이름은 덜 잘렸지만, 짧은 이름만 있는 디렉터리에서도 ext/size/date/time/attrs 가 화면 오른쪽으로 밀려 이름과 확장자가 과하게 멀어졌다.

반대로 `.frame(maxWidth: .infinity)`에 맡기면 SwiftUI `HStack` 분배가 이름 컬럼을 거의 0pt까지 압축해 `A...` 같은 한 글자 truncation 이 생겼다.

## 올바른 해결

`nameWidth`는 현재 패널 rows 의 `displayName` / `volume.name` 최대 실측값에 렌더링 여유 padding 을 더해 계산한다. `forFlexible` 전체를 이름에 주지 않고, `nameWidth` 뒤에 ext/size/date/time/attrs 를 붙인 다음 남는 폭을 description 컬럼이 흡수하게 한다.

좁은 패널에서는 같은 `FileListLayout` 값으로 header 와 row 를 동시에 전환한다. 먼저 spacing 을 줄이고, 그래도 이름 실측 폭을 확보하지 못하면 attrs, ext 순서로 낮은 우선순위 컬럼을 숨긴다.

## 참고

- 구현: `Features/Pane/FileListView.swift`
- 요건: `docs/requirements/file-list-columns.md`
