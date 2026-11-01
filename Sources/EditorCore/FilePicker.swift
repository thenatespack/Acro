import Foundation
#if os(macOS)
import AppKit
#endif

/// The platform's "choose files" dialog, where there is one (macOS). Elsewhere callers ask for
/// a path in the UI instead.
@MainActor
enum FilePicker {
    /// Set while an AI client drives the UI, and without a window: no modal dialog may open,
    /// so callers ask for a path in the UI instead.
    static var isSuppressed = false

    /// Whether `chooseFiles` can show a native dialog on this platform now.
    static var isAvailable: Bool {
        #if os(macOS)
        !isSuppressed
        #else
        false
        #endif
    }

    /// Shows a modal dialog for picking files and folders (several at once). Returns nil when
    /// cancelled or when there's no native dialog.
    static func chooseFiles(title: String, prompt: String) -> [URL]? {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.title = title
        panel.prompt = prompt
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.resolvesAliases = true
        return panel.runModal() == .OK && !panel.urls.isEmpty ? panel.urls : nil
        #else
        return nil
        #endif
    }

    /// Shows a modal dialog for picking one folder (a new one can be made in it). Returns nil
    /// when cancelled, suppressed (`isSuppressed`) or when there's no native dialog.
    static func chooseFolder(title: String, prompt: String) -> URL? {
        #if os(macOS)
        guard isAvailable else { return nil }
        let panel = NSOpenPanel()
        panel.title = title
        panel.prompt = prompt
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.resolvesAliases = true
        return panel.runModal() == .OK ? panel.url : nil
        #else
        return nil
        #endif
    }
}
