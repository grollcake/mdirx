import SwiftUI

struct ColorPayload: Codable {
    var panelBackground:    String?
    var neutralBackground:  String?
    var selectionActive:    String?
    var selectionInactive:  String?
    var markedBackground:   String?
    var folder:             String?
    var document:           String?
    var spreadsheet:        String?
    var image:              String?
    var code:               String?
    var archive:            String?
    var media:              String?
    var diskImage:          String?
    var paneBorder:         String?
    var middleColumn:       String?
}

struct SettingsFile: Codable {
    let version: Int
    let theme: String?
    let colors: ColorPayload?
}

// MARK: - Theme presets

enum ThemeName: String, CaseIterable {
    case catppuccinLatte     = "catppuccin-latte"
    case catppuccinFrappe    = "catppuccin-frappe"
    case catppuccinMacchiato = "catppuccin-macchiato"
    case catppuccinMocha     = "catppuccin-mocha"
}

extension ColorPayload {
    // Returns a fully populated payload (no nils) for the given theme.
    static func theme(_ name: ThemeName) -> ColorPayload {
        switch name {
        case .catppuccinMocha:
            return ColorPayload(
                panelBackground:    "#1E1E2E",
                neutralBackground:  "#181825",
                selectionActive:    "#89B4FA33",
                selectionInactive:  "#45475A66",
                markedBackground:   "#F38BA826",
                folder:             "#FAB387",
                document:           "#CDD6F4",
                spreadsheet:        "#A6E3A1",
                image:              "#F5C2E7",
                code:               "#89DCEB",
                archive:            "#F9E2AF",
                media:              "#89B4FA",
                diskImage:          "#94E2D5",
                paneBorder:         "#FFFFFF1E",
                middleColumn:       "#181825"
            )
        case .catppuccinMacchiato:
            return ColorPayload(
                panelBackground:    "#24273A",
                neutralBackground:  "#1E2030",
                selectionActive:    "#8AADF433",
                selectionInactive:  "#494D6466",
                markedBackground:   "#ED879626",
                folder:             "#F5A97F",
                document:           "#CAD3F5",
                spreadsheet:        "#A6DA95",
                image:              "#F5BDE6",
                code:               "#91D7E3",
                archive:            "#EED49F",
                media:              "#8AADF4",
                diskImage:          "#8BD5CA",
                paneBorder:         "#FFFFFF1E",
                middleColumn:       "#1E2030"
            )
        case .catppuccinFrappe:
            return ColorPayload(
                panelBackground:    "#303446",
                neutralBackground:  "#292C3C",
                selectionActive:    "#8CAAEE33",
                selectionInactive:  "#51576D66",
                markedBackground:   "#E7828426",
                folder:             "#EF9F76",
                document:           "#C6D0F5",
                spreadsheet:        "#A6D189",
                image:              "#F4B8E4",
                code:               "#99D1DB",
                archive:            "#E5C890",
                media:              "#8CAAEE",
                diskImage:          "#81C8BE",
                paneBorder:         "#FFFFFF1E",
                middleColumn:       "#292C3C"
            )
        case .catppuccinLatte:
            return ColorPayload(
                panelBackground:    "#EFF1F5",
                neutralBackground:  "#E6E9EF",
                selectionActive:    "#1E66F533",
                selectionInactive:  "#BCC0CC66",
                markedBackground:   "#D20F3926",
                folder:             "#FE640B",
                document:           "#4C4F69",
                spreadsheet:        "#40A02B",
                image:              "#EA76CB",
                code:               "#04A5E5",
                archive:            "#DF8E1D",
                media:              "#1E66F5",
                diskImage:          "#179299",
                paneBorder:         "#00000026",
                middleColumn:       "#E6E9EF"
            )
        }
    }

    // Overlay: non-nil values in `override` replace values in `self`.
    func merged(with override: ColorPayload) -> ColorPayload {
        var r = self
        if let v = override.panelBackground    { r.panelBackground    = v }
        if let v = override.neutralBackground  { r.neutralBackground  = v }
        if let v = override.selectionActive    { r.selectionActive    = v }
        if let v = override.selectionInactive  { r.selectionInactive  = v }
        if let v = override.markedBackground   { r.markedBackground   = v }
        if let v = override.folder             { r.folder             = v }
        if let v = override.document           { r.document           = v }
        if let v = override.spreadsheet        { r.spreadsheet        = v }
        if let v = override.image              { r.image              = v }
        if let v = override.code               { r.code               = v }
        if let v = override.archive            { r.archive            = v }
        if let v = override.media              { r.media              = v }
        if let v = override.diskImage          { r.diskImage          = v }
        if let v = override.paneBorder         { r.paneBorder         = v }
        if let v = override.middleColumn       { r.middleColumn       = v }
        return r
    }
}

