import Foundation

// A layout lint for a laid-out widget tree: interactive widgets that are outside the window or
// their parent, cut off by a parent that doesn't scroll, too small to hit, overlapping another
// control, button titles that don't fit, and text too small to read. UI tests run it at several
// window sizes and scales (the editor's EditorLayoutTests); `Evals/ui-audit.py` runs the same
// geometry checks on a live editor's `ui.snapshot`.
//
// ```swift
// ui.setViewport(size: Vec2(800, 600), scale: 2)
// for issue in ui.layoutAudit() { print(issue) }   // "overlap: editorRoot/toolbar/undo ∩ …"
// ```
//
// Content inside a `ScrollView`, list or tree, or a panel whose content overflows (it scrolls),
// is exempt from the containment checks (it scrolls into view), as are the parts a widget draws
// itself (tabs, rows, menu items), which their widget clips and scrolls. Sizes are compared in points at the context's `uiScale`.

/// One problem `UIContext.layoutAudit` found.
public struct UILayoutIssue: Sendable, Equatable, CustomStringConvertible {
    public enum Kind: String, Sendable, CaseIterable {
        /// An interactive widget, or a panel, list or scroll view, reaching past the window.
        case outsideWindow
        /// An interactive widget reaching past its parent (which doesn't scroll).
        case outsideParent
        /// An interactive widget partly or wholly cut off by a clipping parent that doesn't scroll.
        case clipped
        /// Two interactive elements on the same layer overlapping (neither inside the other).
        case overlap
        /// An interactive element narrower or shorter than `UILayoutAuditOptions.minHitSize`.
        case tooSmall
        /// Text smaller than `UILayoutAuditOptions.minTextSize` on screen.
        case smallText
        /// A title that doesn't fit and has no tooltip to read it in full.
        case truncatedWithoutTooltip
    }

    public var kind: Kind
    /// The element's accessibility path (`UIContext.accessibilityElements`).
    public var path: String
    /// The other element, for overlaps.
    public var otherPath: String?
    public var frame: UIRect
    public var detail: String

    public var description: String {
        "\(kind.rawValue): \(path)\(otherPath.map { " ∩ \($0)" } ?? "") \(detail)"
    }
}

/// Thresholds for `UIContext.layoutAudit`.
public struct UILayoutAuditOptions: Sendable {
    /// Smallest width and height (points, after `uiScale`) of something to click.
    public var minHitSize: Float = 12
    /// Smallest text size (points, after `uiScale`).
    public var minTextSize: Float = 9
    /// Overlaps and overhangs up to this many points are ignored (borders, rounding).
    public var tolerance: Float = 1
    public var checks = Set(UILayoutIssue.Kind.allCases)

    public init(minHitSize: Float = 12, minTextSize: Float = 9, tolerance: Float = 1,
                checks: Set<UILayoutIssue.Kind> = Set(UILayoutIssue.Kind.allCases)) {
        self.minHitSize = minHitSize
        self.minTextSize = minTextSize
        self.tolerance = tolerance
        self.checks = checks
    }
}

extension Widget {
    /// Whether this widget scrolls what it contains (children or drawn items) into view.
    var scrollsContent: Bool {
        self is ScrollView || self is RowListView || ((self as? TabView)?.contentOverflow ?? 0) > 0
    }
}

extension UIContext {
    /// Lays out if needed and checks every visible widget (see the notes at the top of the file).
    public func layoutAudit(_ options: UILayoutAuditOptions = UILayoutAuditOptions()) -> [UILayoutIssue] {
        let elements = accessibilityElements()
        var pathOf: [ObjectIdentifier: String] = [:]
        for element in elements where element.itemKey == nil { pathOf[ObjectIdentifier(element.widget)] = element.path }
        let tolerance = options.tolerance
        let zoom = uiScale
        var issues: [UILayoutIssue] = []
        func report(_ kind: UILayoutIssue.Kind, _ path: String, _ frame: UIRect, _ detail: String, other: String? = nil) {
            if options.checks.contains(kind) {
                issues.append(UILayoutIssue(kind: kind, path: path, otherPath: other, frame: frame, detail: detail))
            }
        }
        func inside(_ a: UIRect, _ b: UIRect) -> Bool {
            a.x >= b.x - tolerance && a.y >= b.y - tolerance && a.maxX <= b.maxX + tolerance && a.maxY <= b.maxY + tolerance
        }
        func intersection(_ a: UIRect, _ b: UIRect) -> UIRect? {
            let x0 = max(a.x, b.x), y0 = max(a.y, b.y), x1 = min(a.maxX, b.maxX), y1 = min(a.maxY, b.maxY)
            return x1 > x0 && y1 > y0 ? UIRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0) : nil
        }
        func describe(_ r: UIRect) -> String { "[\(Int(r.x)), \(Int(r.y)), \(Int(r.width))x\(Int(r.height))]" }

