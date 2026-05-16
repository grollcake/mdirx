import Foundation

@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private(set) var colors: ResolvedColors = .defaults

    func load() {
        guard let url = settingsURL,
              let data = try? Data(contentsOf: url) else { return }
        do {
            let file = try JSONDecoder().decode(SettingsFile.self, from: data)
            // Theme is the base; individual colors overlay on top.
            var payload: ColorPayload? = nil
            if let themeName = file.theme, let theme = ThemeName(rawValue: themeName) {
                payload = ColorPayload.theme(theme)
            }
            if let overrides = file.colors {
                payload = (payload ?? ColorPayload()).merged(with: overrides)
            }
            colors = ResolvedColors(merging: payload)
        } catch {
            print("[AppSettings] JSON parse error: \(error)")
        }
    }

    private var settingsURL: URL? {
        let nextToBundle = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("settings.json")
        if FileManager.default.fileExists(atPath: nextToBundle.path) {
            return nextToBundle
        }
        return FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MdirX/settings.json")
    }
}
