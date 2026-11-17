import EditorCore
import Engine
import Foundation

// `meshBuild.examples`: a few small, correct mesh builds to copy from. Each one stands on y = 0,
// faces -Z, has every part touching another and gives no warnings (MeshBuildToolsTests checks).

/// A ready-made mesh build and what it shows.
public struct MeshBuildExample: Codable, Equatable, Sendable {
    public var name: String
    /// What it demonstrates.
    public var about: String
    public var build: MeshBuild
}

public enum MeshBuildExamples {
    /// The examples bake ambient occlusion (`"ao": true`; it is off by default): they are
    /// finished props, and the builds agents copy should show the switch.
    public static var all: [MeshBuildExample] {
        let examples = [streetLamp, cart, turret, crate, bench, armchair, stoneArch, teapot, mossyStone, sailboat, gnarledTree, deskLamp]
            + plants  // MeshBuildExamples+Plants.swift
        return examples.map { example in
            var example = example
            if example.build.ao == nil { example.build.ao = true }
            return example
        }
    }

    /// Dark green-black paint for street furniture.
    static let lampPaint = Vec3(0.09, 0.13, 0.11)
    static let iron = Vec3(0.18, 0.19, 0.2)

    /// A pole on a foot with an arm reaching forward, a shade and a glowing bulb: a parent chain
    /// where each position is in the parent's space.
    public static var streetLamp: MeshBuildExample {
        MeshBuildExample(name: "Street Lamp", about: "3.8 m tall. A parent chain (Base > Pole > Arm > Shade > Bulb): each position is the part's center in its parent's space, so the pole's 1.9 is half its 3.6 m height above the foot's center. The arm reaches forward (-Z). Painted metal looks with wear (scuffed paint, grime) tinted dark green; the bulb glows.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Base", shape: .cylinder, position: Vec3(0, 0.1, 0), size: Vec3(0.4, 0.2, 0.4), color: lampPaint,
                          bevel: 0.03, look: "paintedMetal", wear: 0.6),
            MeshBuildPart(name: "Pole", shape: .cylinder, parent: "Base", position: Vec3(0, 1.9, 0), size: Vec3(0.12, 3.6, 0.12),
                          color: lampPaint, look: "paintedMetal", wear: 0.4),
            MeshBuildPart(name: "Arm", shape: .box, parent: "Pole", position: Vec3(0, 1.7, -0.3), size: Vec3(0.08, 0.08, 0.7),
                          color: lampPaint, look: "paintedMetal", wear: 0.4),
            MeshBuildPart(name: "Shade", shape: .cone, parent: "Arm", position: Vec3(0, -0.1, -0.3), size: Vec3(0.45, 0.3, 0.45),
                          color: Vec3(0.12, 0.3, 0.2), look: "paintedMetal", wear: 0.3),
            MeshBuildPart(name: "Bulb", shape: .sphere, parent: "Shade", position: Vec3(0, -0.15, 0), size: Vec3(0.18, 0.18, 0.18),
                          color: Vec3(1, 0.95, 0.8), glow: Vec3(1, 0.85, 0.55), glowStrength: 4),
        ]))
    }

    /// A wooden cart, 2 m long, front at -Z: wheels turned onto the X axle with rotation [0,0,90].
    public static var cart: MeshBuildExample {
        func wheel(_ name: String, _ x: Float, _ z: Float) -> MeshBuildPart {
            MeshBuildPart(name: name, shape: .cylinder, parent: "Bed", position: Vec3(x, -0.2, z), rotation: Vec3(0, 0, 90),
                          size: Vec3(0.8, 0.1, 0.8), color: Vec3(0.45, 0.33, 0.22), look: "wood", wear: 0.7)
        }
        func axle(_ name: String, _ z: Float) -> MeshBuildPart {
            MeshBuildPart(name: name, shape: .cylinder, parent: "Bed", position: Vec3(0, -0.2, z), rotation: Vec3(0, 0, 90),
                          size: Vec3(0.06, 1.3, 0.06), look: "rustyMetal")
        }
        return MeshBuildExample(name: "Wooden Cart", about: "2 m long, front (the shaft) at -Z. Cylinders run along Y, so wheels and axles on an axle along X use rotation [0,0,90]. The wheels' 0.8 m diameter puts their centers 0.4 m up and their bottoms on y=0; they touch the bed's sides. Planks and wood looks with wear, rusty axles. The Roll animation (autoplay off) spins the wheels about their own axis (motion axis y).", build: MeshBuild(parts: [
            MeshBuildPart(name: "Bed", shape: .box, position: Vec3(0, 0.6, 0), size: Vec3(1.2, 0.15, 2), look: "planks", wear: 0.5,
                          grain: .z),
            MeshBuildPart(name: "Side L", shape: .box, parent: "Bed", position: Vec3(-0.56, 0.25, 0), size: Vec3(0.08, 0.35, 2),
                          look: "planks", wear: 0.5),
            MeshBuildPart(name: "Side R", shape: .box, parent: "Bed", position: Vec3(0.56, 0.25, 0), size: Vec3(0.08, 0.35, 2),
                          look: "planks", wear: 0.5),
            MeshBuildPart(name: "Front", shape: .box, parent: "Bed", position: Vec3(0, 0.25, -0.96), size: Vec3(1.04, 0.35, 0.08),
                          look: "planks", wear: 0.5),
            MeshBuildPart(name: "Shaft", shape: .box, parent: "Bed", position: Vec3(0, -0.05, -1.45), size: Vec3(0.08, 0.08, 1),
                          look: "wood", wear: 0.5),
            axle("Front Axle", -0.6), axle("Back Axle", 0.6),
            wheel("Wheel FL", -0.65, -0.6), wheel("Wheel FR", 0.65, -0.6), wheel("Wheel BL", -0.65, 0.6), wheel("Wheel BR", 0.65, 0.6),
        ], animations: [
            MeshBuildAnimation(name: "Roll", autoplay: false, motions: ["Wheel FL", "Wheel FR", "Wheel BL", "Wheel BR"].map {
                MeshBuildMotion(part: $0, kind: .spin, axis: .y, period: 1.5)
            }),
        ]))
    }

    /// A small gun turret whose head sweeps from side to side on a group pivot.
    public static var turret: MeshBuildExample {
        let olive = Vec3(0.32, 0.36, 0.24), gunmetal = Vec3(0.25, 0.26, 0.28)
        return MeshBuildExample(name: "Turret", about: "1.2 m wide. A group part (Pivot) is a hinge with no mesh: the head hangs from it and the Scan animation swings the pivot 40 degrees each way about Y, so everything on it turns together. The barrel is a cylinder turned with rotation [90,0,0] to point forward (-Z); the muzzle is its child, so it inherits that rotation and sits at the barrel's local y=-0.5 end. Painted metal tinted olive with wear, a brushed steel barrel.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Base", shape: .cylinder, position: Vec3(0, 0.15, 0), size: Vec3(1.2, 0.3, 1.2), color: Vec3(0.3, 0.31, 0.32),
                          bevel: 0.03, look: "paintedMetal", wear: 0.7),
            MeshBuildPart(name: "Pivot", shape: .group, parent: "Base", position: Vec3(0, 0.15, 0)),
            MeshBuildPart(name: "Head", shape: .box, parent: "Pivot", position: Vec3(0, 0.25, 0), size: Vec3(0.8, 0.5, 0.9),
                          color: olive, bevel: 0.04, look: "paintedMetal", wear: 0.5),
            MeshBuildPart(name: "Barrel", shape: .cylinder, parent: "Head", position: Vec3(0, 0.05, -0.85), rotation: Vec3(90, 0, 0),
                          size: Vec3(0.12, 1, 0.12), color: gunmetal, look: "brushedMetal", wear: 0.3),
            MeshBuildPart(name: "Muzzle", shape: .cylinder, parent: "Barrel", position: Vec3(0, -0.5, 0), size: Vec3(0.18, 0.15, 0.18),
                          color: gunmetal, look: "brushedMetal", wear: 0.6),
            MeshBuildPart(name: "Sensor", shape: .sphere, parent: "Head", position: Vec3(0.25, 0.3, 0.1), size: Vec3(0.2, 0.2, 0.2),
                          color: Vec3(0.9, 0.1, 0.05), glow: Vec3(1, 0.1, 0.05), glowStrength: 3),
        ], animations: [
            MeshBuildAnimation(name: "Scan", motions: [MeshBuildMotion(part: "Pivot", kind: .swing, axis: .y, amount: 40, period: 4)]),
        ]))
    }

    /// A weathered wooden crate with rusty metal corner caps and bolts: looks, wear and mirror.
    public static var crate: MeshBuildExample {
        MeshBuildExample(name: "Weathered Crate", about: "0.8 m cube of worn planks with a batten across each side, rusty corner caps and bolts. One corner cap (with its two bolts as children) mirrored across x, y and z makes all eight; one batten mirrored across z covers the back. Looks: planks (grain along X), wood, rustyMetal; wear adds grime and darker creases, and the baked ambient occlusion darkens where parts meet.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Crate", shape: .box, position: Vec3(0, 0.41, 0), size: Vec3(0.8, 0.8, 0.8), look: "planks",
                          lookScale: 0.9, wear: 0.7, grain: .x),
            MeshBuildPart(name: "Batten Front", shape: .box, parent: "Crate", position: Vec3(0, 0, -0.415), size: Vec3(0.66, 0.1, 0.03),
                          color: Vec3(0.42, 0.3, 0.2), mirror: [.z], look: "wood", wear: 0.8),
            MeshBuildPart(name: "Batten Left", shape: .box, parent: "Crate", position: Vec3(-0.415, 0, 0), size: Vec3(0.03, 0.1, 0.66),
                          color: Vec3(0.42, 0.3, 0.2), mirror: [.x], look: "wood", wear: 0.8),
            MeshBuildPart(name: "Corner", shape: .box, parent: "Crate", position: Vec3(0.34, 0.34, -0.34), size: Vec3(0.14, 0.14, 0.14),
                          bevel: 0.006, mirror: [.x, .y, .z], look: "rustyMetal", wear: 0.5),
            MeshBuildPart(name: "Bolt Front", shape: .cylinder, parent: "Corner", position: Vec3(-0.02, -0.02, -0.0775),
                          rotation: Vec3(90, 0, 0), size: Vec3(0.03, 0.015, 0.03), segments: 12, look: "rustyMetal", wear: 0.8),
            MeshBuildPart(name: "Bolt Side", shape: .cylinder, parent: "Corner", position: Vec3(0.0775, -0.02, 0.02),
                          rotation: Vec3(0, 0, 90), size: Vec3(0.03, 0.015, 0.03), segments: 12, look: "rustyMetal", wear: 0.8),
        ]))
    }

    /// A park bench: wooden slats on painted iron ends, made with mirror and repeat.
    public static var bench: MeshBuildExample {
        let iron = Vec3(0.06, 0.07, 0.065)
        return MeshBuildExample(name: "Park Bench", about: "1.6 m wide, seat 0.47 m high, facing -Z. One iron end (front leg, back leg, seat rail, armrest) mirrored across x makes both; one seat slat repeated 4 times along z and one back slat 3 times up y. Looks: wood slats (grain along X by default: their longest side) with wear, paintedMetal tinted near-black for the iron, so scuffs and grime show.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Front Leg L", shape: .box, position: Vec3(-0.75, 0.34, -0.2), size: Vec3(0.06, 0.68, 0.06), color: iron,
                          mirror: [.x], look: "paintedMetal", wear: 0.5),
            MeshBuildPart(name: "Back Leg L", shape: .box, position: Vec3(-0.75, 0.425, 0.2), size: Vec3(0.06, 0.85, 0.06), color: iron,
                          mirror: [.x], look: "paintedMetal", wear: 0.5),
            MeshBuildPart(name: "Seat Rail L", shape: .box, position: Vec3(-0.75, 0.42, 0), size: Vec3(0.06, 0.06, 0.34), color: iron,
                          mirror: [.x], look: "paintedMetal", wear: 0.5),
            MeshBuildPart(name: "Arm L", shape: .box, position: Vec3(-0.75, 0.7, -0.05), size: Vec3(0.07, 0.04, 0.36), color: iron,
                          bevel: 0.01, mirror: [.x], look: "paintedMetal", wear: 0.6),
            MeshBuildPart(name: "Seat Slat", shape: .box, position: Vec3(0, 0.4675, -0.18), size: Vec3(1.56, 0.035, 0.09),
                          bevel: 0.006, repetition: MeshBuildRepeat(count: 4, offset: Vec3(0, 0, 0.12)), look: "wood", wear: 0.5),
            MeshBuildPart(name: "Back Slat", shape: .box, position: Vec3(0, 0.58, 0.155), size: Vec3(1.56, 0.09, 0.03),
                          bevel: 0.006, repetition: MeshBuildRepeat(count: 3, offset: Vec3(0, 0.11, 0)), look: "wood", wear: 0.5),
        ]))
    }
}

