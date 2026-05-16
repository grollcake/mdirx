import Testing
import SwiftUI
@testable import MdirX

@MainActor
struct AppSettingsTests {

    // MARK: - Color(hex:) parsing

    @Test func hexRGB_parsesCorrectly() {
        let c = Color(hex: "#FF8000")
        #expect(c != nil)
    }

    @Test func hexRGBA_parsesCorrectly() {
        let c = Color(hex: "#FF800080")
        #expect(c != nil)
    }

    @Test func hexWithoutHash_parsesCorrectly() {
        let c = Color(hex: "FFFFFF")
        #expect(c != nil)
    }

    @Test func invalidHex_returnsNil() {
        #expect(Color(hex: "#ZZZZZZ") == nil)
        #expect(Color(hex: "#12345") == nil)
        #expect(Color(hex: "") == nil)
    }

    // MARK: - ResolvedColors merging

    @Test func nilPayload_givesDefaults() {
        let resolved = ResolvedColors(merging: nil)
        let defaults = ResolvedColors.defaults
        // Spot-check: panelBackground should match default
        // We compare via description since Color doesn't conform to Equatable directly
        #expect("\(resolved.panelBackground)" == "\(defaults.panelBackground)")
        #expect("\(resolved.folder)" == "\(defaults.folder)")
    }

    @Test func emptyPayload_givesDefaults() {
        let resolved = ResolvedColors(merging: ColorPayload())
        let defaults = ResolvedColors.defaults
        #expect("\(resolved.panelBackground)" == "\(defaults.panelBackground)")
        #expect("\(resolved.neutralBackground)" == "\(defaults.neutralBackground)")
    }

    @Test func validHexInPayload_overridesDefault() {
        var payload = ColorPayload()
        payload.folder = "#FF0000FF"
        let resolved = ResolvedColors(merging: payload)
        let override = Color(hex: "#FF0000FF")!
        #expect("\(resolved.folder)" == "\(override)")
    }

    @Test func invalidHexInPayload_fallsBackToDefault() {
        var payload = ColorPayload()
        payload.folder = "#ZZZZZZ"
        let resolved = ResolvedColors(merging: payload)
        let defaults = ResolvedColors.defaults
        #expect("\(resolved.folder)" == "\(defaults.folder)")
    }

    @Test func partialPayload_onlyOverridesSpecifiedKeys() {
        var payload = ColorPayload()
        payload.folder = "#0000FFFF"
        let resolved = ResolvedColors(merging: payload)
        let defaults = ResolvedColors.defaults
        // folder overridden
        #expect("\(resolved.folder)" == "\(Color(hex: "#0000FFFF")!)")
        // everything else unchanged
        #expect("\(resolved.panelBackground)" == "\(defaults.panelBackground)")
        #expect("\(resolved.code)" == "\(defaults.code)")
    }

    // MARK: - SettingsFile JSON decoding

    @Test func validJSON_decodesCorrectly() throws {
        let json = """
        {
          "version": 1,
          "colors": {
            "folder": "#FF0000FF",
            "panelBackground": "#000000"
          }
        }
        """.data(using: .utf8)!
        let file = try JSONDecoder().decode(SettingsFile.self, from: json)
        #expect(file.version == 1)
        #expect(file.colors?.folder == "#FF0000FF")
        #expect(file.colors?.panelBackground == "#000000")
        #expect(file.colors?.code == nil)
    }

    @Test func emptyColorsObject_decodesWithAllNils() throws {
        let json = #"{"version":1,"colors":{}}"#.data(using: .utf8)!
        let file = try JSONDecoder().decode(SettingsFile.self, from: json)
        #expect(file.colors?.folder == nil)
        #expect(file.colors?.panelBackground == nil)
    }

    @Test func missingColorsKey_decodesWithNilColors() throws {
        let json = #"{"version":1}"#.data(using: .utf8)!
        let file = try JSONDecoder().decode(SettingsFile.self, from: json)
        #expect(file.colors == nil)
    }

    @Test func invalidJSON_throwsOnDecode() {
        let json = "not json".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(SettingsFile.self, from: json)
        }
    }
}
