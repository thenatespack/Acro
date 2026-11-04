import Engine
import Foundation

/// The Export Game window: a modal card that picks what Build Game (`game.build`) builds and
/// where, then starts it.
///
/// - **Platform**: macOS, Linux or Windows. Natively only this machine's platform can be built
///   (there is no cross-compiling); Linux can also be built in Docker from any machine. The
///   others say why, and Export stays disabled.
/// - **Architecture**: x86_64 or arm64. macOS builds either (`swift build --arch`); Linux in
///   Docker builds either (the one that isn't the machine's under emulation); otherwise only the
///   machine's own.
/// - **Configuration**: Release (optimized, what to ship) or Debug (unoptimized, with assertions
///   and debug info).
/// - **Build in Docker**: Linux only (GameExporterDocker.swift); turned on when Linux is picked
///   on another platform.
/// - **Output folder**: where the app or game folder goes; empty is the default
///   (`Build/<platform>-<arch>[-debug]` in the project). Choose… opens a folder picker.
///
/// The choice is remembered for the session (`EditorGameExport.lastChoice`). The toolbar's
/// Build Game button opens it; Enter or Export starts the build and closes it, Esc or Cancel
/// closes it.
@MainActor
public final class ExportDialog: Widget {
    /// What the dialog picks.
    public struct Choice: Equatable, Sendable {
        public var platform: CookPlatform
        public var architecture: BuildArchitecture
        public var configuration: BuildConfiguration
        public var useDocker: Bool
        /// The output folder (absolute, or relative to the project folder); nil: the default.
        public var output: String?

        public init(platform: CookPlatform = .current, architecture: BuildArchitecture = .current,
                    configuration: BuildConfiguration = .release, useDocker: Bool = false, output: String? = nil) {
            self.platform = platform
            self.architecture = architecture
            self.configuration = configuration
            self.useDocker = useDocker
            self.output = output
        }

        /// `game.build`'s arguments for it.
        public var arguments: GameBuildCommand.Arguments {
            .init(output: output, platform: platform, configuration: configuration, architecture: architecture,
                  docker: useDocker ? true : nil)
        }
    }

    private unowned let session: EditorSession
    public private(set) var choice: Choice
    private let card: VStack
    private let platformMenu: Dropdown
    private let architectureMenu: Dropdown
    private let configurationMenu: Dropdown
    private let dockerBox = Checkbox("Build in Docker", name: "exportDocker")
    private let outputField = TextField(placeholder: "", name: "exportOutput")
    private let chooseButton = Button("Choose…", name: "exportChooseOutput")
    private let note = Label("", role: .caption, name: "exportNote")
    private let exportButton = Button("Export", role: .primary, name: "exportStart")
    private var isClosed = false

    /// Called after the dialog closed.
    public var onClose: (() -> Void)?

    static let platforms = CookPlatform.allCases
    static let architectures = BuildArchitecture.allCases
    static let configurations = BuildConfiguration.allCases

    public init(session: EditorSession, initial: Choice? = nil) {
        self.session = session
        self.choice = initial ?? session.gameExport.lastChoice ?? Choice()
        platformMenu = Dropdown(options: [], name: "exportPlatform")
        architectureMenu = Dropdown(options: [], name: "exportArchitecture")
        configurationMenu = Dropdown(options: Self.configurations.map(\.title), name: "exportConfiguration")
        let heading = Label("Export Game", role: .heading, name: "exportTitle")
        let cancel = Button("Cancel", name: "exportCancel")
        let footer = HStack(spacing: 8, name: "exportFooter", [Spacer(), cancel, exportButton])
        note.wraps = true
        card = VStack(spacing: 10, padding: EdgeInsets(18), name: "exportCard", [heading, Separator()])
        super.init(name: "exportDialog")
        card.background = .clear  // drawn by `draw`, with its shadow
        addChild(card)
        row("Platform", platformMenu, tooltip: "The operating system the game runs on")
        row("Architecture", architectureMenu, tooltip: "The CPU the game runs on: x86_64 (Intel, AMD) or arm64 (Apple silicon, ARM)")
        row("Configuration", configurationMenu,
            tooltip: "Release: optimized, what to ship. Debug: unoptimized, with assertions and debug info, for tracking down problems")
        row("", dockerBox, tooltip: "Build a Linux game in a Docker container with the Linux Swift toolchain: from any machine, "
            + "for either architecture (the other one emulated, slower). Needs Docker installed and running")
        outputField.style.grow = 1
        outputField.style.shrink = 1
        outputField.style.minWidth = 0
        chooseButton.style.shrink = 0
        row("Output folder", HStack(spacing: 6, name: "exportOutputRow", [outputField, chooseButton]),
            tooltip: "Where the app or game folder goes (its previous build there is replaced). Empty: the project's Build folder")
        card.addChild(note)
        card.addChild(Spacer(grow: 0, minLength: 4))
        card.addChild(footer)

        let build = GameBuildCommand.id.rawValue
        for widget in [platformMenu, architectureMenu, configurationMenu, dockerBox, outputField, chooseButton, exportButton] as [Widget] {
            widget.command = build
        }
        outputField.text = choice.output ?? ""
        cancel.action = { [unowned self] in close() }
        exportButton.action = { [unowned self] in export() }
        platformMenu.onChange = { [unowned self] index in
            guard Self.platforms.indices.contains(index) else { return }
            setPlatform(Self.platforms[index])
        }
        architectureMenu.onChange = { [unowned self] index in
            guard Self.architectures.indices.contains(index) else { return }
            choice.architecture = Self.architectures[index]
            refresh()
        }
        configurationMenu.onChange = { [unowned self] index in
            guard Self.configurations.indices.contains(index) else { return }
            choice.configuration = Self.configurations[index]
            refresh()
        }
        dockerBox.onChange = { [unowned self] on in
            choice.useDocker = on && choice.platform == .linux
            refresh()
        }
        let commitOutput: (String) -> Void = { [unowned self] text in setOutput(text) }
        outputField.onSubmit = commitOutput
        outputField.onEndEditing = commitOutput
        outputField.onChange = commitOutput
        chooseButton.action = { [unowned self] in chooseOutput() }
        refresh()
    }