// MARK: Sculpts

extension MeshBuildPart {
    /// This part with its sculpt fields set (for building examples in code).
    func sculpting(blend: MeshBuildBlend? = nil, smooth: Float? = nil, resolution: Int? = nil, noise: MeshBuildNoise? = nil) -> MeshBuildPart {
        var part = self
        part.blend = blend
        part.smooth = smooth
        part.resolution = resolution
        part.noise = noise
        return part
    }
}

extension MeshBuildExamples {
    /// An upholstered armchair: one sculpt whose back and rolled arms melt into the base, with
    /// puffy cushions in another fabric (children with a look of their own), on turned wooden legs.
    public static var armchair: MeshBuildExample {
        let fabric = Vec3(0.24, 0.31, 0.25), linen = Vec3(0.66, 0.61, 0.5)
        /// A cushion child: it sets its own look (linen-colored fabric), so it is drawn with a mesh and material of its own.
        func cushion(_ part: MeshBuildPart) -> MeshBuildPart {
            var p = part
            p.color = linen
            p.look = "fabric"
            p.lookScale = 0.3
            return p
        }
        return MeshBuildExample(name: "Armchair", about: "0.9 m wide, seat 0.47 m high, front at -Z. One sculpt: the frame (base, back tilted 8° back, arms and rolled arm tops mirrored on x) melts together with small smooth radii (0.02-0.04 m; larger radii on faces that line up bulge at the seam) and has the sculpt's own look (green fabric with a little wear); the cushions (a bevelled box plus a flattened sphere smoothed in for a puffy top, front and back) are children that set their own look (linen-colored fabric), so the sculpt draws a mesh per look; the seat and back cushions join the frame with smooth 0.015, so the two fabrics blend softly over about 2 cm where they meet instead of at a hard line. The tapered legs are wooden lathes mirrored on x and z, touching the frame's underside at y=0.1.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Armchair", shape: .sculpt, position: Vec3(0, 0.1, 0), color: fabric, look: "fabric", wear: 0.3)
                .sculpting(resolution: 96),
            MeshBuildPart(name: "Base", parent: "Armchair", position: Vec3(0, 0.125, 0), size: Vec3(0.8, 0.25, 0.78), bevel: 0.05),
            MeshBuildPart(name: "Back", parent: "Armchair", position: Vec3(0, 0.42, 0.32), rotation: Vec3(-8, 0, 0), size: Vec3(0.84, 0.82, 0.16),
                          bevel: 0.07).sculpting(smooth: 0.04),
            MeshBuildPart(name: "Left Arm", parent: "Armchair", position: Vec3(-0.35, 0.27, -0.01), size: Vec3(0.15, 0.52, 0.8), bevel: 0.06,
                          mirror: [.x]).sculpting(smooth: 0.02),
            MeshBuildPart(name: "Left Roll", shape: .capsule, parent: "Armchair", position: Vec3(-0.355, 0.54, -0.02), rotation: Vec3(90, 0, 0),
                          size: Vec3(0.18, 0.8, 0.15), mirror: [.x]).sculpting(smooth: 0.03),
            cushion(MeshBuildPart(name: "Seat", parent: "Armchair", position: Vec3(0, 0.31, -0.06), size: Vec3(0.53, 0.12, 0.64), bevel: 0.05)
                .sculpting(smooth: 0.015)),
            cushion(MeshBuildPart(name: "Puff", shape: .sphere, parent: "Armchair", position: Vec3(0, 0.33, -0.06), size: Vec3(0.46, 0.1, 0.58))
                .sculpting(smooth: 0.03)),
            cushion(MeshBuildPart(name: "Back Cushion", parent: "Armchair", position: Vec3(0, 0.59, 0.2), rotation: Vec3(-10, 0, 0),
                                  size: Vec3(0.53, 0.46, 0.14), bevel: 0.06).sculpting(smooth: 0.015)),
            cushion(MeshBuildPart(name: "Back Puff", shape: .sphere, parent: "Armchair", position: Vec3(0, 0.59, 0.19), rotation: Vec3(-10, 0, 0),
                                  size: Vec3(0.44, 0.4, 0.15)).sculpting(smooth: 0.03)),
            MeshBuildPart(name: "Front Left Leg", shape: .lathe, position: Vec3(-0.35, 0, -0.32), color: Vec3(0.28, 0.17, 0.09),
                          profile: [Vec2(0, 0), Vec2(0.018, 0), Vec2(0.028, 0.1), Vec2(0, 0.1)], mirror: [.x, .z], look: "wood"),
        ]))
    }

    /// A weathered stone arch: one sculpt carved with subtracts (the opening, mortar joints) and roughened with noise.
    public static var stoneArch: MeshBuildExample {
        func joint(_ name: String, at position: Vec3, size: Vec3, rotation: Vec3 = .zero, mirror: MeshBuildMirror, repeat r: MeshBuildRepeat) -> MeshBuildPart {
            MeshBuildPart(name: name, parent: "Arch", position: position, rotation: rotation, size: size, mirror: mirror, repetition: r)
                .sculpting(blend: .subtract, smooth: 0.006)
        }
        return MeshBuildExample(name: "Stone Arch", about: "2.6 m wide, 2.65 m high, the opening 1.3 m wide. One sculpt: a wall box with the opening cut out by a subtracted cylinder (the round top, turned [90,0,0] to run along Z) and box (below it), and mortar joints cut 1.5 cm into both faces by thin subtracted boxes: courses repeated up the wall, staggered vertical joints mirrored on x and z, and voussoir joints in a half ring around the opening (repeat radial about z with a radius, angle 180). Keystone, cornice and plinths are added with a 1 cm smooth so they join like mortared stone. noise (1 cm bumps 12 cm across) weathers the stone, and the last child, Trim (a big box intersected, standing on y=0), trims the bumps off the base so it stands flat on y=0: intersects aren't roughened. resolution 120 keeps the joints sharp.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Arch", shape: .sculpt, color: Vec3(0.66, 0.6, 0.5), roughness: 0.95)
                .sculpting(resolution: 120, noise: MeshBuildNoise(amount: 0.01, scale: 0.12, seed: 7)),
            MeshBuildPart(name: "Wall", parent: "Arch", position: Vec3(0, 1.25, 0), size: Vec3(2.4, 2.5, 0.6), bevel: 0.03),
            MeshBuildPart(name: "Opening Top", shape: .cylinder, parent: "Arch", position: Vec3(0, 1.55, 0), rotation: Vec3(90, 0, 0),
                          size: Vec3(1.3, 1, 1.3)).sculpting(blend: .subtract, smooth: 0.02),
            MeshBuildPart(name: "Opening", parent: "Arch", position: Vec3(0, 0.75, 0), size: Vec3(1.3, 1.6, 1)).sculpting(blend: .subtract, smooth: 0.02),
            joint("Front Course", at: Vec3(0, 0.42, -0.3), size: Vec3(2.6, 0.04, 0.035), mirror: [.z],
                  repeat: MeshBuildRepeat(count: 4, offset: Vec3(0, 0.42, 0))),
            joint("Front Left Joint", at: Vec3(-1, 0.21, -0.3), size: Vec3(0.04, 0.42, 0.035), mirror: [.x, .z],
                  repeat: MeshBuildRepeat(count: 3, offset: Vec3(0, 0.84, 0))),
            joint("Front Left Joint B", at: Vec3(-0.82, 0.63, -0.3), size: Vec3(0.04, 0.42, 0.035), mirror: [.x, .z],
                  repeat: MeshBuildRepeat(count: 2, offset: Vec3(0, 0.84, 0))),
            joint("Front Voussoir", at: Vec3(0, 1.55, -0.3), size: Vec3(0.04, 0.44, 0.035), rotation: Vec3(0, 0, 90), mirror: [.z],
                  repeat: MeshBuildRepeat(count: 8, radial: MeshBuildRepeat.Radial(axis: .z, radius: 0.87, angle: 180))),
            MeshBuildPart(name: "Keystone", parent: "Arch", position: Vec3(0, 2.27, 0), size: Vec3(0.3, 0.44, 0.66), bevel: 0.02).sculpting(smooth: 0.01),
            MeshBuildPart(name: "Cornice", parent: "Arch", position: Vec3(0, 2.56, 0), size: Vec3(2.6, 0.14, 0.72), bevel: 0.025).sculpting(smooth: 0.01),
            MeshBuildPart(name: "Left Plinth", parent: "Arch", position: Vec3(-0.88, 0.14, 0), size: Vec3(0.64, 0.28, 0.7), bevel: 0.025, mirror: [.x])
                .sculpting(smooth: 0.01),
            MeshBuildPart(name: "Trim", parent: "Arch", position: Vec3(0, 1.5, 0), size: Vec3(3, 3, 1)).sculpting(blend: .intersect),
        ]))
    }
}

