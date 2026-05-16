# Swift 6 strict concurrency 를 처음부터 켜도 placeholder 단계는 무경고

## 상황 / 의도

M1 스캐폴딩에서 [PLAN.md](../../../PLAN.md) 의 결정대로 `SWIFT_VERSION=6.0` + `SWIFT_STRICT_CONCURRENCY=complete` 를 초기부터 켜고 빈 SwiftUI 앱을 빌드. 사전에는 `@MainActor` 어디에 붙여야 할지 가이드를 만들지 고민했음.

## 올바른 해결

`App`/`View`/`Scene` 등 SwiftUI 표준 프로토콜은 이미 `@MainActor` 격리가 선언돼 있어, `@main struct MdirXApp: App` · `struct ContentView: View` · `enum PersistenceBootstrap { static func makeEmptyContainer() throws -> ModelContainer }` 수준의 placeholder 는 추가 표기 없이 **0 warning** 으로 빌드된다.

→ 동시성 가이드는 실제 actor 경계(`FileSystemActor`, OperationQueue, AsyncStream)가 등장하는 시점에 작성해도 늦지 않다. 스캐폴딩 단계에서 선제적으로 `@MainActor` 를 흩뿌릴 필요 없음.

## 참고

- 커밋 `49f908b chore(scaffold): bootstrap MdirX Xcode project (M1)`
- [PLAN.md §4.2 동시성 모델](../../../PLAN.md)
