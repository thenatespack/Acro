# Editor UI review (card #658)

A systematic pass over the editor's UI: every panel, the toolbar and status bar, menus, the
context menus, the delete dialog, the inspector with every Add Component type, the asset
inspector per asset type (glTF model, texture, material, prefab), the Activity and Stats
panels, play mode, a floating and a squeezed panel, empty states (no project, nothing
selected) and busy ones (a 166-character entity name, 300 entities, long console lines, a long
"Undo AI: …" title), at 800x600, 1280x720, 2560x1440, 2560x600 and 800x1400 points, at UI
zoom 0.85 / 1 / 2, in all four themes, on Metal with spot checks on Vulkan.

## Method

- **A real window over MCP.** `Evals/ui-audit.py` launches the debug editor per configuration
  (`EDITOR_WINDOW_SIZE`, `EDITOR_UI_SCALE`, `EDITOR_THEME`, a fresh prefs folder and workspace),
  drives it through 23 states with MCP tools (`entity.create`, `edit.batch`, `component.add`,
  `ui.click` on menus and tree rows, `ui.key`, `play.*`, `panel.dock`, `project.new`,
  `asset.import`, `asset.select`…), checks each `ui.snapshot` for interactive elements outside
  the window, cut off by their panel, overlapping each other or smaller than 12 pt, and saves a
  window screenshot of each state. About 600 states were captured over the runs before and after
  the fixes; the screenshots were read one by one.
- **Headless.** `UIContext.layoutAudit()` (new, `Sources/Engine/UI/Widgets/UILayoutAudit.swift`)
  runs the same geometry checks on the widget tree, plus text under 9 pt (after the zoom) and
  button titles cut off without a tooltip. `Tests/EditorTests/EditorLayoutTests.swift` lays the
  editor out at the five sizes × backing 1x/2x × the smallest, default and largest zoom, walks
  the busy states at small and large sizes and in every theme, and fails on any finding.
- **Contrast.** WCAG 2 contrast ratios of every theme's text colors against its panel, field,
  control and popup backgrounds, white (accent) text on the accent in each state, selected rows,
  axis prefixes and editor-specific colors (`UIColor.contrastRatio(with:)`; the test checks them).
- **Backing scale.** This machine's display is 1x (3440x1440), so windowed screenshots are 1x;
  2x backing was covered headless (layout snaps to the 2x pixel grid) and by zoom 2, which
  draws the same number of pixels per point.
- **Vulkan.** The same states at 1280x720 with `--backend vulkan` look the same as Metal (see
  Results). The UI demo scenes render identically on both (`Scripts/render-scenes.sh`).

## Findings

Severity: **high** = something can't be reached or read; **medium** = hard to read or use, or
fails WCAG AA; **low** = cosmetic or polish. "Fixed" ones are fixed in this change.