// MARK: - Curves and deformers

// Larger, more realistic builds made of sweeps, lofts and deformers (MeshBuildCurves.swift,
// MeshBuildDeform.swift). They are written as the file format itself, which is what an agent
// reads and writes.

extension MeshBuildExamples {
    /// A build from its JSON (empty if it doesn't read; the tests check every example builds).
    static func decoded(_ json: String) -> MeshBuild {
        (try? AssetJSON.decoder().decode(MeshBuild.self, from: Data(json.utf8))) ?? MeshBuild()
    }

    /// A 6 m sloop, bow at -Z: a lofted hull, deck, cabin, keel and bulb, a tapered mast bent aft,
    /// billowing sails (bent and twisted extrudes) and swept rigging and rails.
    public static var sailboat: MeshBuildExample {
        MeshBuildExample(name: "Sailboat", about: "6 m long, bow at -Z. The hull is a loft along z (axis \"z\"): each section's `at` is its center [x, y, z] (the deck centerline) and its `profile` [across, height] runs from the deck edge down to the keel and back up, so the deck edge stays a hard edge and the bottom is round; the same point count in every section keeps them matched. The deck, cabin, keel fin and bulb are lofts of superellipse sections (roundness 4 is a flat plate, 3 a rounded box, 1 an ellipse; size [0,0] ends in a point). The mast is a cylinder tapered and bent 4° aft with `deform`; the sails are thin extrudes turned onto the boat's length (rotation [0,90,0]) and bent and twisted so they fill with wind. Rigging, pulpit, pushpit and lifelines are sweeps (radius 6-18 mm; shrouds with straight:true and mirror x). The boom and mainsail hang from a group pivot turned 14° to starboard.", build: decoded(sailboatJSON))
    }

