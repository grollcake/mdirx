import Testing
@testable import MdirX

@Test
@MainActor
func browserSessionStartsWithLeftActive() {
    let session = BrowserSession()
    #expect(session.activePane == .left)
}

@Test
@MainActor
func browserSessionToggleAlternatesActivePane() {
    let session = BrowserSession()
    session.toggleActive()
    #expect(session.activePane == .right)
    session.toggleActive()
    #expect(session.activePane == .left)
}
