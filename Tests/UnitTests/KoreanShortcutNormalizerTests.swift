import SwiftUI
import Testing
@testable import MdirX

@Test
@MainActor
func koreanJamoMapsToQwertyWhenCommandHeld() {
    #expect(KoreanShortcutNormalizer.normalize(character: "ㅣ", modifiers: .command) == Character("l"))
}

@Test
@MainActor
func koreanJamoMapsToQwertyWhenOptionHeld() {
    #expect(KoreanShortcutNormalizer.normalize(character: "ㅏ", modifiers: .option) == Character("k"))
}

@Test
@MainActor
func koreanJamoMapsToQwertyWhenControlHeld() {
    #expect(KoreanShortcutNormalizer.normalize(character: "ㅜ", modifiers: .control) == Character("n"))
}

@Test
@MainActor
func englishLetterPassesThroughWithModifier() {
    #expect(KoreanShortcutNormalizer.normalize(character: "l", modifiers: .command) == Character("l"))
}

@Test
@MainActor
func koreanJamoUntouchedWithoutModifier() {
    #expect(KoreanShortcutNormalizer.normalize(character: "ㅣ", modifiers: []) == Character("ㅣ"))
}

@Test
@MainActor
func unmappedCharWithModifierReturnsOriginal() {
    #expect(KoreanShortcutNormalizer.normalize(character: ".", modifiers: .command) == Character("."))
}
