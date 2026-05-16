# SwiftUI `ForEach` 중복 id — 심볼릭 ↔ mounted volume 같은 URL

## 상황 / 의도

듀얼 패널 파일 목록에서 `entries`(`listDirectory` 결과)와 `mountedVolumes`(`VolumeService`)를 한 번에 `ForEach(state.paneRows)` 로 렌더링. `paneRows = fileRows + volumeRows` 로 단순 합쳐 `id: URL` 기준으로 식별.

홈 디렉터리(`~/`) 에 `OrbStack` 같이 **`/Volumes/<name>` 으로 향하는 심볼릭 폴더**가 있으면:

- `entries[8].id == /Volumes/OrbStack`  (folder 표현, kind: `.file`)
- `mountedVolumes[2].id == /Volumes/OrbStack` (volume 표현, kind: `.volume`)

같은 URL 이 두 번 등장 → `ForEach` 가 동일 id 를 보면 한쪽만 렌더링.

## 증상

행 번호가 뒤죽박죽으로 보인다:

```
1, 2, 3, 4, 5, 6, 7, 8, 19, 10, 11, ..., 18, [공백], 20
```

- 폴더 OrbStack(rowNumber 9 자리) 가 화면에서 빠짐
- 대신 OrbStack 의 **volume 표현** 이 그 자리에 끼어들어가 보임
- 그러나 그 행에 매겨진 rowNumber 는 `entries.count + volume_index + 1 = 19`
- 사용자 입장에서는 "왜 9가 없고 19 가 그 자리에 있지?" 로 보임
- 추가로 마지막 volume 행이 `LazyVStack` 다른 측정 패스에 걸려 컬럼 폭이 잠깐 어긋나기도 함

## 잘못된 접근

- 폴더가 비어 보여서 listDirectory 결과를 다시 의심.
- `entries` 정렬 / 한글 비교 / 심볼릭 처리 의심.
- `rowNumber` 산식 오프셋 의심.
- `Table` vs `LazyVStack` 의 정렬·virtualization 의심.

위 중 어느 것도 아니라, **`ForEach` 가 받은 컬렉션 안에 동일 `id` 가 두 번 있다는 사실** 이 진짜 원인. SwiftUI 는 이 경우 콘솔 경고 없이 한쪽만 그린다.

## 올바른 해결

`paneRows` 합치는 단계에서:

1. `mountedVolumes` 의 id 집합을 먼저 만든다.
2. `entries` 중 그 집합과 겹치는 항목은 **제외**(볼륨 표현 우선).
3. 단일 카운터로 `1..N` 까지 **연속 번호** 재부여.

```swift
extension PaneState {
    var paneRows: [PaneRow] {
        let volumeIDs = Set(mountedVolumes.map(\.id))
        var rows: [PaneRow] = []
        var n = 0
        for entry in entries where !volumeIDs.contains(entry.id) {
            n += 1
            rows.append(PaneRow(id: entry.id, rowNumber: n, kind: .file(entry)))
        }
        for volume in mountedVolumes {
            n += 1
            rows.append(PaneRow(id: volume.id, rowNumber: n, kind: .volume(volume)))
        }
        return rows
    }
}
```

이렇게 하면:

- `ForEach` 가 받는 컬렉션의 id 가 모두 unique → 모든 행이 렌더링됨
- 행 번호가 시각적으로 1..N 연속
- 심볼릭이 가리키는 마운트 볼륨은 "드라이브" 표현으로 한 번만 등장(잔량 게이지 포함)

## 일반화

`ForEach` 에 넘기는 컬렉션은 **id 가 컬렉션 내부에서 unique 한지** 매번 점검한다. 두 출처(예: 로컬 리스트 + 외부 서비스)에서 같은 식별자가 들어올 수 있으면 합치는 단계에서 dedupe 또는 prefix/네임스페이스 분리.

좋은 진단 도구:

```swift
assert(Set(paneRows.map(\.id)).count == paneRows.count, "duplicate ids in paneRows")
```

개발 빌드에서만 켜면 같은 함정에 다시 안 빠진다.

## 참고

- 변경 파일: `Features/Pane/PaneRow.swift`
- 관련 계획: [`.plan/0516-1722-multi-selection.done.md`](../../.plan/0516-1722-multi-selection.done.md) 검증 단계에서 발견.
