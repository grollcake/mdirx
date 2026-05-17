import SwiftUI
import Testing
@testable import MdirX

@Test
func koreanJamoMapsToQwertyWhenCommandHeld() {
    #expect(KoreanShortcutNormalizer.normalize(character: "ㅣ", modifiers: .command) == Character("l"))
}

@Test
func koreanJamoMapsToQwertyWhenOptionHeld() {
    #expect(KoreanShortcutNormalizer.normalize(character: "ㅏ", modifiers: .option) == Character("k"))
}

@Test
func koreanJamoMapsToQwertyWhenControlHeld() {
    #expect(KoreanShortcutNormalizer.normalize(character: "ㅜ", modifiers: .control) == Character("n"))
}

@Test
func englishLetterPassesThroughWithModifier() {
    #expect(KoreanShortcutNormalizer.normalize(character: "l", modifiers: .command) == Character("l"))
}

@Test
func koreanJamoUntouchedWithoutModifier() {
    #expect(KoreanShortcutNormalizer.normalize(character: "ㅣ", modifiers: []) == Character("ㅣ"))
}

@Test
func unmappedCharWithModifierReturnsOriginal() {
    #expect(KoreanShortcutNormalizer.normalize(character: ".", modifiers: .command) == Character("."))
}
