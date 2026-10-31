import Testing
@testable import Engine

// ConfirmDialog: modal, Enter/click confirm, Esc/Cancel cancel, exactly one callback.

@MainActor private final class Driver {
    let input = Input()
    let ui = UIContext()
    let size = Vec2(500, 400)

    init() { ui.setViewport(size: size, scale: 1) }

    func frame(_ body: (Input) -> Void = { _ in }) {
        input.beginFrame()
        body(input)
        input.endEvents()
        ui.update(input: input, dt: 1.0 / 60, viewportSize: size, scale: 1)
    }

    func click(at p: Vec2) {
        frame { $0.mousePosition = p; $0.setButton(.left, down: true) }
        frame { $0.setButton(.left, down: false) }
    }

    func key(_ key: Key) {
        frame {
            $0.recordKeyPress(key, modifiers: [], isRepeat: false)
            $0.textKeyEvent(key, modifiers: [], isRepeat: false)
        }
    }
}

@MainActor private func present(_ d: Driver) -> (ConfirmDialog, () -> [String]) {
    var log: [String] = []
    let dialog = ConfirmDialog(title: "Delete \u{201C}Rock\u{201D}?", message: "This can't be undone.", confirmTitle: "Delete")
    dialog.onConfirm = { log.append("confirm") }
    dialog.onCancel = { log.append("cancel") }
    dialog.present(in: d.ui)
    d.frame()
    return (dialog, { log })
}

@MainActor @Suite struct ConfirmDialogTests {
    @Test func coversTheWindowCentersTheCardAndFocusesConfirm() {
        let d = Driver()
        var clicked = false
        let behind = Button("Behind") { clicked = true }
        d.ui.root.addChild(behind)
        let (dialog, log) = present(d)
        #expect(dialog.frame == UIRect(x: 0, y: 0, width: 500, height: 400))
        #expect(d.ui.focusedWidget === dialog.confirmButton)
        #expect(dialog.confirmButton.frame.x > dialog.cancelButton.frame.maxX)

        // Clicks outside the card reach nothing and don't close it.
        d.click(at: behind.frame.center)
        d.click(at: Vec2(5, 395))
        #expect(!clicked)
        #expect(d.ui.overlays.count == 1)
        #expect(log().isEmpty)
    }

    @Test func enterAndClickConfirmOnce() {
        let d = Driver()
        let (dialog, log) = present(d)
        d.key(.enter)
        #expect(log() == ["confirm"])
        #expect(d.ui.overlays.isEmpty)
        dialog.resolve(confirmed: false)  // already resolved: ignored
        #expect(log() == ["confirm"])

        let (second, log2) = present(d)
        d.click(at: second.confirmButton.frame.center)
        #expect(log2() == ["confirm"])
    }

    @Test func escapeAndCancelCancel() {
        let d = Driver()
        let (_, log) = present(d)
        d.key(.escape)
        #expect(log() == ["cancel"])
        #expect(d.ui.overlays.isEmpty)

        let (second, log2) = present(d)
        d.click(at: second.cancelButton.frame.center)
        #expect(log2() == ["cancel"])

        let (third, log3) = present(d)
        d.ui.dismissOverlay(third)
        #expect(log3() == ["cancel"])
    }
}