    public override var accessibilityRole: UIAccessibilityRole { .dialog }
    public override var accessibilityText: String? { "Export Game" }

    /// Shows the dialog over everything in `context`.
    public func present(in context: UIContext) {
        context.presentOverlay(self)
    }

    /// Closes the dialog without exporting (like Cancel or Esc).
    public func close() {
        guard !isClosed else { return }
        context?.dismissOverlay(self)
        finishClosing()
    }

    public override func overlayDismissed() { finishClosing() }

    private func finishClosing() {
        guard !isClosed else { return }
        isClosed = true
        onClose?()
    }

    /// Why Export is disabled, or nil when it can run.
    public var unavailableReason: String? {
        session.commands.unavailableReason(GameBuildCommand.id)
            ?? EditorGameExport.unbuildableReason(platform: choice.platform, architecture: choice.architecture, docker: choice.useDocker)
    }

    /// Picks `choice` (as the controls would).
    public func select(_ choice: Choice) {
        self.choice = choice
        if !outputField.isFocused { outputField.text = choice.output ?? "" }
        refresh()
    }

    /// Picks `platform`: Linux on another platform turns on Docker (the only way to build it
    /// there), any other platform turns it off.
    public func setPlatform(_ platform: CookPlatform) {
        choice.platform = platform
        if platform != .linux {
            choice.useDocker = false
        } else if CookPlatform.current != .linux {
            choice.useDocker = true
        }
        refresh()
    }

    /// The output folder from the field (trimmed; empty is the default).
    public func setOutput(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        choice.output = trimmed.isEmpty ? nil : trimmed
        refresh()
    }

    /// The folder picker (macOS); elsewhere the field is the way to type one.
    private func chooseOutput() {
        guard FilePicker.isAvailable,
              let url = FilePicker.chooseFolder(title: "Export the game into", prompt: "Choose") else { return }
        let path = displayPath(url)
        outputField.text = path
        setOutput(path)
    }

    /// The folder the build goes into for the current choice.
    public var outputFolder: URL? {
        guard let project = session.project else { return nil }
        if let output = choice.output {
            let expanded = output.hasPrefix("~") ? NSString(string: output).expandingTildeInPath : output
            return URL(fileURLWithPath: expanded, relativeTo: project.root).standardizedFileURL
        }
        return GameExporter.defaultOutput(for: project, platform: choice.platform, configuration: choice.configuration,
                                          architecture: choice.architecture)
    }

    /// `url` relative to the project folder when it is inside it.
    private func displayPath(_ url: URL) -> String {
        guard let root = session.project?.root.standardizedFileURL.path else { return url.path }
        let path = url.standardizedFileURL.path
        return path.hasPrefix(root + "/") ? String(path.dropFirst(root.count + 1)) : path
    }

