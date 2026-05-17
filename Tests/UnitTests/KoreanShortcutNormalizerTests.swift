import SwiftUI
import Testing
@testable import MdirX

@Test
@MainActor
func koreanJamoMapsToQwertyWhenCommandHeld() {
    let press = KeyPress(phase: .down, key: KeyEquivalent("ㅣ"), characters: "ㅣ", modifiers: .command)
    #expect(KoreanShortcutNormalizer.qwertyCharacter(for: press) == Character("l"))
}

@Test
@MainActor
func koreanJamoMapsToQwertyWhenOptionHeld() {
    let press = KeyPress(phase: .down, key: KeyEquivalent("ㅏ"), characters: "ㅏ", modifiers: .option)
    #expect(KoreanShortcutNormalizer.qwertyCharacter(for: press) == Character("k"))
}

@Test
@MainActor
func koreanJamoMapsToQwertyWhenControlHeld() {
    let press = KeyPress(phase: .down, key: KeyEquivalent("ㅜ"), characters: "ㅜ", modifiers: .control)
    #expect(KoreanShortcutNormalizer.qwertyCharacter(for: press) == Character("n"))
}

@Test
@MainActor
func englishLetterPassesThroughWithModifier() {
    let press = KeyPress(phase: .down, key: KeyEquivalent("l"), characters: "l", modifiers: .command)
    #expect(KoreanShortcutNormalizer.qwertyCharacter(for: press) == Character("l"))
}

@Test
@MainActor
func koreanJamoUntouchedWithoutModifier() {
    let press = KeyPress(phase: .down, key: KeyEquivalent("ㅣ"), characters: "ㅣ", modifiers: [])
    #expect(KoreanShortcutNormalizer.qwertyCharacter(for: press) == Character("ㅣ"))
}

@Test
@MainActor
func unmappedCharWithModifierReturnsOriginal() {
    let press = KeyPress(phase: .down, key: KeyEquivalent("."), characters: ".", modifiers: .command)
    #expect(KoreanShortcutNormalizer.qwertyCharacter(for: press) == Character("."))
}
