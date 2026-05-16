# 일괄 선택 기능은 driveIDs URL 집합으로 볼륨을 제외해야 한다

## 상황 / 의도

`selectAllToggle` 같은 일괄 선택 동작을 구현할 때 드라이브(볼륨)를 제외하려 했다.

## 잘못된 접근

`DirectoryEntry.isMountedVolume` 플래그로 제외하려 했으나, 이 플래그는 항상 `false`이므로 실제로 제외되지 않는다.

## 올바른 해결

`VolumeService.mountedVolumes()`가 반환하는 `MountedVolume.id` (URL) 집합을 기준으로 제외한다.

```swift
let volumeIDs = Set(mountedVolumes.map(\.id))
// 선택 가능 항목 필터 시 volumeIDs.contains($0.id) 를 추가로 체크
```

향후 유사한 일괄 동작(복사·이동·삭제 등)을 구현할 때도 동일하게 적용한다.

## 참고

커밋 `cc6a787` — `feat(pane): 전체 선택 3단계 토글 (alt+u) + 드라이브 제외 수정`
