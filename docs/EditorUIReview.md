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
| 23 | OS window | any | No minimum window size: below ~640x420 pt the panels' minimum sizes no longer fit and are scaled down together; the toolbar takes four rows. | medium | | Fixed in #661 (see the re-review below) |
| 24 | Hit targets | all | Tab close buttons and tree disclosure triangles are 16 pt, checkboxes 16 pt: above the audit's 12-pt floor but under WCAG 2.2's 24x24 target size. | medium | | Fixed in #661 (see the re-review below) |
| 25 | Disabled controls | Dark, Light, Game | Disabled text 2.2–2.7:1 (exempt from WCAG, but hard to read: Undo, Redo, Pause, Step at rest). | low | | Fixed in #661 (see the re-review below) |
| 26 | Selected rows | Dark | Secondary text on a focused selected row 2.75:1. | low | | Fixed in #661 (see the re-review below) |
| 27 | Toolbar density | all | Wrapping keeps everything reachable but the toolbar takes 2 rows at 1280 and 3 at 800 (68–100 pt). | low | | Decided in #659: icon-only toolbar buttons (titles kept as labels, tooltips), one row at 1280 and 800; wraps narrower or with Build / Reload Game shown |
| 28 | Inspector name field | long names | Shows the end of a long name (caret at the end) rather than the start. | low | | Fixed in #661 (see the re-review below) |
| 29 | Game theme in the editor | Game | Disabled buttons are light gray with light text; the Game preset isn't designed for tool UI. | low | | Fixed in #661 (see the re-review below) |
| 30 | Viewport caption | all | The "Perspective · Move" badge sits over scene labels (e.g. "Sun"). | low | | Fixed in #661 (see the re-review below) |
| 31 | 4-component fields at the minimum inspector width | 800x600 | Clear Color shows whole numbers ("0", "1"); exact values only in the tooltip. | low | [after](ui-review/after-800x600-inspector.png) | Accepted with the fix to #7 |
| 32 | `DockSpace` | any non-default theme; 800x600 | Splits built while the dock isn't in a context take `UITheme()`'s divider color and keep it. Floating windows may hang below the dock (only their tab bar is kept inside): at 800x600 the floating inspector's Add Component was below the window until the window was moved. | low | | Fixed in #661 (see the re-review below) |
| 33 | Assets panel | Game theme at zoom 2 (888x500 pt) | The asset toolbar's 44-pt controls wrap to three rows, taller than the short Assets panel: Rename, Delete and List end up below the window. Panel content doesn't scroll. | low | | Fixed in #661 (see the re-review below) |
| 34 | Inspector vector fields | 1280x720 | Fields of one vector can show different decimals ("X 1.00", "Y 2.0") since each drops what doesn't fit on its own. | low | | Fixed in #661 (see the re-review below) |

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

All ten were decided in cards #659 (#27) and #661 (the rest); see "Follow-ups (#661): what was
decided" below. What still needs the user is listed at the end of this document.

# Re-review after icons (cards #660 and #661)