| # | View | Size / scale / theme | Problem | Severity | Screenshot | Status |
|---|---|---|---|---|---|---|
| 1 | Toolbar | every width under ~1410 pt, incl. 1280x720 | One row of 22 controls: Reset Layout off the right edge at 1280; at 800x600 Move, Rotate, Scale, the project path, Open / New Project and Reset Layout unreachable. A long "Undo AI: Set Transform.position on …" title pushed everything further. | high | | Fixed: the path fields give way first, then the toolbar wraps onto more rows (one row at the 1440x900 default as before, two at 1280, three at 800); Undo / Redo stop at 220 pt with "…" and the full title in the tooltip |
| 2 | Dock, floating panel | any | Floating the inspector while it shows a tall component list made the dock as tall as that list (~8000 pt): the bottom tab group and status bar went below the window and the viewport stretched. `DockSpace` measured its floating windows' content. | high | [before](ui-review/before-floating-inspector-stretches-dock.png) | Fixed (`DockSpace.measureContent` counts docked panels only) |
| 3 | Add Component / any popup menu | 1280x720 at zoom 2 (888x500 pt), Game theme at 1280x720 | A menu taller than the window ran off its bottom; the last components couldn't be clicked. | high | | Fixed: `PopupMenu` is cut to fit and scrolls (wheel, keys; `ui.click` reveals items) |
| 4 | Any panel | narrow panels, zoom 2 | Panel content wider than the panel painted over the neighbouring panel (the asset toolbar over the inspector). | high | [before](ui-review/before-2x-zoom-panels-crushed.png) | Fixed: `TabView` clips its content |
| 5 | Hierarchy, Assets, Activity button bars; prefab rows | 800x600, zoom ≥ 1.5, narrow panels | Buttons past the panel edge (Delete, New Folder, New Material, Rename, List) were cut off or unreachable. | high | [before](ui-review/before-2x-zoom-panels-crushed.png) | Fixed: these bars wrap |
| 6 | Whole editor | 800x600 and 1280x720 at zoom 2 (400x300 and 640x360 pt) | Panels crushed to slivers, tabs reduced to "As…", the viewport a strip; at 800x600 the viewport ~180x60. | high | [before](ui-review/before-2x-zoom-panels-crushed.png) | Fixed: a zoom above 100% gives way so the UI keeps 800x500 pt (`EditorApp.fittedUIScale`) |
| 7 | Inspector vector fields | 800x600 and any inspector under ~300 pt | X/Y/Z fields 26 pt wide: "X.", "1.00(" — digits cut mid-glyph; 4-component colors unreadable. | medium | [before](ui-review/before-800x600-inspector.png), [after](ui-review/after-800x600-inspector.png) | Fixed: the label column gives way (to 56 pt, ellipsized with tooltip) before editors go under 32 pt per component; inspector minimum width 240 pt |
| 8 | Number fields | narrow | Values were clipped without any sign ("1.000" → "1.00"). | medium | | Fixed: fewer decimals first ("1.0", "1"), then "…"; the exact value is the tooltip |
| 9 | Stats panel | 1280x720 and smaller | The last lines cut off at the panel bottom; not scrollable. | medium | | Fixed: it scrolls |
| 10 | Toolbar time scale | all themes | Fixed 64 pt width: "0.25×" cut; just "…" in the Game theme. | medium | | Fixed: natural width |
| 11 | Primary buttons (Play/Stop, Move, Game, Delete, Apply) | Dark | White on the accent 0x3478f6 = 4.07:1, hover 3.5:1 (< 4.5). | medium | | Fixed: accent 0x2a66dc (5.2:1), hover 0x2f6fe6 (4.6:1), pressed 0x2458c2 (6.5:1) |
| 12 | Placeholder text | Dark, Light | 3.7:1 (Dark) and 3.1:1 (Light) on fields. | medium | | Fixed: 0x7e879a (4.9:1), 0x687083 (5.0:1) |
| 13 | Console warnings / errors | Light | Colors made for the dark theme: 1.8:1 and 2.6:1 on the light panel. | medium | [before](ui-review/before-light-console-colors.png), [after](ui-review/after-light-zoomed-console.png) | Fixed: `UITheme.warningTextColor` / `errorTextColor` per theme |
| 14 | Vector axis prefixes (X Y Z W) | Light | 2.5–3.9:1 on white fields. | medium | [before](ui-review/before-light-console-colors.png) | Fixed: `UITheme.axisColors` per theme (Light ≥ 4.8:1) |
| 15 | Selected row (focused) | High Contrast | White text on yellow at 55% = 4.46:1. | medium | | Fixed: 45% (6.2:1) |
| 16 | Light primary button hover | Light | 4.25:1. | medium | | Fixed: 0x316cec (4.7:1) |
| 17 | Status bar "AI acting" | Dark | Accent as 11-pt text on the panel: 4.0:1. | medium | | Fixed: the accent lifted toward the text color (5.8:1) |
| 18 | UI zoom | zoom ≠ 1 | The editor had no zoom setting; with `ui.uiScale` set, viewport hover, picking, gizmos and Game View input used unzoomed mouse coordinates, the viewport target was rendered at the unzoomed size, and the asset drag badge was drawn unzoomed. | medium | | Fixed: prefs `uiScale` (0.85–2) and `theme`, `EDITOR_UI_SCALE` / `EDITOR_THEME`; mouse mapped by the zoom; target sized with `ui.scale` |
| 19 | Lists, trees, menus | Game theme | 22-pt rows with 18-pt text: rows crowd and clip descenders. | medium | | Fixed: Game rows 30 pt, indent 20 |
| 20 | Toolbar separators | all | Measured 0 pt tall in the row, so never drawn. | low | | Fixed: 18-pt rules |
| 21 | Asset inspector | all | The texture setting "sRGB" titled "S RGB". | low | | Fixed |
| 22 | Panel gaps | Light, High Contrast, Game | The dividers between panels were near-black in every theme: the dock builds its splits before it joins the UI, so they took the default theme's field color. | low | [before](ui-review/before-light-console-colors.png) | Fixed in the editor (it sets the dock's `gapColor` from its theme); the engine-side cause is open (#32) |
| 23 | OS window | any | No minimum window size: below ~640x420 pt the panels' minimum sizes no longer fit and are scaled down together; the toolbar takes four rows. | medium | | Needs a decision (platform API) |
| 24 | Hit targets | all | Tab close buttons and tree disclosure triangles are 16 pt, checkboxes 16 pt: above the audit's 12-pt floor but under WCAG 2.2's 24x24 target size. | medium | | Needs a decision |
| 25 | Disabled controls | Dark, Light, Game | Disabled text 2.2–2.7:1 (exempt from WCAG, but hard to read: Undo, Redo, Pause, Step at rest). | low | | Needs a decision |
| 26 | Selected rows | Dark | Secondary text on a focused selected row 2.75:1. | low | | Needs a decision |
| 27 | Toolbar density | all | Wrapping keeps everything reachable but the toolbar takes 2 rows at 1280 and 3 at 800 (68–100 pt). | low | | Needs a decision (menus / overflow / icons) |
| 28 | Inspector name field | long names | Shows the end of a long name (caret at the end) rather than the start. | low | | Needs a decision |
| 29 | Game theme in the editor | Game | Disabled buttons are light gray with light text; the Game preset isn't designed for tool UI. | low | | Needs a decision (offer it in the editor or not) |
| 30 | Viewport caption | all | The "Perspective · Move" badge sits over scene labels (e.g. "Sun"). | low | | Not fixed (cosmetic) |
| 31 | 4-component fields at the minimum inspector width | 800x600 | Clear Color shows whole numbers ("0", "1"); exact values only in the tooltip. | low | [after](ui-review/after-800x600-inspector.png) | Accepted with the fix to #7 |
| 32 | `DockSpace` | any non-default theme; 800x600 | Splits built while the dock isn't in a context take `UITheme()`'s divider color and keep it. Floating windows may hang below the dock (only their tab bar is kept inside): at 800x600 the floating inspector's Add Component was below the window until the window was moved. | low | | Needs a decision (re-theme on attach; keep floating windows fully inside when they fit) |
| 33 | Assets panel | Game theme at zoom 2 (888x500 pt) | The asset toolbar's 44-pt controls wrap to three rows, taller than the short Assets panel: Rename, Delete and List end up below the window. Panel content doesn't scroll. | low | | Needs a decision (scrolling panel content, or a compact toolbar) |
| 34 | Inspector vector fields | 1280x720 | Fields of one vector can show different decimals ("X 1.00", "Y 2.0") since each drops what doesn't fit on its own. | low | | Needs a decision (a shared precision per vector) |

Counts: 6 high, 15 medium (2 of them need a decision), 13 low. Fixed: 22 (all high,
13 medium, 3 low).

## What was fixed

- **Engine widgets (additive APIs):** `Stack.wraps` (rows for horizontal stacks; shrinkable
  children count at their minimum, so they shrink before the row wraps); `Button`
  ellipsizes its title and shows it as the tooltip when cut (`titleIsTruncated`); `NumberField`
  drops decimals then ellipsizes, with the value as tooltip (`isTextShortened`), and takes axis
  colors from the theme (`prefixAxis`); `PopupMenu` cuts itself to the window and scrolls
  (`scrollOffset`, `scrollToReveal`); `TabView` clips its content; `DockSpace` sizes to its
  docked panels only; `PropertyGrid` lets the label column shrink to `minLabelWidth` before
  editors get too small. Theme: contrast fixes above, `warningTextColor`, `errorTextColor`,
  `axisColors`, Game `rowHeight` / `treeIndent`; `UIColor.relativeLuminance`, `contrastRatio`,
  `composited(over:)`. `UIContext.layoutAudit()`.
- **Editor:** wrapping toolbar and button bars, undo / redo title cap, toolbar rules, time scale
  width, scrolling Stats, inspector minimum width 240 pt, theme and zoom prefs
  (`EditorPrefs.theme` / `uiScale`, `EDITOR_THEME`, `EDITOR_UI_SCALE`), zoom that gives way in
  small windows, zoom-correct viewport input and render target, theme-colored console lines,
  status bar and panel gaps (`dock.gapColor`); `EDITOR_WINDOW_SIZE` for reviews.
- **Tools:** `Evals/ui-audit.py` (windowed review over MCP), `EditorLayoutTests` (headless),
  `UILayoutFitTests` (the widget behaviors).

## Results

- `EditorLayoutTests`: the default layout at 5 sizes × 2 backing scales × 3 zooms, the busy
  states at 800x600, 800x600 2x zoomed, 2560x1440 at the smallest zoom, 2560x600 and 800x1400,
  and every theme at 1280x720 and 800x600: no findings. Theme contrast: every text pair ≥ 4.5:1.
- `Evals/ui-audit.py` after the fixes (23 states each at 800x600, 1280x720, 2560x1440 and
  2560x600, at 1280x720 zoom 2 in all four themes, and on Vulkan): no geometry findings except
  #32 (a floating window placed partly below an 800x600 window) and #33 (Game theme at zoom 2).
- Vulkan (`--backend vulkan`, 1280x720, Dark, the same 23 states): pixel-identical to Metal in
  the default and empty states; the others differ only where text changes between runs (frame
  times, entity ids, console timestamps; 0.1–0.5% of pixels).
- UI demo scenes (`SCENES="ui widgets docking inspector viewports gizmos hud"
  Scripts/render-scenes.sh high`): Metal and Vulkan identical. Against the images before this
  change: ui, viewports and gizmos are unchanged; widgets (1.6% of pixels), docking (0.2%),
  inspector (0.02%) and hud (< 0.01%) differ by the darker Dark accent (#11: primary buttons,
  checked boxes, slider fills, the highlighted menu item) and the lighter placeholder (#12).

## Remaining issues that need a decision

1. **Minimum window size** (#23): set one in the platform layer (`NSWindow.contentMinSize`,
   `glfwSetWindowSizeLimits`), e.g. 800x500 points, or let the editor collapse side panels.
2. **Hit target size** (#24): grow tab close buttons, disclosure triangles and checkboxes to
   24 pt (WCAG 2.2 AA), or accept 16 pt as desktop-tool density.
3. **Disabled and secondary-on-selection contrast** (#25, #26): raise disabled text toward 3:1,
   or keep the dim look; pick a secondary color for selected rows.
4. **Toolbar structure** (#27): a File menu and an overflow menu, or icon buttons, instead of
   22 labeled controls in a wrapping strip.
5. **Name field scroll position** (#28): show the start of a long name when not editing.
6. **Theme choice in the editor** (#29): whether Game (and Light / High Contrast) should be
   offered in a settings UI; today they are prefs / environment only.
7. **Viewport caption placement** (#30).
8. **Dock theming and floating windows** (#32): re-color splits when the dock joins a context or
   the theme changes; keep floating windows fully inside the dock when they fit.
9. **Panel content that doesn't fit** (#33): let panels scroll their whole content, or give the
   asset browser a compact toolbar for large themes and zooms.
10. **Vector precision** (#34): one precision for all fields of a vector.