    /// A 5.5 m oak with a curving bark trunk, flared roots, tapering branches and a leafy crown of cut-out cards.
    public static var gnarledTree: MeshBuildExample {
        MeshBuildExample(name: "Gnarled Tree", about: "5.5 m tall, about 9k triangles. The trunk, roots, branches and twigs are sweeps whose `radii` taper them toward their tips (1 → 0.15) with the bark look, whose normal map gives the relief (only a gentle, large noise bends the trunk: fine noise would cost tens of thousands of triangles). The roots are one sweep repeated 5 times around the trunk (repeat radial). The leaves are two foliage parts with the oakLeaves look: Leaves grows `on` the branches and twigs (cards along their outer 60%), Crown fills a 3.6 x 2.4 x 3 m ellipsoid around where they end, so the crown is full and its edge ragged. Normals bent out of the crown make it shade as one volume. A dirt mound keeps the base on y=0.", build: decoded(treeJSON))
    }

    /// A spring-balanced desk lamp: lathe base and shade, straight swept arms, helical spring sweeps
    /// and a cable lying on the desk.
    public static var deskLamp: MeshBuildExample {
        MeshBuildExample(name: "Desk Lamp", about: "0.5 m tall, the shade pointing forward (-Z) and down. Base and shade are lathes (the shade's profile goes out along the outside and back along the inside, so it is a hollow cone). Each arm is a pair of straight sweeps (straight:true, mirror x) between joint positions written in the model's space; the springs are sweeps along helix paths (16 turns, 10 points a turn, radius 1.8 mm). The cable is a smooth sweep through points 8 mm above the desk, ending at a bevelled box plug. The bulb glows.", build: decoded(lampJSON))
    }

