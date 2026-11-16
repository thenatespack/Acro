import Foundation
import EngineCore
import EngineScene

// A `.ui` layout (UI / HUD Builder) as the dialogue box. `DialogueLayoutPresenter` (Engine
// module) shows a conversation in any layout by setting these value keys and listening for
// these button events, so a layout made in the UI tab only has to use the names:
//
// Values the presenter sets:
// - `speaker`: the speaker's name ("" when none); `speakerColor`: its "#RRGGBB" color ("" for none).
// - `text`: the line (typed out letter by letter) or the choice's prompt.
// - `portrait`: the speaker's portrait texture (bind an image to it); `hasPortrait`: whether there is one.
// - `isLine` / `isChoice`: what is shown (for `visibleWhen`); `active`: whether anything is.
// - `choiceCount`; `choice1`…`choice9`: each option's text; `hasChoice1`…`hasChoice9`: whether it is shown.
//
// Button events the presenter answers:
// - `continue`: finish typing the line, else continue (also a click on any panel of the layout,
//   Enter or Space).
// - `choice1`…`choice9`: pick that option (also the number keys 1-9).
//
// `UIBuild.dialogue` (preset "dialogue") is a layout to start from that uses all of them.

/// The value keys and button events a dialogue `.ui` layout uses (see DialogueLayout.swift).
public enum DialogueLayoutKeys {
    public static let speaker = "speaker"
    public static let speakerColor = "speakerColor"
    public static let text = "text"
    public static let portrait = "portrait"
    public static let hasPortrait = "hasPortrait"
    public static let isLine = "isLine"
    public static let isChoice = "isChoice"
    public static let active = "active"
    public static let choiceCount = "choiceCount"
    /// The most options a layout can show (`choice1`…`choice9`).
    public static let maxChoices = 9

    /// The event that continues past a line.
    public static let continueEvent = "continue"

    /// The text key of option `number` (1-based): "choice1"…
    public static func choice(_ number: Int) -> String { "choice\(number)" }
    /// The shown flag of option `number` (1-based): "hasChoice1"…
    public static func hasChoice(_ number: Int) -> String { "hasChoice\(number)" }
    /// The option index (0-based) a button event picks, nil if it isn't "choice1"…"choice9".
    public static func choiceIndex(ofEvent event: String) -> Int? {
        guard event.hasPrefix("choice"), let n = Int(event.dropFirst(6)), (1...maxChoices).contains(n) else { return nil }
        return n - 1
    }

    /// Every value key the presenter sets.
    public static var allValueKeys: [String] {
        [speaker, speakerColor, text, portrait, hasPortrait, isLine, isChoice, active, choiceCount]
            + (1...maxChoices).flatMap { [choice($0), hasChoice($0)] }
    }

    /// The values that show `state`. `text` replaces the line's text (the typed-out part);
    /// `portrait` gives a speaker's portrait path (default: the speaker's `portrait`).
    public static func values(for state: DialogueRunner.State?, text: String? = nil,
                              portrait: ((DialogueSpeaker) -> String)? = nil) -> [String: JSONValue] {
        var speaker: DialogueSpeaker?
        var speakerID = ""
        var shownText = ""
        var options: [String] = []
        var isLine = false, isChoice = false
        switch state {
        case .line(let line)?:
            speaker = line.speaker
            speakerID = line.speakerID
            shownText = line.text
            isLine = true
        case .choices(let choices)?:
            speaker = choices.speaker
            speakerID = choices.speakerID
            shownText = choices.prompt
            options = choices.options.map(\.text)
            isChoice = true
        case .idle?, .finished?, nil:
            break
        }
        let portraitPath = speaker.map { portrait?($0) ?? $0.portrait } ?? ""
        var values: [String: JSONValue] = [
            Self.speaker: .string(speaker?.displayName ?? speakerID),
            Self.speakerColor: .string(speaker?.color ?? ""),
            Self.text: .string(text ?? shownText),
            Self.portrait: .string(portraitPath),
            Self.hasPortrait: .bool(!portraitPath.isEmpty),
            Self.isLine: .bool(isLine),
            Self.isChoice: .bool(isChoice),
            Self.active: .bool(isLine || isChoice),
            Self.choiceCount: .int(Int64(options.count)),
        ]
        for n in 1...maxChoices {
            let option = options.indices.contains(n - 1) ? options[n - 1] : nil
            values[choice(n)] = .string(option ?? "")
            values[hasChoice(n)] = .bool(option != nil)
        }
        return values
    }

    /// What a layout lacks to work as a dialogue box: a `text` key, and a way to continue and
    /// to pick options. Empty when it is usable.
    public static func problems(in build: UIBuild) -> [String] {
        var problems: [String] = []
        let keys = Set(build.valueKeys)
        let events = Set(build.events)
        if !keys.contains(text) { problems.append("no widget shows '\(text)' (bind a label to it or write {\(text)})") }
        if !(1...maxChoices).contains(where: { events.contains(choice($0)) }) {
            problems.append("no button sends 'choice1'… (options can only be picked with the number keys)")
        }
        if !events.contains(continueEvent) {
            problems.append("no button sends '\(continueEvent)' (lines continue on a click on a panel, Enter or Space)")
        }
        return problems
    }
}

extension UIBuild {
    /// A dialogue box to start from: a panel at the bottom with the portrait, the speaker's
    /// name, the line, four option buttons and a Continue button, using the `DialogueLayoutKeys`.
    public static var dialogue: UIBuild {
        let K = DialogueLayoutKeys.self
        // Sample values for the UI tab's preview (the presenter sets every key while playing).
        let values: [String: JSONValue] = [
            K.speaker: .string("Stranger"), K.text: .string("Hello there, traveler. What brings you to these parts?"),
            K.isLine: .bool(true), K.active: .bool(true), K.choice(1): .string("Who are you?"), K.choice(2): .string("Goodbye."),
        ]
        var widgets: [UIBuildWidget] = [
            UIBuildWidget(id: "dialogue", type: .hstack, anchor: .bottom, offset: Vec2(0, 24), width: 640, padding: 16, spacing: 14,
                          align: .start, background: "panel", borderColor: "panelBorder", cornerRadius: 12, visibleWhen: K.active),
            UIBuildWidget(id: "portrait", type: .image, parent: "dialogue", width: 72, height: 72, cornerRadius: 8, fit: .fill,
                          bind: K.portrait, visibleWhen: K.hasPortrait),
            UIBuildWidget(id: "column", type: .vstack, parent: "dialogue", grow: 1, spacing: 6, align: .stretch),
            UIBuildWidget(id: "speaker", type: .label, parent: "column", fontSize: 18, color: "accent", bind: K.speaker),
            UIBuildWidget(id: "text", type: .label, parent: "column", wrap: true, bind: K.text),
            UIBuildWidget(id: "choices", type: .vstack, parent: "column", spacing: 4, align: .stretch, visibleWhen: K.isChoice),
        ]
        for n in 1...4 {
            widgets.append(UIBuildWidget(id: K.choice(n), type: .button, parent: "choices", text: "\(n). {\(K.choice(n))}",
                                         event: K.choice(n), visibleWhen: K.hasChoice(n)))
        }
        widgets += [
            UIBuildWidget(id: "footer", type: .hstack, parent: "column", spacing: 6, visibleWhen: K.isLine),
            UIBuildWidget(id: "footerSpace", type: .spacer, parent: "footer", grow: 1),
            UIBuildWidget(id: "continue", type: .button, parent: "footer", text: "Continue", primary: true, event: K.continueEvent),
        ]
        return UIBuild(values: values, widgets: widgets)
    }
}