        // Theme sizes every control uses.
        let theme = self.theme
        for (name, size) in [("fontSize", theme.fontSize), ("smallFontSize", theme.smallFontSize),
                             ("tooltipFontSize", theme.tooltipFontSize)] where size * zoom < options.minTextSize {
            report(.smallText, "theme.\(name)", .zero, "\(size * zoom) pt < \(options.minTextSize) pt")
        }

        /// Interactive rects to compare for overlaps, per layer (the root, each overlay, each floating window).
        var hitRects: [(path: String, rect: UIRect, layer: Int, widget: Widget, isItem: Bool)] = []
        var layerCount = 0

        func visit(_ widget: Widget, clip: UIRect, scrolled: Bool, clipOwner: Widget?, layer: Int) {
            guard !widget.isHidden else { return }
            var layer = layer
            if widget is DockFloatingWindow {
                layerCount += 1
                layer = layerCount
            }
            let path = pathOf[ObjectIdentifier(widget)] ?? widget.name
            let frame = widget.frame
            let visible = intersection(frame, clip)
            // A panel, list or scroll view cut by the window hides whatever it holds out there.
            if !scrolled, [.tabGroup, .scrollView, .list, .tree, .viewport].contains(widget.accessibilityRole), !inside(frame, viewport) {
                report(.outsideWindow, path, frame, "\(describe(frame)) vs window \(describe(viewport))")
            }
            if widget.accessibilityRole.isInteractive {
                if !scrolled {
                    if !inside(frame, viewport) {
                        report(.outsideWindow, path, frame, "\(describe(frame)) vs window \(describe(viewport))")
                    } else if let parent = widget.parent, parent.frame.width > 0 || parent.frame.height > 0,
                              !(parent is DockFloatingWindow), !inside(frame, parent.frame) {
                        report(.outsideParent, path, frame, "\(describe(frame)) vs parent \(describe(parent.frame))")
                    } else if visible.map({ !inside(frame, $0) }) ?? true, let owner = clipOwner {
                        report(.clipped, path, frame, "\(describe(frame)) clipped by \(pathOf[ObjectIdentifier(owner)] ?? owner.name)")
                    }
                }
                if visible != nil, frame.width * zoom < options.minHitSize || frame.height * zoom < options.minHitSize {
                    report(.tooSmall, path, frame, "\(describe(frame)) < \(options.minHitSize) pt")
                }
                if let visible { hitRects.append((path, visible, layer, widget, false)) }
            }
            if let label = widget as? Label, !label.text.isEmpty, visible != nil, label.effectiveFontSize * zoom < options.minTextSize {
                report(.smallText, path, frame, "\(label.effectiveFontSize * zoom) pt < \(options.minTextSize) pt")
            }
            if let button = widget as? Button, visible != nil, button.titleIsTruncated,
               (button.tooltip(at: frame.center) ?? "").isEmpty {
                report(.truncatedWithoutTooltip, path, frame, "\"\(button.title)\" in \(Int(frame.width)) pt")
            }
            let clipsHere = widget.clipsContent
            let childClip = clipsHere ? (intersection(frame, clip) ?? UIRect(x: frame.x, y: frame.y, width: 0, height: 0)) : clip
            let childScrolled = scrolled || widget.scrollsContent
            for item in widget.accessibilityItems where item.role.isInteractive {
                guard let shown = intersection(item.frame, childClip) else { continue }
                let itemPath = "\(path)/\(item.key)"
                if item.frame.width * zoom < options.minHitSize || item.frame.height * zoom < options.minHitSize {
                    report(.tooSmall, itemPath, item.frame, "\(describe(item.frame)) < \(options.minHitSize) pt")
                }
                hitRects.append((itemPath, shown, layer, widget, true))
            }
            for child in widget.children {
                visit(child, clip: childClip, scrolled: childScrolled, clipOwner: clipsHere ? widget : clipOwner, layer: layer)
            }
        }
        for child in root.children { visit(child, clip: viewport, scrolled: false, clipOwner: nil, layer: 0) }
        for overlay in overlays {
            layerCount += 1
            visit(overlay, clip: viewport, scrolled: false, clipOwner: nil, layer: layerCount)
        }

        if options.checks.contains(.overlap) {
            for i in hitRects.indices {
                let a = hitRects[i]
                for j in hitRects.indices where j > i {
                    let b = hitRects[j]
                    guard a.layer == b.layer, let shared = intersection(a.rect, b.rect),
                          shared.width > tolerance, shared.height > tolerance else { continue }
                    // A part and the widget drawing it, or a widget inside another, don't count.
                    if a.widget === b.widget && a.isItem != b.isItem { continue }
                    // A part drawn inside another part (a tab's close button, a row's disclosure toggle).
                    if a.widget === b.widget && (inside(a.rect, b.rect) || inside(b.rect, a.rect)) { continue }
                    if a.widget !== b.widget && (a.widget.isDescendant(of: b.widget) || b.widget.isDescendant(of: a.widget)) { continue }
                    report(.overlap, a.path, a.rect, "by \(describe(shared))", other: b.path)
                }
            }
        }
        return issues
    }
}