struct ResolvedColors {
    let panelBackground:            Color
    let neutralBackground:          Color
    let selectionActive:            Color
    let selectionInactive:          Color
    let markedBackground:           Color
    let folder:                     Color
    let document:                   Color
    let spreadsheet:                Color
    let image:                      Color
    let code:                       Color
    let archive:                    Color
    let media:                      Color
    let diskImage:                  Color
    let paneBorder:                 Color
    let middleColumn:               Color

    static let defaults = ResolvedColors(
        panelBackground:    Color(white: 0.07),
        neutralBackground:  Color(white: 0.15),
        selectionActive:    Color.yellow.opacity(0.45),
        selectionInactive:  Color.gray.opacity(0.12),
        markedBackground:   Color(.sRGB, red: 0.31, green: 0.14, blue: 0.14, opacity: 1.0),
        folder:             Color(.sRGB, red: 0.98, green: 0.55, blue: 0.20),
        document:           Color.white,
        spreadsheet:        Color(.sRGB, red: 0.55, green: 0.80, blue: 0.40),
        image:              Color(.sRGB, red: 0.95, green: 0.55, blue: 0.85),
        code:               Color(.sRGB, red: 0.45, green: 0.85, blue: 0.95),
        archive:            Color.yellow,
        media:              Color(.sRGB, red: 0.45, green: 0.65, blue: 0.95),
        diskImage:          Color(.sRGB, red: 0.45, green: 0.85, blue: 0.85),
        paneBorder:         Color(white: 1.0, opacity: 0.12),
        middleColumn:       Color(white: 0.15)
    )

    init(
        panelBackground: Color,
        neutralBackground: Color,
        selectionActive: Color,
        selectionInactive: Color,
        markedBackground: Color,
        folder: Color,
        document: Color,
        spreadsheet: Color,
        image: Color,
        code: Color,
        archive: Color,
        media: Color,
        diskImage: Color,
        paneBorder: Color,
        middleColumn: Color
    ) {
        self.panelBackground   = panelBackground
        self.neutralBackground = neutralBackground
        self.selectionActive   = selectionActive
        self.selectionInactive = selectionInactive
        self.markedBackground  = markedBackground
        self.folder            = folder
        self.document          = document
        self.spreadsheet       = spreadsheet
        self.image             = image
        self.code              = code
        self.archive           = archive
        self.media             = media
        self.diskImage         = diskImage
        self.paneBorder        = paneBorder
        self.middleColumn      = middleColumn
    }

    init(merging payload: ColorPayload?) {
        let d = ResolvedColors.defaults
        func c(_ hex: String?, fallback: Color) -> Color {
            guard let hex else { return fallback }
            return Color(hex: hex) ?? fallback
        }
        panelBackground   = c(payload?.panelBackground,   fallback: d.panelBackground)
        neutralBackground = c(payload?.neutralBackground, fallback: d.neutralBackground)
        selectionActive   = c(payload?.selectionActive,   fallback: d.selectionActive)
        selectionInactive = c(payload?.selectionInactive, fallback: d.selectionInactive)
        markedBackground  = c(payload?.markedBackground,  fallback: d.markedBackground)
        folder            = c(payload?.folder,            fallback: d.folder)
        document          = c(payload?.document,          fallback: d.document)
        spreadsheet       = c(payload?.spreadsheet,       fallback: d.spreadsheet)
        image             = c(payload?.image,             fallback: d.image)
        code              = c(payload?.code,              fallback: d.code)
        archive           = c(payload?.archive,           fallback: d.archive)
        media             = c(payload?.media,             fallback: d.media)
        diskImage         = c(payload?.diskImage,         fallback: d.diskImage)
        paneBorder        = c(payload?.paneBorder,        fallback: d.paneBorder)
        middleColumn      = c(payload?.middleColumn,      fallback: d.middleColumn)
    }
}

extension Color {
    init?(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard (s.count == 6 || s.count == 8),
              let value = UInt64(s, radix: 16) else { return nil }
        let r, g, b, a: Double
        if s.count == 6 {
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1.0
        } else {
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