    static let sailboatJSON = #"""
        {"parts": [
          {"name":"Hull","shape":"loft","axis":"z","color":[0.07,0.13,0.27],"roughness":0.35,"sections":[{"at":[0,1.48,-3],"profile":[[0.02,0],[0.019,-0.105],[0.017,-0.21],[0.013,-0.315],[0,-0.42],[-0.013,-0.315],[-0.017,-0.21],[-0.019,-0.105],[-0.02,0]]},{"at":[0,1.42,-2.3],"profile":[[0.62,0],[0.604,-0.15],[0.542,-0.3],[0.409,-0.45],[0,-0.6],[-0.409,-0.45],[-0.542,-0.3],[-0.604,-0.15],[-0.62,0]]},{"at":[0,1.37,-1.2],"profile":[[1,0],[0.974,-0.16],[0.874,-0.32],[0.659,-0.48],[0,-0.64],[-0.659,-0.48],[-0.874,-0.32],[-0.974,-0.16],[-1,0]]},{"at":[0,1.34,0.3],"profile":[[1.1,0],[1.071,-0.15],[0.961,-0.3],[0.725,-0.45],[0,-0.6],[-0.725,-0.45],[-0.961,-0.3],[-1.071,-0.15],[-1.1,0]]},{"at":[0,1.35,1.8],"profile":[[1.02,0],[0.993,-0.125],[0.891,-0.25],[0.673,-0.375],[0,-0.5],[-0.673,-0.375],[-0.891,-0.25],[-0.993,-0.125],[-1.02,0]]},{"at":[0,1.38,3],"profile":[[0.84,0],[0.818,-0.07],[0.734,-0.14],[0.554,-0.21],[0,-0.28],[-0.554,-0.21],[-0.734,-0.14],[-0.818,-0.07],[-0.84,0]]}]},
          {"name":"Deck","shape":"loft","parent":"Hull","axis":"z","color":[0.4,0.28,0.17],"roughness":0.7,"sections":[{"at":[0,1.492,-2.88],"size":[0.079,0.024],"roundness":4},{"at":[0,1.432,-2.3],"size":[1.203,0.024],"roundness":4},{"at":[0,1.382,-1.2],"size":[1.94,0.024],"roundness":4},{"at":[0,1.352,0.3],"size":[2.134,0.024],"roundness":4},{"at":[0,1.362,1.8],"size":[1.979,0.024],"roundness":4},{"at":[0,1.392,3],"size":[1.63,0.024],"roundness":4}]},
          {"name":"Cabin","shape":"loft","parent":"Hull","axis":"z","color":[0.93,0.92,0.88],"roughness":0.4,"sections":[{"at":[0,1.56,-1.5],"size":[0.9,0.4],"roundness":3},{"at":[0,1.6,-0.9],"size":[1.35,0.5],"roundness":3.5},{"at":[0,1.6,0.6],"size":[1.45,0.5],"roundness":3.5}]},
          {"name":"Window Left","shape":"box","parent":"Cabin","position":[-0.7,1.68,-0.5],"rotation":[0,4,0],"size":[0.02,0.12,0.7],"bevel":0.01,"color":[0.05,0.07,0.1],"metallic":0.2,"roughness":0.1,"mirror":"x"},
          {"name":"Mast","shape":"cylinder","parent":"Cabin","position":[0,5.35,-0.9],"size":[0.13,7,0.11],"color":[0.78,0.8,0.83],"metallic":0.8,"roughness":0.3,"deform":[{"taper":[0.55,0.55]},{"bend":{"axis":"z","degrees":4}}]},
          {"name":"Boom Pivot","shape":"group","parent":"Mast","position":[0,-2.7,0.02],"rotation":[0,14,0]},
          {"name":"Boom","shape":"cylinder","parent":"Boom Pivot","position":[0,0,1.45],"rotation":[90,0,0],"size":[0.09,2.9,0.11],"color":[0.78,0.8,0.83],"metallic":0.8,"roughness":0.3},
          {"name":"Mainsail","shape":"extrude","parent":"Boom Pivot","position":[0,0.07,0.07],"rotation":[0,90,0],"size":[1,1,0.02],"color":[0.96,0.95,0.9],"roughness":0.9,"profile":[[0,0],[-2.85,0],[-2.2,1.6],[-1.45,3.4],[-0.75,5],[-0.22,5.85]],"deform":[{"bend":{"axis":"z","degrees":14}},{"twist":8}]},
          {"name":"Jib","shape":"extrude","parent":"Hull","position":[0.02,1.62,-2.82],"rotation":[0,101,0],"size":[1,1,0.02],"color":[0.96,0.95,0.9],"roughness":0.9,"profile":[[0,0],[-1.72,5.6],[-2.15,0.55],[-1.2,0.15]],"deform":[{"bend":{"axis":"z","degrees":7}}]},
          {"name":"Forestay","shape":"sweep","parent":"Hull","radius":0.008,"color":[0.25,0.26,0.28],"metallic":0.7,"roughness":0.4,"segments":8,"path":[[0,1.5,-2.96],[0,8.494,-0.736]]},
          {"name":"Backstay","shape":"sweep","parent":"Hull","radius":0.008,"color":[0.25,0.26,0.28],"metallic":0.7,"roughness":0.4,"segments":8,"path":[[0,8.794,-0.616],[0,1.4,2.95]]},
          {"name":"Spreader Left","shape":"box","parent":"Mast","position":[-0.35,-0.15,0.06],"size":[0.7,0.04,0.05],"color":[0.78,0.8,0.83],"metallic":0.8,"roughness":0.3,"mirror":"x"},
          {"name":"Shroud Left","shape":"sweep","parent":"Hull","radius":0.008,"color":[0.25,0.26,0.28],"metallic":0.7,"roughness":0.4,"segments":8,"straight":true,"mirror":"x","path":[[-0.04,7.944,-0.73],[-0.7,5.2,-0.78],[-1.03,1.36,-0.65]]},
          {"name":"Pulpit","shape":"sweep","parent":"Hull","radius":0.018,"color":[0.8,0.82,0.85],"metallic":0.9,"roughness":0.2,"path":[[-0.5,1.38,-1.9],[-0.47,1.95,-2],[-0.24,2,-2.55],[0,2,-2.74],[0.24,2,-2.55],[0.47,1.95,-2],[0.5,1.38,-1.9]]},
          {"name":"Keel","shape":"loft","parent":"Hull","color":[0.14,0.14,0.16],"roughness":0.5,"sections":[{"at":[0,0.25,0.15],"size":[0.09,0.62]},{"at":[0,0.8,0],"size":[0.13,1.05]}]},
          {"name":"Bulb","shape":"loft","parent":"Keel","axis":"z","color":[0.14,0.14,0.16],"roughness":0.5,"sections":[{"at":[0,0.18,-0.5],"size":[0.03,0.03]},{"at":[0,0.18,-0.25],"size":[0.26,0.3]},{"at":[0,0.18,0.15],"size":[0.32,0.36]},{"at":[0,0.18,0.6],"size":[0.2,0.22]},{"at":[0,0.18,0.9],"size":[0.02,0.02]}]},
          {"name":"Rudder","shape":"loft","parent":"Hull","color":[0.14,0.14,0.16],"roughness":0.5,"sections":[{"at":[0,0.42,2.62],"size":[0.05,0.32]},{"at":[0,1.15,2.5],"size":[0.08,0.48]}]},
          {"name":"Tiller","shape":"sweep","parent":"Hull","color":[0.55,0.36,0.2],"roughness":0.6,"radius":0.025,"path":[[0,1.38,2.55],[0,1.58,2.35],[0,1.66,1.65]],"radii":[1.2,1,0.8]},
          {"name":"Pushpit","shape":"sweep","parent":"Hull","radius":0.014,"color":[0.8,0.82,0.85],"metallic":0.9,"roughness":0.2,"path":[[-0.72,1.36,2.3],[-0.7,1.95,2.45],[-0.4,1.98,2.78],[0.4,1.98,2.78],[0.7,1.95,2.45],[0.72,1.36,2.3]]},
          {"name":"Stanchion Left","shape":"cylinder","parent":"Hull","color":[0.8,0.82,0.85],"metallic":0.9,"roughness":0.2,"position":[-0.9,1.65,-1],"size":[0.025,0.6,0.025],"mirror":"x","repeat":{"count":3,"offset":[0,0,1.1]}},
          {"name":"Lifeline Left","shape":"sweep","parent":"Hull","radius":0.006,"color":[0.25,0.26,0.28],"metallic":0.7,"roughness":0.4,"segments":8,"mirror":"x","path":[[-0.47,1.93,-2],[-0.9,1.94,-1],[-0.92,1.94,0.1],[-0.9,1.94,1.2],[-0.69,1.93,2.42]]},
          {"name":"Winch Left","shape":"cylinder","parent":"Hull","position":[-0.75,1.42,1.5],"size":[0.12,0.12,0.12],"bevel":0.015,"color":[0.75,0.77,0.8],"metallic":0.9,"roughness":0.25,"mirror":"x"}
        ]}
        """#

    static let treeJSON = #"""
        {"parts": [
          {"name":"Mound","shape":"hemisphere","position":[0,0.06,0],"size":[1.8,0.12,1.8],"segments":24,"look":"dirt"},
          {"name":"Trunk","shape":"sweep","parent":"Mound","position":[0,-0.06,0],"look":"bark","radius":0.26,"segments":16,"path":[[0,0.08,0],[0.1,0.8,0.05],[-0.13,1.6,0.14],[0.07,2.3,0],[0.12,3,-0.05]],"radii":[1.4,1,0.85,0.75,0.6],"deform":[{"noise":{"amount":0.035,"scale":0.45,"seed":4}}]},
          {"name":"Root","shape":"sweep","parent":"Trunk","look":"bark","radius":0.1,"segments":10,"path":[[0.1,0.62,0],[0.38,0.3,0.02],[0.62,0.17,0.06],[0.86,0.11,0.1]],"radii":[1.6,1.1,0.6,0.15],"repeat":{"count":5,"radial":{"axis":"y"}}},
          {"name":"Branch East","shape":"sweep","parent":"Trunk","look":"bark","radius":0.15,"segments":12,"path":[[0,2.35,0.05],[0.6,2.9,0.1],[1.2,3.2,0],[1.75,3.75,-0.1]],"radii":[1,0.72,0.48,0.15]},
          {"name":"Branch West","shape":"sweep","parent":"Trunk","look":"bark","radius":0.14,"segments":12,"path":[[-0.05,2.05,0.1],[-0.6,2.6,0.4],[-1.1,3,0.5],[-1.55,3.65,0.7]],"radii":[1,0.72,0.48,0.15]},
          {"name":"Branch Front","shape":"sweep","parent":"Trunk","look":"bark","radius":0.12,"segments":10,"path":[[0.05,2.65,0],[0.1,3.3,-0.5],[0,3.8,-0.95],[0.15,4.25,-1.2]],"radii":[1,0.7,0.45,0.15]},
          {"name":"Branch Back","shape":"sweep","parent":"Trunk","look":"bark","radius":0.11,"segments":10,"path":[[0.05,2.5,0.05],[0.25,3.1,0.6],[0.2,3.6,1.0],[0.4,4.0,1.35]],"radii":[1,0.7,0.45,0.15]},
          {"name":"Leader","shape":"sweep","parent":"Trunk","look":"bark","radius":0.14,"segments":10,"path":[[0.12,2.9,-0.05],[0.2,3.6,0.1],[0.1,4.3,0.2],[0.25,4.9,0.15]],"radii":[1,0.7,0.45,0.12]},
          {"name":"Twig East","shape":"sweep","parent":"Branch East","look":"bark","radius":0.05,"segments":8,"path":[[1.2,3.2,0],[1.5,3.35,0.5],[1.85,3.5,0.85]],"radii":[1,0.6,0.15]},
          {"name":"Twig West","shape":"sweep","parent":"Branch West","look":"bark","radius":0.05,"segments":8,"path":[[-1.1,3,0.5],[-1.6,3.1,0.2],[-2.05,3.3,0.05]],"radii":[1,0.6,0.15]},
          {"name":"Twig Front","shape":"sweep","parent":"Branch Front","look":"bark","radius":0.045,"segments":8,"path":[[0,3.8,-0.95],[-0.5,4.0,-1.1],[-0.9,4.3,-1.0]],"radii":[1,0.6,0.15]},
          {"name":"Twig Top","shape":"sweep","parent":"Leader","look":"bark","radius":0.045,"segments":8,"path":[[0.1,4.3,0.2],[0.55,4.6,0.35],[0.9,4.75,0.55]],"radii":[1,0.6,0.15]},
          {"name":"Leaves","shape":"foliage","parent":"Trunk","look":"oakLeaves","on":["Branch East","Branch West","Branch Front","Branch Back","Leader","Twig East","Twig West","Twig Front","Twig Top"],"along":[0.4,1],"cardSize":0.6,"density":1.3},
          {"name":"Crown","shape":"foliage","parent":"Trunk","look":"oakLeaves","position":[0.05,4.0,0.05],"size":[3.6,2.4,3.0],"cardSize":0.65,"density":0.9,"seed":2}
        ]}
        """#

    static let lampJSON = #"""
        {"parts": [
          {"name":"Base","shape":"lathe","color":[0.1,0.1,0.11],"metallic":0.7,"roughness":0.35,"segments":40,"profile":[[0,0],[0.1,0],[0.104,0.006],[0.102,0.02],[0.085,0.03],[0.04,0.036],[0.025,0.04],[0,0.04]]},
          {"name":"Post","shape":"cylinder","parent":"Base","color":[0.1,0.1,0.11],"metallic":0.7,"roughness":0.35,"position":[0,0.05,0.035],"size":[0.03,0.03,0.03]},
          {"name":"Knuckle","shape":"cylinder","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"position":[0,0.075,0.035],"rotation":[0,0,90],"size":[0.03,0.06,0.03]},
          {"name":"Lower Arm Left","shape":"sweep","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"radius":0.006,"segments":10,"straight":true,"mirror":"x","path":[[-0.022,0.075,0.035],[-0.022,0.37,0.14]]},
          {"name":"Elbow","shape":"cylinder","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"position":[0,0.37,0.14],"rotation":[0,0,90],"size":[0.028,0.06,0.028]},
          {"name":"Upper Arm Left","shape":"sweep","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"radius":0.005,"segments":10,"straight":true,"mirror":"x","path":[[-0.016,0.37,0.14],[-0.016,0.47,-0.2]]},
          {"name":"Spring Left","shape":"sweep","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"radius":0.0018,"segments":6,"mirror":"x","path":[[-0.04,0.1022,0.0433],[-0.0441,0.103,0.045],[-0.0467,0.1032,0.0488],[-0.0467,0.1031,0.0533],[-0.0441,0.1032,0.057],[-0.04,0.1041,0.0587],[-0.0359,0.1057,0.0578],[-0.0333,0.1081,0.0549],[-0.0333,0.1107,0.0512],[-0.0359,0.113,0.0483],[-0.04,0.1147,0.0474],[-0.0441,0.1155,0.0491],[-0.0467,0.1157,0.0528],[-0.0467,0.1156,0.0573],[-0.0441,0.1157,0.0611],[-0.04,0.1166,0.0628],[-0.0359,0.1182,0.0619],[-0.0333,0.1206,0.059],[-0.0333,0.1232,0.0553],[-0.0359,0.1255,0.0523],[-0.04,0.1272,0.0515],[-0.0441,0.128,0.0531],[-0.0467,0.1282,0.0569],[-0.0467,0.1281,0.0614],[-0.0441,0.1282,0.0651],[-0.04,0.1291,0.0668],[-0.0359,0.1307,0.0659],[-0.0333,0.1331,0.063],[-0.0333,0.1357,0.0593],[-0.0359,0.138,0.0564],[-0.04,0.1397,0.0555],[-0.0441,0.1405,0.0572],[-0.0467,0.1407,0.0609],[-0.0467,0.1406,0.0655],[-0.0441,0.1407,0.0692],[-0.04,0.1416,0.0709],[-0.0359,0.1432,0.07],[-0.0333,0.1456,0.0671],[-0.0333,0.1482,0.0634],[-0.0359,0.1505,0.0605],[-0.04,0.1522,0.0596],[-0.0441,0.153,0.0613],[-0.0467,0.1532,0.065],[-0.0467,0.1531,0.0695],[-0.0441,0.1532,0.0733],[-0.04,0.1541,0.0749],[-0.0359,0.1557,0.0741],[-0.0333,0.1581,0.0712],[-0.0333,0.1607,0.0674],[-0.0359,0.163,0.0645],[-0.04,0.1647,0.0637],[-0.0441,0.1655,0.0653],[-0.0467,0.1657,0.0691],[-0.0467,0.1656,0.0736],[-0.0441,0.1657,0.0773],[-0.04,0.1666,0.079],[-0.0359,0.1682,0.0781],[-0.0333,0.1706,0.0752],[-0.0333,0.1732,0.0715],[-0.0359,0.1755,0.0686],[-0.04,0.1772,0.0677],[-0.0441,0.178,0.0694],[-0.0467,0.1782,0.0731],[-0.0467,0.1781,0.0777],[-0.0441,0.1782,0.0814],[-0.04,0.1791,0.0831],[-0.0359,0.1807,0.0822],[-0.0333,0.1831,0.0793],[-0.0333,0.1857,0.0756],[-0.0359,0.188,0.0726],[-0.04,0.1897,0.0718],[-0.0441,0.1905,0.0735],[-0.0467,0.1907,0.0772],[-0.0467,0.1906,0.0817],[-0.0441,0.1907,0.0854],[-0.04,0.1916,0.0871],[-0.0359,0.1932,0.0863],[-0.0333,0.1956,0.0833],[-0.0333,0.1982,0.0796],[-0.0359,0.2005,0.0767],[-0.04,0.2022,0.0758],[-0.0441,0.203,0.0775],[-0.0467,0.2032,0.0813],[-0.0467,0.2031,0.0858],[-0.0441,0.2032,0.0895],[-0.04,0.2041,0.0912],[-0.0359,0.2057,0.0903],[-0.0333,0.2081,0.0874],[-0.0333,0.2107,0.0837],[-0.0359,0.213,0.0808],[-0.04,0.2147,0.0799],[-0.0441,0.2155,0.0816],[-0.0467,0.2157,0.0853],[-0.0467,0.2156,0.0898],[-0.0441,0.2157,0.0936],[-0.04,0.2166,0.0953],[-0.0359,0.2182,0.0944],[-0.0333,0.2206,0.0915],[-0.0333,0.2232,0.0878],[-0.0359,0.2255,0.0848],[-0.04,0.2272,0.084],[-0.0441,0.228,0.0856],[-0.0467,0.2282,0.0894],[-0.0467,0.2281,0.0939],[-0.0441,0.2282,0.0976],[-0.04,0.2291,0.0993],[-0.0359,0.2307,0.0984],[-0.0333,0.2331,0.0955],[-0.0333,0.2357,0.0918],[-0.0359,0.238,0.0889],[-0.04,0.2397,0.088],[-0.0441,0.2405,0.0897],[-0.0467,0.2407,0.0934],[-0.0467,0.2406,0.098],[-0.0441,0.2407,0.1017],[-0.04,0.2416,0.1034],[-0.0359,0.2432,0.1025],[-0.0333,0.2456,0.0996],[-0.0333,0.2482,0.0959],[-0.0359,0.2505,0.093],[-0.04,0.2522,0.0921],[-0.0441,0.253,0.0938],[-0.0467,0.2532,0.0975],[-0.0467,0.2531,0.102],[-0.0441,0.2532,0.1058],[-0.04,0.2541,0.1074],[-0.0359,0.2557,0.1066],[-0.0333,0.2581,0.1037],[-0.0333,0.2607,0.0999],[-0.0359,0.263,0.097],[-0.04,0.2647,0.0962],[-0.0441,0.2655,0.0978],[-0.0467,0.2657,0.1016],[-0.0467,0.2656,0.1061],[-0.0441,0.2657,0.1098],[-0.04,0.2666,0.1115],[-0.0359,0.2682,0.1106],[-0.0333,0.2706,0.1077],[-0.0333,0.2732,0.104],[-0.0359,0.2755,0.1011],[-0.04,0.2772,0.1002],[-0.0441,0.278,0.1019],[-0.0467,0.2782,0.1056],[-0.0467,0.2781,0.1102],[-0.0441,0.2782,0.1139],[-0.04,0.2791,0.1156],[-0.0359,0.2807,0.1147],[-0.0333,0.2831,0.1118],[-0.0333,0.2857,0.1081],[-0.0359,0.288,0.1051],[-0.04,0.2897,0.1043],[-0.0441,0.2905,0.106],[-0.0467,0.2907,0.1097],[-0.0467,0.2906,0.1142],[-0.0441,0.2907,0.1179],[-0.04,0.2916,0.1196],[-0.0359,0.2932,0.1188],[-0.0333,0.2956,0.1158],[-0.0333,0.2982,0.1121],[-0.0359,0.3005,0.1092],[-0.04,0.3022,0.1083]]},
          {"name":"Spring Hook Left","shape":"sweep","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"radius":0.0018,"segments":6,"mirror":"x","straight":true,"path":[[-0.022,0.09,0.042],[-0.04,0.1,0.05]]},
          {"name":"Spring Top Left","shape":"sweep","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"radius":0.0018,"segments":6,"mirror":"x","straight":true,"path":[[-0.04,0.3,0.115],[-0.022,0.31,0.12]]},
          {"name":"Head Knuckle","shape":"sphere","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"position":[0,0.47,-0.2],"size":[0.032,0.032,0.032]},
          {"name":"Shade","shape":"lathe","parent":"Head Knuckle","position":[0,-0.087,-0.103],"rotation":[50,0,0],"segments":40,"color":[0.08,0.3,0.22],"metallic":0.4,"roughness":0.35,"profile":[[0,0.135],[0.016,0.133],[0.022,0.12],[0.03,0.1],[0.078,0.008],[0.08,0],[0.074,0],[0.026,0.096],[0,0.118]]},
          {"name":"Bulb","shape":"sphere","parent":"Shade","position":[0,0.05,0],"size":[0.05,0.06,0.05],"color":[1,0.96,0.85],"glow":[1,0.85,0.6],"glowStrength":6},
          {"name":"Cable","shape":"sweep","parent":"Base","radius":0.0035,"segments":8,"color":[0.05,0.05,0.05],"roughness":0.6,"path":[[0,0.03,0.06],[0,0.03,0.105],[0.01,0.01,0.15],[0.05,0.008,0.24],[0.16,0.008,0.3],[0.28,0.008,0.28],[0.36,0.008,0.33]]},
          {"name":"Plug","shape":"box","parent":"Cable","position":[0.38,0.014,0.344],"rotation":[0,-58,0],"size":[0.022,0.016,0.04],"bevel":0.004,"color":[0.92,0.92,0.9],"roughness":0.5}
        ]}
        """#

}

public enum MeshBuildExamplesCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// One example by name (default: all).
        public var name: String?
        public init(name: String? = nil) { self.name = name }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var examples: [Example]
    }

    /// An example with its build as JSON keeping only the keys that differ from the defaults.
    public struct Example: Codable, Equatable, Sendable {
        public var name: String
        public var about: String
        public var build: JSONValue
    }

    /// `build` as JSON without the keys that hold their default values (names are kept).
    static func compact(_ build: MeshBuild) throws -> JSONValue {
        func json<T: Encodable>(_ value: T) throws -> JSONValue { try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value)) }
        func strip(_ value: JSONValue, _ defaults: JSONValue) -> JSONValue {
            guard case .object(let fields) = value, case .object(let base) = defaults else { return value }
            return .object(fields.filter { key, value in key == "name" || key == "part" || base[key] != value })
        }
        guard case .object(var root) = try json(build) else { return try json(build) }
        let part = try json(MeshBuildPart()), animation = try json(MeshBuildAnimation()), motion = try json(MeshBuildMotion())
        let track = try json(MeshBuildTrack())
        if case .array(let parts)? = root["parts"] { root["parts"] = .array(parts.map { strip($0, part) }) }
        if case .array(let animations)? = root["animations"] {
            root["animations"] = .array(animations.map { value in
                guard case .object(var fields) = strip(value, animation) else { return value }
                if case .array(let motions)? = fields["motions"] { fields["motions"] = .array(motions.map { strip($0, motion) }) }
                if case .array(let tracks)? = fields["tracks"] { fields["tracks"] = .array(tracks.map { strip($0, track) }) }
                return .object(fields)
            })
            if animations.isEmpty { root["animations"] = nil }
        }
        return .object(root)
    }

    public static let id: CommandID = "meshBuild.examples"
    public static let title = "Mesh Build Examples"
    public static let doc = "Returns small, correct mesh builds to learn from or start with (pass one's `build` to meshBuild.new; keys at their defaults are left out): a street lamp (a parent chain, glow), a wooden cart (wheels turned onto an axle, a spin animation), a turret (a group pivot swinging its children), a weathered crate (looks, wear, mirrored corner caps), a park bench (mirror and repeat, wood and painted iron), three sculpts: an armchair (parts melted together with smooth, cushions in a second fabric as children with their own look), a stone arch (carved with subtracts, roughened with noise) and a ceramic teapot (swept spout and handle melted onto a lathe body, a knob in another glaze), three built from curves: a sailboat (lofted hull, bent mast, billowing sails, swept rigging), a gnarled tree (tapered bark sweeps, leaf-card foliage on branches and in a crown) and a desk lamp (lathes, swept arms, helical springs, a cable), and plants: a flowering shrub, a potted fern (a lathe pot, ribbon fronds) and a small pine (whorls of branches with needle cards). Each stands on y=0, faces -Z and gives no warnings. `name` picks one."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let matches = MeshBuildExamples.all.filter { arguments.name == nil || $0.name.caseInsensitiveCompare(arguments.name!) == .orderedSame }
        guard !matches.isEmpty else {
            throw CommandError.failed("No example named \(arguments.name ?? "") (examples: \(MeshBuildExamples.all.map(\.name).joined(separator: ", ")))")
        }
        return Result(examples: try matches.map { Example(name: $0.name, about: $0.about, build: try compact($0.build)) })
    }
}
