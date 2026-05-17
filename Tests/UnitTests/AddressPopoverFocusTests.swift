import Foundation
import Testing
@testable import MdirX

@MainActor
private func makePane() -> PaneState {
    PaneState(slot: .left, initialURL: FileManager.default.temporaryDirectory)
}

private func u(_ s: String) -> URL {
    URL(fileURLWithPath: s, isDirectory: true)
}

@Test
@MainActor
func beginAddressEditingPopulatesItemsAndResetsFocus() {
    let pane = makePane()
    let items = AddressListItems(
        frequent: [u("/a"), u("/b")],
        recent: [u("/c")]
    )
    pane.beginAddressEditing(items: items)
    #expect(pane.addressEditing == true)
    #expect(pane.addressListItems == items)
    #expect(pane.addressListFocusIndex == nil)
    #expect(pane.addressListFlat.count == 3)
}

@Test
@MainActor
func cancelAddressEditingClearsItemsAndFocus() {
    let pane = makePane()
    pane.beginAddressEditing(items: AddressListItems(frequent: [u("/a")], recent: []))
    pane.focusListFirst()
    pane.cancelAddressEditing()
    #expect(pane.addressEditing == false)
    #expect(pane.addressListItems == .empty)
    #expect(pane.addressListFocusIndex == nil)
}

@Test
@MainActor
func focusListFirstReturnsFalseWhenEmpty() {
    let pane = makePane()
    pane.beginAddressEditing()
    #expect(pane.focusListFirst() == false)
    #expect(pane.addressListFocusIndex == nil)
}

@Test
@MainActor
func focusListFirstReturnsTrueAndSetsZero() {
    let pane = makePane()
    pane.beginAddressEditing(items: AddressListItems(frequent: [u("/a")], recent: [u("/b")]))
    #expect(pane.focusListFirst() == true)
    #expect(pane.addressListFocusIndex == 0)
}

@Test
@MainActor
func focusListNextClampsToLast() {
    let pane = makePane()
    pane.beginAddressEditing(items: AddressListItems(frequent: [u("/a"), u("/b")], recent: [u("/c")]))
    pane.focusListFirst()                 // 0
    pane.focusListNext()                  // 1
    pane.focusListNext()                  // 2
    pane.focusListNext()                  // clamp at 2
    #expect(pane.addressListFocusIndex == 2)
}

@Test
@MainActor
func focusListPreviousFromZeroGoesToNil() {
    let pane = makePane()
    pane.beginAddressEditing(items: AddressListItems(frequent: [u("/a"), u("/b")], recent: []))
    pane.focusListFirst()                 // 0
    pane.focusListPrevious()              // → nil (TextField)
    #expect(pane.addressListFocusIndex == nil)
}

@Test
@MainActor
func focusCanRoundTripBetweenFieldAndList() {
    let pane = makePane()
    pane.beginAddressEditing(items: AddressListItems(frequent: [u("/a"), u("/b")], recent: []))
    pane.focusListFirst()
    #expect(pane.addressListFocusIndex == 0)
    pane.focusListPrevious()
    #expect(pane.addressListFocusIndex == nil)
    pane.focusListFirst()
    #expect(pane.addressListFocusIndex == 0)
}

@Test
@MainActor
func addressListFocusedURLReadsFlat() {
    let pane = makePane()
    pane.beginAddressEditing(items: AddressListItems(frequent: [u("/a")], recent: [u("/b"), u("/c")]))
    pane.focusListFirst()                 // 0 → /a
    #expect(pane.addressListFocusedURL == u("/a"))
    pane.focusListNext()                  // 1 → /b (first recent)
    #expect(pane.addressListFocusedURL == u("/b"))
    pane.focusTextField()                 // nil
    #expect(pane.addressListFocusedURL == nil)
}