Card #659 put icons everywhere (Lucide glyphs through `VectorIcon` / `IconView`, an icon-only
toolbar, viewport billboards) and #666 added prefab-variant rows to the inspector. This pass
repeated the review on that build, judged the icons specifically, and implemented the open
decisions of the first review (#661).

## Method

The same tools as above, plus:

- `Evals/ui-audit.py` gained two states: **prefab-variant** (an overridden prefab instance turned
  into a variant, its inspector rows) and **mesh-kinds** (cube, sphere and plane entities next
  to a prefab instance). 25 states per configuration; the baseline (before this change) and the
  final run each covered 800x600, 1280x720, 2560x1440, 2560x600 and 800x1400 in Dark, and
  1280x720 at zoom 0.85 and 2 in all four themes: 13 configurations, 325 states and
  screenshots per run. The screenshots were read one by one.
- **Real 2x backing.** This machine now has a Retina display (built-in, 2560x1664): every
  windowed screenshot is 2x (an 800x600-point window is 1600x1200 pixels), so text and icon
  crispness at 2x was judged on real windows, not only headless.
- **Icons.** Recognisability and ambiguity by eye in every state; consistent weight (Lucide's
  2-unit stroke at 24 units, so 1.33 px at 16 pt); alignment with the text (row icons centered
  on the row, toolbar icons on the button, tab icons on the title); crispness at 1x, 2x and
  the zooms (icons are rasterized per pixel size onto whole pixels: `drawListRasterizesPerPixelSize`);
  glyph contrast (WCAG 1.4.11, 3:1) of every icon tint against what it is drawn on, in every
  theme, including billboards over white, black and sky-blue scene content
  (`EditorIconTests.iconGlyphsHaveContrastInEveryTheme`).
- **Vulkan.** The UI demo scenes on Metal and Vulkan (identical), and the editor at 1280x720
  with `--backend vulkan`.

## Findings

Severity as above. R = re-review; #n = the first review's numbers where the item was known.

| # | View | Size / scale / theme | Problem | Severity | Screenshot | Status |
|---|---|---|---|---|---|---|
| R1 | Hierarchy, inspector header, Create menu | all | Every mesh entity had the cube icon: Blue Sphere, the Hub, a plane, imported models. | medium | [before](ui-review/icons-before.png), [after](ui-review/icons-after.png) | Fixed: icons by mesh shape (`EditorIcons.meshIconName`): cube, sphere, plane, cylinder / capsule, and a subdivided triangle for any other mesh (imported, game-registered) |
| R2 | Hierarchy, inspector, asset browser | all | Prefab instances and `.prefab` files used Lucide's `package`, a box with a ribbon: at 16 px the silhouette of the mesh cube, told apart only by the accent tint (color alone, WCAG 1.4.1). | medium | | Fixed: a prefab mark (four diamonds, the "component instance" sign of design tools) for instances and files; still accent-tinted |
| R3 | Viewport name labels | bright scenes (the starter scene's sky) | "Sun" in yellow on the light sky, about 1.4:1; white camera names likewise. | medium | [before](ui-review/icons-before.png), [after](ui-review/icons-after.png) | Fixed: labels over a dark drop shadow (`DebugDraw.text(shadow:)`) |
| R4 | Viewport caption (#30) | all | The "Perspective · Move" badge sat over the Sun label and billboard. | low | [before](ui-review/icons-before.png), [after](ui-review/icons-after.png) | Fixed: the caption is in the Scene panel's tab bar (`DockPanel.caption`); the badge only appears when the bar has no room |
| R5 | Asset browser folder icons | Light | Amber 0xd9a646 on the light panel: 2.0:1. | medium | | Fixed: icon tints (folders, prefabs) are lifted toward the text color until 3:1 on the panel (`EditorIcons.readable`) |
| R6 | Selected asset cells, sub-asset names, tree arrows (#26) | Dark, Light, Game | Secondary color on a focused selection: 2.6–3.7:1. | low | | Fixed: the text color on selections (5.9–9.7:1) |
| R7 | Disabled buttons, checkboxes, dropdowns, fields (#29) | Game | Light gray: the theme's translucent white fill (alpha 0.08) was given alpha 0.5 (`withAlpha` replaces alpha). | medium | [before](ui-review/game-disabled-before.png), [after](ui-review/game-disabled-after.png) | Fixed: `UIColor.fading` multiplies alpha (opaque themes draw exactly as before) |
| R8 | Disabled text and toolbar icons (#25) | Dark, Light | 2.2–2.7:1 (Undo, Redo, Pause, Step at rest). | low | | Fixed: Dark 0x767f92 (3.2–4.4:1), Light 0x848b99 (3.1–3.4:1); HC 6.3, Game 3.2–3.9 unchanged |
| R9 | Toolbar document title | 800 pt | "U…" (known from #659). | low | | Fixed: it hides below 64 pt (`Label.minimumTruncatedWidth`); the OS window title and the label's tooltip still name the document |
| R10 | Scene path field, inspector name field (#28) | any | The path field showed ";cene.json" (scrolled a pixel, its first glyph cut); a long name showed its end. | low | | Fixed: an idle `TextField` shows its start, ellipsized, with the whole text as tooltip; editing scrolls to the caret as before |
| R11 | Inspector labels | default width | "Receives Shad…" (known from #659). | low | | Fixed: inspector label column 120 pt (was 104); in a narrow inspector rows with wide editors still shrink it first |
| R12 | Inspector (#33) | Game, 1280x720 at zoom 2 | The prefab variant rows filled the inspector and pushed Add Component below the window (the baseline audit's only geometry finding). | medium | | Fixed: panel content taller than the panel scrolls (`TabView.contentOverflow`) |
| R13 | Inspector | any | Selecting the already-selected entity (its hierarchy row, `selection.set`) while an asset was in the inspector kept showing the asset. | low | | Fixed: selecting entities always brings the entity back |
| R14 | Toolbar | Game at zoom 2; 800 pt with a project open | Wraps onto a second row (the Build Game button, or the Game theme's 44-pt controls). | low | | Accepted (#659's decision: wrap rather than hide); Game isn't offered in the View menu |
| R15 | Tab close buttons, disclosure triangles, checkboxes (#24) | all | 16-pt targets (WCAG 2.2 asks 24). | medium | | Fixed (see #661 below) |
| R16 | OS window (#23) | any | No minimum size. | medium | | Fixed: 800x500 |
| R17 | Vector fields (#34) | narrow inspectors | "X 1.00  Y 2.0" in one vector. | low | | Fixed: one precision per vector |
| R18 | Dock (#32) | non-default themes; 800x600 | Splits kept the default theme's divider color (the editor worked around it); floating windows could hang below the dock. | low | | Fixed in the engine; the workaround is gone |
| R19 | Theme choice (#29) | — | Themes only through prefs and `EDITOR_THEME`. | low | | Fixed: View menu |
| R20 | Empty text fields | narrow (High Contrast at zoom 2) | A placeholder wider than its field was cut mid-glyph ("path/to/proje"). | low | | Fixed: ellipsized like the text |
| R21 | Asset browser | any | A prefab variant's cell has an empty thumbnail (the base prefab's renders). | low | | Open (thumbnails, not UI layout) |

Checked and fine, no change: icon recognisability elsewhere (lights, cameras, audio, particles,
physics, log levels, panels, asset kinds, toolbar actions with their tooltips); stroke weight is
the same everywhere (all icons share Lucide's 2-unit stroke; the High Contrast and Game themes
draw their own lines thicker, icons keep the glyph); icons are centered on rows, buttons and tab
titles at every zoom; crisp at 1x, real 2x and zoom 0.85 / 1.44 / 2; billboards (a 72% dark disc
with a light rim) read over the bright sky and the dark ground, each tint ≥ 3:1 over white,
black and sky blue; the thumbnail kind badges (light glyph on a 60% black disc) ≥ 5:1; selected
tab icons (accent mixed with the text) ≥ 3:1 in every theme.

Counts: 21 findings (0 high, 8 medium, 13 low). Fixed: 19; accepted: 1 (R14); open: 1 (R21). Of the first
review's 12 open items (#23–#34 that needed a decision), all are decided and implemented here
except #27 (decided in #659) and #31 (accepted then).

## Follow-ups (#661): what was decided

- **Minimum window size (#23):** `EngineConfig.minimumWindowSize` (additive; `NSWindow.contentMinSize`
  on AppKit, `glfwSetWindowSizeLimits` on GLFW, in points / screen coordinates); a smaller
  requested size opens at the minimum (`openingWindowSize`). The editor uses
  `EditorApp.minimumWindowSize`, 800x500: the default layout's panel minimums plus a one-row
  toolbar fit at 100%, and it is also the smallest UI a zoom may leave (`minimumZoomedUISize`).
  Collapsing side panels was not needed.
- **Hit targets (#24):** `UITheme.minimumHitSize` (24 pt). Tab close buttons take clicks over
  24x24 around the 16-pt cross (the hover highlight stays small); disclosure triangles over 24 pt
  wide around the arrow, reaching into the indentation; untitled checkboxes are 24 pt wide (the
  box stays 16 at the left). A disclosure triangle can only be 24 tall if its row is, so
  `rowHeight` went from 22 to 24 in Dark, Light and High Contrast (Game was already 30): about
  8% fewer rows in a full hierarchy, in exchange for meeting WCAG 2.2's 2.5.8 without relying on
  its spacing exception.
- **Contrast (#25, #26):** disabled text ≥ 3:1 on every surface in every theme (WCAG exempts
  inactive controls from 4.5:1, so it stays visibly dimmer than secondary text); on a
  selection, secondary elements switch to the text color instead of getting a new theme color.
- **Name field (#28):** `TextField` shows the start of its text whenever it isn't focused; the
  caret position is kept for editing.
- **Theme picker (#29):** the toolbar's last button is now a **View** menu: Reset Layout, Dark /
  Light / High Contrast Theme and Zoom 85 / 100 / 125 / 150 / 200%, current choices checked
  (`PopupMenu.checkedIndices`). It runs `view.appearance {theme?, uiScale?}`, a new MCP tool that
  restyles the running editor and saves the prefs. Reset Layout moved into the menu so the
  toolbar stays one row at 800 pt. **Game is not offered** in the menu: it is a preset for game
  HUDs and menus (44-pt controls, 18-pt text, translucent panels) and makes a dense tool UI wrap
  and truncate everywhere; its disabled-control bug (R7) is fixed regardless, and
  `view.appearance`, the prefs and `EDITOR_THEME` still accept it for previewing a game's UI.
- **Viewport caption (#30):** in the tab bar (R4).
- **Dock (#32):** `SplitView.dividerUsesThemeColor`: the dock's gaps take the theme's field
  color when drawn (theme changes included), so `EditorApp` no longer sets `gapColor`. Floating
  windows are drawn wholly inside the dock and no larger than it; the stored frame is kept, so a
  window placed in a larger window goes back when there is room; moving one keeps it inside.
- **Panel content that doesn't fit (#33):** `TabView` lays content that runs past the panel's
  bottom (anywhere in it except inside scroll views) out at its full height and scrolls it with
  the wheel (`contentOverflow`, `contentOffset`, `scrollToReveal`, a scroll indicator), clipped
  below the tab bar. The layout audit, `ui.snapshot`'s on-screen flags and `ui-audit.py` treat
  such panels as scrolling. (With icon-only buttons the Assets toolbar no longer overflows at
  1280x720 zoom 2; the inspector with prefab-variant rows did, R12.)
- **Vector precision (#34):** `VectorField` caps every component at the fewest decimals any of
  them fits with (`NumberField.decimalsLimit`, `decimalsThatFit`, `shownText`); a component
  shortened to match shows its exact value as the tooltip. Different vectors may still differ
  (Position "0.0", Scale "1.00").
- **2x backing:** verified on a real Retina window (see Method); headless 2x tests still run.

## Results

- **Audit (`Evals/ui-audit.py`), baseline:** 1 geometry finding in 325 states (R12). **After:**
  0 findings in 325 states (13 configurations), and 0 in the final Metal and Vulkan runs at
  1280x720 (25 states each).
- **Tests:** `EditorLayoutTests` (minimum window, 24-pt targets including a click at the edge of
  the larger area, floating windows on screen, View menu theme and zoom switching at runtime,
  inspector overflow scrolling, caption, title, name field, reselecting an entity, disabled
  contrast ≥ 3:1), `EditorIconTests` (editor icons parse and draw, mesh and prefab icons differ
  in more than half their ink, glyph contrast in every theme), `UILayoutFitTests` (shared
  decimals, hit targets, idle text fields, overflow scrolling, dock dividers, floating windows,
  label hiding, caption, multi-check menus, `fading`); with UIThemeTests, InspectorWidgetTests,
  DockingTests, WidgetTests, UIIntrospectionTests, ParityTests (the View menu and its items map
  to `view.appearance` / `layout.reset`), EditorTests, EditorTooltipTests, ToolReferenceTests:
  all pass. Linux (Docker): UILayoutFitTests, DockingTests and WidgetTests pass with the GLFW
  change.
- **UI demo scenes** (`SCENES="ui widgets docking inspector viewports gizmos hud"
  Scripts/render-scenes.sh high`): Metal and Vulkan identical. Against the images before this
  change: ui, viewports and gizmos unchanged; widgets (3.1% of pixels), inspector (3.1%),
  docking (0.9%) and hud (0.07%) differ on purpose: 24-pt rows in trees, lists and dropdown
  menus (the rest of a panel moves down), the lighter disabled text (#25), the text-colored
  disclosure arrow on the selected row (#26) and 24-pt-wide untitled checkboxes.
- **Vulkan editor spot check** (1280x720, Dark, all 25 states, `--backend vulkan`): no
  findings; pixel-identical to Metal in the default and empty states, the rest differ only where
  text changes between runs (entity ids, frame times; 0.2–0.7% of pixels).

## Remaining issues that need the user's decision

1. **Game theme in the editor:** hidden from the View menu but accepted by `view.appearance`,
   the prefs and `EDITOR_THEME`. Drop it from the editor entirely, or keep it as a preview?
2. **24-pt rows:** chosen for WCAG 2.2 target size; 22 pt (denser, ~8% more rows) would need
   the spacing exception instead.
3. **Prefab mark:** four diamonds (design tools' instance sign) rather than a tinted cube
   (Unity's). Fine, or prefer a cube with a link badge?
4. **Toolbar at 800 pt with a project open** wraps the View button onto a second row (R14): an
   overflow ("…") menu for the project group would keep one row.
5. **Prefab variant thumbnails** (R21), and whether the asset browser should drop its
   highlight when the inspector goes back to an entity (today the cell stays selected).

## Decisions on the remaining issues (follow-up)

The user decided the five items above:

1. **Game theme: removed from the editor.** `EditorApp.themes` is Dark, Light and High
   Contrast. `view.appearance` refuses Game with a message naming them; prefs or `EDITOR_THEME`
   that say Game (allowed before) start in Dark and log one warning. Game stays an engine
   preset for game HUDs (the `hud` demo is unchanged).
2. **24-pt rows: kept.**
3. **Four-diamond prefab mark: kept.**
4. **Toolbar overflow menu.** The toolbar is one row at any width (`ToolbarRow`): when it
   doesn't fit, buttons leave it least-used first (New / Open Project, Save As, New, Open,
   Snap, Step, Redo, Game View, Pause, Undo, Save, the tools; Build / Reload Game and Play
   last) into a More (») menu at its end, with their icons and commands. Overflowed buttons
   stay in `ui.snapshot` as `editorRoot/toolbar/overflow:<name>` items (label, command,
   enabled state) on the More button, and `ui.click` on one opens the menu and clicks its entry.
   At 800x600 with a project open the toolbar is one row with Build Game in it
   (`EditorLayoutTests.toolbarOverflowsIntoAMoreMenu`); at 1440 nothing overflows.
5. **Prefab variant thumbnails** are rendered from the variant's resolved template (its base
   with its overrides), like its instances (`AssetThumbnails.spawnPrefab`), and remade when
   the variant or any base in its chain changes.
6. **Asset highlight.** When the inspector goes back to an entity (or the asset goes away),
   the asset browser drops its selected cell.

`Evals/ui-audit.py` at 800x600 and 1280x720 after these changes (Dark and Light, 25 states each): 0 findings in 100 states. The UI demo scenes are unchanged (Metal and Vulkan identical; `hud` too).
