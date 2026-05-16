# isMountedVolume 플래그가 항상 false → paneRows dedup과 불일치

## 상황 / 의도

`selectableEntries`에서 드라이브를 제외하려고 `entry.isMountedVolume` 플래그를 사용했다.

## 잘못된 접근

`FileSystemActor.listDirectory`가 모든 `DirectoryEntry`를 `isMountedVolume: false`로 생성한다.
드라이브 제외 로직은 `paneRows`에서만 `mountedVolumes.map(\.id)`와 대조해 처리했기 때문에,
`selectableEntries`는 OrbStack·nas 같은 네트워크 볼륨 심볼릭을 일반 항목으로 통과시켰다.
결과: `selectAllToggle` 실행 시 드라이브 항목이 선택됨.

## 올바른 해결

`selectableEntries`와 `fileOnlyIDs` 모두에서 `mountedVolumes` URL 목록과 대조해 제외한다.

```swift
let volumeIDs = Set(mountedVolumes.map(\.id))
entries.filter { !$0.isParentLink && !$0.isMountedVolume && !volumeIDs.contains($0.id) }
```

`paneRows`의 dedup 로직과 동일한 기준을 공유해야 일관성이 유지된다.

## 참고

커밋 `cc6a787` — `feat(pane): 전체 선택 3단계 토글 (alt+u) + 드라이브 제외 수정`