    /// Starts the build with the current choice and closes the dialog; the build's progress goes to the console.
    public func export() {
        if outputField.isFocused { setOutput(outputField.text) }
        guard unavailableReason == nil else { return }
        session.gameExport.lastChoice = choice
        var arguments = choice.arguments
        arguments.output = outputFolder?.path ?? choice.output
        do {
            _ = try session.commands.start(GameBuildCommand.self, arguments)
            close()
        } catch {
            note.text = "\(error)"
        }
    }

    /// Pushes the choice into the controls, the note and the Export button.
    public func refresh() {
        let host = CookPlatform.current
        let platforms = Self.platforms.map { platform -> String in
            if platform == host { return "\(platform.title) (this machine)" }
            return platform == .linux ? "\(platform.title) (in Docker)" : "\(platform.title) (build on \(platform.title))"
        }
        if platformMenu.options != platforms { platformMenu.options = platforms }
        let architectures = Self.architectures.map { arch -> String in
            let title = arch.title(on: choice.platform)
            if choice.useDocker { return arch == .current ? title : "\(title) (emulated, slower)" }
            return choice.platform == host && !arch.canBuild(for: host) ? "\(title) (not on this machine)" : title
        }
        if architectureMenu.options != architectures { architectureMenu.options = architectures }
        sync(platformMenu, Self.platforms.firstIndex(of: choice.platform))
        sync(architectureMenu, Self.architectures.firstIndex(of: choice.architecture))
        sync(configurationMenu, Self.configurations.firstIndex(of: choice.configuration))
        if dockerBox.isOn != choice.useDocker { dockerBox.isOn = choice.useDocker }
        dockerBox.isEnabled = choice.platform == .linux
        chooseButton.isEnabled = FilePicker.isAvailable && session.project != nil
        chooseButton.tooltip = FilePicker.isAvailable ? "Pick the output folder" : "Type the folder in the field (no folder picker here)"
        if let project = session.project {
            let placeholder = displayPath(GameExporter.defaultOutput(for: project, platform: choice.platform, configuration: choice.configuration,
                                                                     architecture: choice.architecture))
            if outputField.placeholder != placeholder { outputField.placeholder = placeholder }
        }

        let reason = unavailableReason
        exportButton.isEnabled = reason == nil
        exportButton.tooltip = reason ?? "Cook the scenes and build the game; progress goes to the console"
        let text: String
        if let reason {
            text = reason
        } else if let folder = outputFolder {
            let what = choice.platform == .macos ? "an app" : "a game folder"
            let first = choice.useDocker
                ? "The first Docker build downloads the Swift toolchain and compiles the engine: many minutes."
                : "The first \(choice.configuration.rawValue) build for an architecture compiles the engine: minutes."
            text = "Builds \(what) into \(displayPath(folder))/ (the previous one there is replaced). \(first)"
        } else {
            text = ""
        }
        if note.text != text { note.text = text }
    }

    private func sync(_ menu: Dropdown, _ index: Int?) {
        if let index, menu.selectedIndex != index { menu.select(index) }
    }

    private func row(_ label: String, _ editor: Widget, tooltip: String) {
        let title = Label(label, role: .secondary, name: "exportLabel")
        title.style.width = 120
        title.style.shrink = 1
        title.style.minWidth = 60
        title.tooltip = tooltip
        editor.style.grow = 1
        editor.style.shrink = 1
        editor.style.minWidth = 0
        editor.tooltip = tooltip
        card.addChild(HStack(spacing: 8, name: "exportRow", [title, editor]))
    }

    // MARK: Widget

    public override func overlayFrame(in viewport: UIRect) -> UIRect { viewport }

    public override func layoutChildren() {
        card.padding = EdgeInsets(theme.dialogPadding)
        let width = min(520, max(frame.width - 32, 200))
        let height = min(card.measure(width: width).y, max(frame.height - 32, 160))
        card.layout(in: UIRect(x: (frame.x + (frame.width - width) / 2).rounded(), y: (frame.y + (frame.height - height) / 2).rounded(),
                               width: width, height: height))
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown, .pointerUp, .pointerMove, .scroll:
            return true  // modal: nothing behind it reacts
        case .key(let e) where e.key == .escape:
            close()
            return true
        case .key(let e) where e.key == .enter:
            export()
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        list.fillRect(frame, color: theme.modalDim)
        let radii = UICornerRadii(theme.dialogCornerRadius)
        list.fillRect(card.frame.inset(by: -6), color: theme.shadow.withAlpha(theme.shadow.a / 2), radii: UICornerRadii(theme.dialogCornerRadius + 6))
        list.fillRect(card.frame, color: theme.popupBackground, radii: radii)
        list.strokeRect(card.frame, color: theme.popupBorder, width: theme.borderWidth, radii: radii)
    }
}
