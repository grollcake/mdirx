# LazyVStack 기본 alignment가 .center라 창이 좁아지면 왼쪽 컬럼이 잘림

## 현상

파일 목록에서 창을 좁히면 선택 마커(▶)·아이콘 컬럼이 사라졌다.
오른쪽 컬럼이 먼저 잘릴 것 같지만 실제로는 왼쪽이 먼저 잘렸다.

## 원인

`LazyVStack(spacing: 0)`의 기본 `alignment`는 `.center`.
행 내용(HStack)이 컨테이너 폭보다 넓어지면 `.center` 정렬 때문에
오버플로우가 양쪽으로 반씩 잘려, 왼쪽(leading) 컬럼도 잘린다.

## 올바른 해결

```swift
// 변경 전
LazyVStack(spacing: 0)

// 변경 후
LazyVStack(alignment: .leading, spacing: 0)
```

`alignment: .leading`을 명시하면 오버플로우가 오른쪽(trailing)으로만 잘려
왼쪽 컬럼은 항상 보인다.

## 적용 범위

고정 폭 컬럼이 여러 개 있는 모든 `LazyVStack` / `VStack` 목록.
행이 컨테이너보다 넓어질 수 있다면 반드시 `alignment: .leading` 명시.
