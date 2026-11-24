#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
#if os(Windows)
import WinSDK
#endif

/// Keeps a console program's errors readable when it was started by double-clicking it.
///
/// On Windows, Explorer gives a console program (`Editor.exe`, `GameRunner.exe`) its own console
/// window, which closes the moment the process exits, taking any error printed to it along. After
/// ``install(title:)``, a crash (a Swift trap such as `fatalError`) shows a message box that holds
/// the console open, and ``fatal(_:)`` shows its message in one. Started from a terminal, which
/// stays open anyway, both only print. Elsewhere this does nothing beyond printing.
public enum StartupErrors {
    #if os(Windows)
    nonisolated(unsafe) private static var title = "Error"
    nonisolated(unsafe) private static var installed = false
    #endif

    /// Call first thing in `main`. `title` is the message box caption (the program's name).
    public static func install(title: String) {
        #if os(Windows)
        guard ownsConsole else { return }
        Self.title = title
        installed = true
        // Swift traps raise an exception nothing handles; its message is already on stderr.
        _ = SetUnhandledExceptionFilter { _ in
            StartupErrors.showMessageBox("\(StartupErrors.title) crashed. The console window shows why; it closes with this message.")
            return EXCEPTION_CONTINUE_SEARCH
        }
        #endif
    }

    /// Prints `message` to stderr and exits with status 1, showing it in a message box first when
    /// ``install(title:)`` found the program owns its console window.
    public static func fatal(_ message: String) -> Never {
        FileHandle.standardError.write(Data((message + "\n").utf8))
        #if os(Windows)
        if installed { showMessageBox(message) }
        #endif
        exit(1)
    }

    #if os(Windows)
    /// True when no other process shares the console: Explorer made it for us, so it closes with us.
    private static var ownsConsole: Bool {
        var processes = [DWORD](repeating: 0, count: 2)
        return GetConsoleProcessList(&processes, DWORD(processes.count)) == 1
    }

    private static func showMessageBox(_ message: String) {
        message.withCString(encodedAs: UTF16.self) { text in
            title.withCString(encodedAs: UTF16.self) { caption in
                _ = MessageBoxW(nil, text, caption, UINT(MB_OK) | UINT(MB_ICONERROR))
            }
        }
    }
    #endif
}
