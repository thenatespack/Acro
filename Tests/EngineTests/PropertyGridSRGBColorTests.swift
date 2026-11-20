import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EngineMeshBuild
@testable import EngineUI
@testable import EngineRendering

// Color fields that hold display (sRGB) values, as builder files do (`FieldHints.srgb`): the
// property grid's swatch shows them as they are and writes back what the picker shows, while
// plain color fields stay linear.

private struct PropertyGridSRGBColorTestsColors: Component, Equatable {
    static let componentName = "PropertyGridSRGBColorTests.Colors"
    static var fieldHints: [String: FieldHints] {
        ["linear": FieldHints(color: true), "display": FieldHints(color: true, srgb: true), "displayA": FieldHints(color: true, srgb: true)]
    }
    var linear = Vec3(0.5, 0.25, 0.1)
    var display = Vec3(0.5, 0.25, 0.1)
    var displayA = Vec4(0.5, 0.25, 0.1, 0.5)
}

@MainActor @Suite struct PropertyGridSRGBColorTests {
    @Test func srgbFieldsShowAndWriteDisplayValues() throws {
        let world = World()
        let e = world.spawn(PropertyGridSRGBColorTestsColors())
        let grid = PropertyGrid(world: world)
        grid.entity = e
        func swatch(_ field: String) throws -> ColorSwatch {
            try #require(grid.descendant(named: "\(PropertyGridSRGBColorTestsColors.componentName).\(field)") as? ColorSwatch)
        }
        let display = try swatch("display"), linear = try swatch("linear"), displayA = try swatch("displayA")
        #expect(display.color.r == 0.5 && display.color.g == 0.25 && display.color.b == 0.1, "shown as written")
        #expect(abs(linear.color.r - UIColor(linearRGB: Vec3(0.5, 0.25, 0.1)).r) < 1e-5 && linear.color.r > 0.7, "linear values are shown converted")
        #expect(displayA.color.a == 0.5)

        // Picking a color writes the picker's (display) values to an sRGB field, linear ones to the other.
        for swatch in [display, linear] {
            let picked = UIColor(0.2, 0.4, 0.6)
            swatch.onEditBegan?(swatch.color)
            swatch.onChange?(picked)
            swatch.onEditEnded?(swatch.color, picked)
        }
        let colors = try #require(world.get(PropertyGridSRGBColorTestsColors.self, for: e))
        #expect(length(colors.display - Vec3(0.2, 0.4, 0.6)) < 1e-6)
        #expect(length(colors.linear - UIColor(0.2, 0.4, 0.6).linearRGB) < 1e-6)
    }

    /// The builders' sRGB color fields say so (their files and importers treat them as display colors).
    @Test func builderColorFieldsAreMarkedSRGB() {
        #expect(MeshBuildPart.fieldHints["color"]?.srgb == true && MeshBuildPart.fieldHints["glow"]?.srgb == true)
        #expect(PathProfile.fieldHints["color"]?.srgb == true && PathProfile.fieldHints["glow"]?.srgb == true)
        #expect(TerrainLayer.fieldHints["color"]?.srgb == true)
        #expect(ProceduralTexture.fieldHints["colorA"]?.srgb == true)
        // Material colors stay linear.
        #expect(Decal.fieldHints["tint"]?.srgb != true)
    }
}
