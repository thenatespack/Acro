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
    public static var all: [MeshBuildExample] { [streetLamp, cart, turret, sailboat, gnarledTree, deskLamp] }

    static let iron = Vec3(0.18, 0.19, 0.2)
    static let wood = Vec3(0.55, 0.36, 0.2)

    /// A pole on a foot with an arm reaching forward, a shade and a glowing bulb: a parent chain
    /// where each position is in the parent's space.
    public static var streetLamp: MeshBuildExample {
        MeshBuildExample(name: "Street Lamp", about: "3.8 m tall. A parent chain (Base > Pole > Arm > Shade > Bulb): each position is the part's center in its parent's space, so the pole's 1.9 is half its 3.6 m height above the foot's center. The arm reaches forward (-Z). The bulb glows.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Base", shape: .cylinder, position: Vec3(0, 0.1, 0), size: Vec3(0.4, 0.2, 0.4), color: iron,
                          metallic: 0.6, roughness: 0.4),
            MeshBuildPart(name: "Pole", shape: .cylinder, parent: "Base", position: Vec3(0, 1.9, 0), size: Vec3(0.12, 3.6, 0.12),
                          color: iron, metallic: 0.6, roughness: 0.4),
            MeshBuildPart(name: "Arm", shape: .box, parent: "Pole", position: Vec3(0, 1.7, -0.3), size: Vec3(0.08, 0.08, 0.7),
                          color: iron, metallic: 0.6, roughness: 0.4),
            MeshBuildPart(name: "Shade", shape: .cone, parent: "Arm", position: Vec3(0, -0.1, -0.3), size: Vec3(0.45, 0.3, 0.45),
                          color: Vec3(0.12, 0.3, 0.2), metallic: 0.3, roughness: 0.5),
            MeshBuildPart(name: "Bulb", shape: .sphere, parent: "Shade", position: Vec3(0, -0.15, 0), size: Vec3(0.18, 0.18, 0.18),
                          color: Vec3(1, 0.95, 0.8), glow: Vec3(1, 0.85, 0.55), glowStrength: 4),
        ]))
    }

    /// A wooden cart, 2 m long, front at -Z: wheels turned onto the X axle with rotation [0,0,90].
    public static var cart: MeshBuildExample {
        func wheel(_ name: String, _ x: Float, _ z: Float) -> MeshBuildPart {
            MeshBuildPart(name: name, shape: .cylinder, parent: "Bed", position: Vec3(x, -0.2, z), rotation: Vec3(0, 0, 90),
                          size: Vec3(0.8, 0.1, 0.8), color: Vec3(0.3, 0.2, 0.12), roughness: 0.8)
        }
        func axle(_ name: String, _ z: Float) -> MeshBuildPart {
            MeshBuildPart(name: name, shape: .cylinder, parent: "Bed", position: Vec3(0, -0.2, z), rotation: Vec3(0, 0, 90),
                          size: Vec3(0.06, 1.3, 0.06), color: iron, metallic: 0.6, roughness: 0.4)
        }
        return MeshBuildExample(name: "Wooden Cart", about: "2 m long, front (the shaft) at -Z. Cylinders run along Y, so wheels and axles on an axle along X use rotation [0,0,90]. The wheels' 0.8 m diameter puts their centers 0.4 m up and their bottoms on y=0; they touch the bed's sides. The Roll animation (autoplay off) spins the wheels about their own axis (motion axis y).", build: MeshBuild(parts: [
            MeshBuildPart(name: "Bed", shape: .box, position: Vec3(0, 0.6, 0), size: Vec3(1.2, 0.15, 2), color: wood, roughness: 0.8),
            MeshBuildPart(name: "Side L", shape: .box, parent: "Bed", position: Vec3(-0.56, 0.25, 0), size: Vec3(0.08, 0.35, 2),
                          color: wood, roughness: 0.8),
            MeshBuildPart(name: "Side R", shape: .box, parent: "Bed", position: Vec3(0.56, 0.25, 0), size: Vec3(0.08, 0.35, 2),
                          color: wood, roughness: 0.8),
            MeshBuildPart(name: "Front", shape: .box, parent: "Bed", position: Vec3(0, 0.25, -0.96), size: Vec3(1.04, 0.35, 0.08),
                          color: wood, roughness: 0.8),
            MeshBuildPart(name: "Shaft", shape: .box, parent: "Bed", position: Vec3(0, -0.05, -1.45), size: Vec3(0.08, 0.08, 1),
                          color: wood, roughness: 0.8),
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
        MeshBuildExample(name: "Turret", about: "1.2 m wide. A group part (Pivot) is a hinge with no mesh: the head hangs from it and the Scan animation swings the pivot 40 degrees each way about Y, so everything on it turns together. The barrel is a cylinder turned with rotation [90,0,0] to point forward (-Z); the muzzle is its child, so it inherits that rotation and sits at the barrel's local y=-0.5 end.", build: MeshBuild(parts: [
            MeshBuildPart(name: "Base", shape: .cylinder, position: Vec3(0, 0.15, 0), size: Vec3(1.2, 0.3, 1.2), color: Vec3(0.35, 0.37, 0.4),
                          metallic: 0.7, roughness: 0.35),
            MeshBuildPart(name: "Pivot", shape: .group, parent: "Base", position: Vec3(0, 0.15, 0)),
            MeshBuildPart(name: "Head", shape: .box, parent: "Pivot", position: Vec3(0, 0.25, 0), size: Vec3(0.8, 0.5, 0.9),
                          color: Vec3(0.45, 0.5, 0.35), metallic: 0.4, roughness: 0.5),
            MeshBuildPart(name: "Barrel", shape: .cylinder, parent: "Head", position: Vec3(0, 0.05, -0.85), rotation: Vec3(90, 0, 0),
                          size: Vec3(0.12, 1, 0.12), color: iron, metallic: 0.8, roughness: 0.3),
            MeshBuildPart(name: "Muzzle", shape: .cylinder, parent: "Barrel", position: Vec3(0, -0.5, 0), size: Vec3(0.18, 0.15, 0.18),
                          color: iron, metallic: 0.8, roughness: 0.3),
            MeshBuildPart(name: "Sensor", shape: .sphere, parent: "Head", position: Vec3(0.25, 0.3, 0.1), size: Vec3(0.2, 0.2, 0.2),
                          color: Vec3(0.9, 0.1, 0.05), glow: Vec3(1, 0.1, 0.05), glowStrength: 3),
        ], animations: [
            MeshBuildAnimation(name: "Scan", motions: [MeshBuildMotion(part: "Pivot", kind: .swing, axis: .y, amount: 40, period: 4)]),
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
        MeshBuildExample(name: "Sailboat", about: "6 m long, bow at -Z. The hull is a loft along z (axis \"z\"): each section's `at` is its center [x, y, z] (the deck centerline) and its `profile` [across, height] runs from the deck edge down to the keel and back up, so the deck edge stays a hard edge and the bottom is round; the same point count in every section keeps them matched. The deck, cabin, keel fin and bulb are lofts of superellipse sections (roundness 4 is a flat plate, 3 a rounded box, 1 an ellipse; size [0,0] ends in a point). The mast is a cylinder tapered and bent 4° aft with `deform`; the sails are thin extrudes turned onto the boat's length (rotation [0,90,0]) and bent and twisted so they fill with wind. Rigging, pulpit, pushpit and lifelines are sweeps (radius 6-18 mm; shrouds with smooth:false and mirror x). The boom and mainsail hang from a group pivot turned 14° to starboard.", build: decoded(sailboatJSON))
    }

    /// A 5.7 m tree with a curving, bark-rough trunk, flared roots, tapering branches and lumpy foliage.
    public static var gnarledTree: MeshBuildExample {
        MeshBuildExample(name: "Gnarled Tree", about: "5.7 m tall. The trunk, roots, branches and twigs are sweeps whose `radii` taper them toward their tips (1 → 0.15); the trunk's S-curved path and fine `noise` deform (2.5 cm lumps 12 cm across) read as bark. The roots are one sweep repeated 5 times around the trunk (repeat radial). Each foliage clump is a sphere roughened by large-scale noise with its own seed, so no two are alike. A low hemisphere mound keeps the base on y=0 (noise moves surfaces both ways, so noisy parts start a little above the ground).", build: decoded(treeJSON))
    }

    /// A spring-balanced desk lamp: lathe base and shade, straight swept arms, helical spring sweeps
    /// and a cable lying on the desk.
    public static var deskLamp: MeshBuildExample {
        MeshBuildExample(name: "Desk Lamp", about: "0.5 m tall, the shade pointing forward (-Z) and down. Base and shade are lathes (the shade's profile goes out along the outside and back along the inside, so it is a hollow cone). Each arm is a pair of straight sweeps (smooth:false, mirror x) between joint positions written in the model's space; the springs are sweeps along helix paths (16 turns, 10 points a turn, radius 1.8 mm). The cable is a smooth sweep through points 8 mm above the desk, ending at a bevelled box plug. The bulb glows.", build: decoded(lampJSON))
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
          {"name":"Shroud Left","shape":"sweep","parent":"Hull","radius":0.008,"color":[0.25,0.26,0.28],"metallic":0.7,"roughness":0.4,"segments":8,"smooth":false,"mirror":"x","path":[[-0.04,7.944,-0.73],[-0.7,5.2,-0.78],[-1.03,1.36,-0.65]]},
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
          {"name":"Mound","shape":"hemisphere","position":[0,0.08,0],"size":[1.9,0.16,1.9],"color":[0.3,0.24,0.16],"roughness":1},
          {"name":"Trunk","shape":"sweep","parent":"Mound","color":[0.36,0.27,0.2],"roughness":0.95,"position":[0,-0.08,0],"radius":0.28,"segments":20,"path":[[0,0.12,0],[0.1,0.8,0.05],[-0.13,1.6,0.14],[0.07,2.3,0],[0.12,3,-0.05]],"radii":[1.35,1,0.85,0.75,0.6],"deform":[{"noise":{"amount":0.025,"scale":0.12,"seed":4}}]},
          {"name":"Root","shape":"sweep","parent":"Trunk","color":[0.36,0.27,0.2],"roughness":0.95,"radius":0.1,"segments":12,"path":[[0.1,0.62,0],[0.38,0.3,0.02],[0.62,0.17,0.06],[0.86,0.11,0.1]],"radii":[1.6,1.1,0.6,0.15],"deform":[{"noise":{"amount":0.012,"scale":0.1,"seed":9}}],"repeat":{"count":5,"radial":{"axis":"y"}}},
          {"name":"Branch East","shape":"sweep","parent":"Trunk","color":[0.36,0.27,0.2],"roughness":0.95,"radius":0.16,"segments":14,"path":[[0,2.35,0.05],[0.6,2.9,0.1],[1.2,3.2,0],[1.7,3.7,-0.1]],"radii":[1,0.75,0.5,0.2],"deform":[{"noise":{"amount":0.015,"scale":0.1,"seed":5}}]},
          {"name":"Branch West","shape":"sweep","parent":"Trunk","color":[0.36,0.27,0.2],"roughness":0.95,"radius":0.15,"segments":14,"path":[[-0.05,2.05,0.1],[-0.6,2.6,0.4],[-1.1,3,0.5],[-1.5,3.6,0.7]],"radii":[1,0.75,0.5,0.2],"deform":[{"noise":{"amount":0.015,"scale":0.1,"seed":6}}]},
          {"name":"Branch Front","shape":"sweep","parent":"Trunk","color":[0.36,0.27,0.2],"roughness":0.95,"radius":0.13,"segments":12,"path":[[0.05,2.65,0],[0.1,3.3,-0.5],[0,3.8,-0.9],[0.15,4.2,-1.1]],"radii":[1,0.7,0.45,0.2]},
          {"name":"Leader","shape":"sweep","parent":"Trunk","color":[0.36,0.27,0.2],"roughness":0.95,"radius":0.15,"segments":12,"path":[[0.12,2.9,-0.05],[0.2,3.6,0.1],[0.1,4.3,0.2],[0.25,4.8,0.15]],"radii":[1,0.7,0.45,0.15]},
          {"name":"Twig East","shape":"sweep","parent":"Branch East","color":[0.36,0.27,0.2],"roughness":0.95,"radius":0.06,"segments":8,"path":[[1.2,3.2,0],[1.5,3.3,0.5],[1.8,3.5,0.8]],"radii":[1,0.6,0.2]},
          {"name":"Twig West","shape":"sweep","parent":"Branch West","color":[0.36,0.27,0.2],"roughness":0.95,"radius":0.06,"segments":8,"path":[[-1.1,3,0.5],[-1.6,3.1,0.2],[-2,3.3,0.1]],"radii":[1,0.6,0.2]},
          {"name":"Leaves 1","shape":"sphere","parent":"Trunk","position":[1.7,3.95,-0.1],"size":[1.4,1.12,1.4],"segments":16,"color":[0.22,0.4,0.15],"roughness":0.9,"deform":[{"noise":{"amount":0.168,"scale":0.42,"seed":1}}]},
          {"name":"Leaves 2","shape":"sphere","parent":"Trunk","position":[1.85,3.65,0.8],"size":[1.1,0.88,1.1],"segments":16,"color":[0.27,0.45,0.17],"roughness":0.9,"deform":[{"noise":{"amount":0.132,"scale":0.33,"seed":2}}]},
          {"name":"Leaves 3","shape":"sphere","parent":"Trunk","position":[-1.5,3.85,0.7],"size":[1.4,1.12,1.4],"segments":16,"color":[0.2,0.36,0.13],"roughness":0.9,"deform":[{"noise":{"amount":0.168,"scale":0.42,"seed":3}}]},
          {"name":"Leaves 4","shape":"sphere","parent":"Trunk","position":[-2.05,3.45,0.1],"size":[1,0.8,1],"segments":16,"color":[0.25,0.43,0.2],"roughness":0.9,"deform":[{"noise":{"amount":0.12,"scale":0.3,"seed":4}}]},
          {"name":"Leaves 5","shape":"sphere","parent":"Trunk","position":[0.15,4.4,-1.1],"size":[1.3,1.04,1.3],"segments":16,"color":[0.22,0.4,0.15],"roughness":0.9,"deform":[{"noise":{"amount":0.156,"scale":0.39,"seed":5}}]},
          {"name":"Leaves 6","shape":"sphere","parent":"Trunk","position":[0.25,5,0.15],"size":[1.6,1.28,1.6],"segments":16,"color":[0.27,0.45,0.17],"roughness":0.9,"deform":[{"noise":{"amount":0.192,"scale":0.48,"seed":6}}]},
          {"name":"Leaves 7","shape":"sphere","parent":"Trunk","position":[0.6,4.45,0.45],"size":[1.4,1.12,1.4],"segments":16,"color":[0.2,0.36,0.13],"roughness":0.9,"deform":[{"noise":{"amount":0.168,"scale":0.42,"seed":7}}]},
          {"name":"Leaves 8","shape":"sphere","parent":"Trunk","position":[-0.6,4.35,0],"size":[1.5,1.2,1.5],"segments":16,"color":[0.25,0.43,0.2],"roughness":0.9,"deform":[{"noise":{"amount":0.18,"scale":0.45,"seed":8}}]}
        ]}
        """#

    static let lampJSON = #"""
        {"parts": [
          {"name":"Base","shape":"lathe","color":[0.1,0.1,0.11],"metallic":0.7,"roughness":0.35,"segments":40,"profile":[[0,0],[0.1,0],[0.104,0.006],[0.102,0.02],[0.085,0.03],[0.04,0.036],[0.025,0.04],[0,0.04]]},
          {"name":"Post","shape":"cylinder","parent":"Base","color":[0.1,0.1,0.11],"metallic":0.7,"roughness":0.35,"position":[0,0.05,0.035],"size":[0.03,0.03,0.03]},
          {"name":"Knuckle","shape":"cylinder","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"position":[0,0.075,0.035],"rotation":[0,0,90],"size":[0.03,0.06,0.03]},
          {"name":"Lower Arm Left","shape":"sweep","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"radius":0.006,"segments":10,"smooth":false,"mirror":"x","path":[[-0.022,0.075,0.035],[-0.022,0.37,0.14]]},
          {"name":"Elbow","shape":"cylinder","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"position":[0,0.37,0.14],"rotation":[0,0,90],"size":[0.028,0.06,0.028]},
          {"name":"Upper Arm Left","shape":"sweep","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"radius":0.005,"segments":10,"smooth":false,"mirror":"x","path":[[-0.016,0.37,0.14],[-0.016,0.47,-0.2]]},
          {"name":"Spring Left","shape":"sweep","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"radius":0.0018,"segments":6,"mirror":"x","path":[[-0.04,0.1022,0.0433],[-0.0441,0.103,0.045],[-0.0467,0.1032,0.0488],[-0.0467,0.1031,0.0533],[-0.0441,0.1032,0.057],[-0.04,0.1041,0.0587],[-0.0359,0.1057,0.0578],[-0.0333,0.1081,0.0549],[-0.0333,0.1107,0.0512],[-0.0359,0.113,0.0483],[-0.04,0.1147,0.0474],[-0.0441,0.1155,0.0491],[-0.0467,0.1157,0.0528],[-0.0467,0.1156,0.0573],[-0.0441,0.1157,0.0611],[-0.04,0.1166,0.0628],[-0.0359,0.1182,0.0619],[-0.0333,0.1206,0.059],[-0.0333,0.1232,0.0553],[-0.0359,0.1255,0.0523],[-0.04,0.1272,0.0515],[-0.0441,0.128,0.0531],[-0.0467,0.1282,0.0569],[-0.0467,0.1281,0.0614],[-0.0441,0.1282,0.0651],[-0.04,0.1291,0.0668],[-0.0359,0.1307,0.0659],[-0.0333,0.1331,0.063],[-0.0333,0.1357,0.0593],[-0.0359,0.138,0.0564],[-0.04,0.1397,0.0555],[-0.0441,0.1405,0.0572],[-0.0467,0.1407,0.0609],[-0.0467,0.1406,0.0655],[-0.0441,0.1407,0.0692],[-0.04,0.1416,0.0709],[-0.0359,0.1432,0.07],[-0.0333,0.1456,0.0671],[-0.0333,0.1482,0.0634],[-0.0359,0.1505,0.0605],[-0.04,0.1522,0.0596],[-0.0441,0.153,0.0613],[-0.0467,0.1532,0.065],[-0.0467,0.1531,0.0695],[-0.0441,0.1532,0.0733],[-0.04,0.1541,0.0749],[-0.0359,0.1557,0.0741],[-0.0333,0.1581,0.0712],[-0.0333,0.1607,0.0674],[-0.0359,0.163,0.0645],[-0.04,0.1647,0.0637],[-0.0441,0.1655,0.0653],[-0.0467,0.1657,0.0691],[-0.0467,0.1656,0.0736],[-0.0441,0.1657,0.0773],[-0.04,0.1666,0.079],[-0.0359,0.1682,0.0781],[-0.0333,0.1706,0.0752],[-0.0333,0.1732,0.0715],[-0.0359,0.1755,0.0686],[-0.04,0.1772,0.0677],[-0.0441,0.178,0.0694],[-0.0467,0.1782,0.0731],[-0.0467,0.1781,0.0777],[-0.0441,0.1782,0.0814],[-0.04,0.1791,0.0831],[-0.0359,0.1807,0.0822],[-0.0333,0.1831,0.0793],[-0.0333,0.1857,0.0756],[-0.0359,0.188,0.0726],[-0.04,0.1897,0.0718],[-0.0441,0.1905,0.0735],[-0.0467,0.1907,0.0772],[-0.0467,0.1906,0.0817],[-0.0441,0.1907,0.0854],[-0.04,0.1916,0.0871],[-0.0359,0.1932,0.0863],[-0.0333,0.1956,0.0833],[-0.0333,0.1982,0.0796],[-0.0359,0.2005,0.0767],[-0.04,0.2022,0.0758],[-0.0441,0.203,0.0775],[-0.0467,0.2032,0.0813],[-0.0467,0.2031,0.0858],[-0.0441,0.2032,0.0895],[-0.04,0.2041,0.0912],[-0.0359,0.2057,0.0903],[-0.0333,0.2081,0.0874],[-0.0333,0.2107,0.0837],[-0.0359,0.213,0.0808],[-0.04,0.2147,0.0799],[-0.0441,0.2155,0.0816],[-0.0467,0.2157,0.0853],[-0.0467,0.2156,0.0898],[-0.0441,0.2157,0.0936],[-0.04,0.2166,0.0953],[-0.0359,0.2182,0.0944],[-0.0333,0.2206,0.0915],[-0.0333,0.2232,0.0878],[-0.0359,0.2255,0.0848],[-0.04,0.2272,0.084],[-0.0441,0.228,0.0856],[-0.0467,0.2282,0.0894],[-0.0467,0.2281,0.0939],[-0.0441,0.2282,0.0976],[-0.04,0.2291,0.0993],[-0.0359,0.2307,0.0984],[-0.0333,0.2331,0.0955],[-0.0333,0.2357,0.0918],[-0.0359,0.238,0.0889],[-0.04,0.2397,0.088],[-0.0441,0.2405,0.0897],[-0.0467,0.2407,0.0934],[-0.0467,0.2406,0.098],[-0.0441,0.2407,0.1017],[-0.04,0.2416,0.1034],[-0.0359,0.2432,0.1025],[-0.0333,0.2456,0.0996],[-0.0333,0.2482,0.0959],[-0.0359,0.2505,0.093],[-0.04,0.2522,0.0921],[-0.0441,0.253,0.0938],[-0.0467,0.2532,0.0975],[-0.0467,0.2531,0.102],[-0.0441,0.2532,0.1058],[-0.04,0.2541,0.1074],[-0.0359,0.2557,0.1066],[-0.0333,0.2581,0.1037],[-0.0333,0.2607,0.0999],[-0.0359,0.263,0.097],[-0.04,0.2647,0.0962],[-0.0441,0.2655,0.0978],[-0.0467,0.2657,0.1016],[-0.0467,0.2656,0.1061],[-0.0441,0.2657,0.1098],[-0.04,0.2666,0.1115],[-0.0359,0.2682,0.1106],[-0.0333,0.2706,0.1077],[-0.0333,0.2732,0.104],[-0.0359,0.2755,0.1011],[-0.04,0.2772,0.1002],[-0.0441,0.278,0.1019],[-0.0467,0.2782,0.1056],[-0.0467,0.2781,0.1102],[-0.0441,0.2782,0.1139],[-0.04,0.2791,0.1156],[-0.0359,0.2807,0.1147],[-0.0333,0.2831,0.1118],[-0.0333,0.2857,0.1081],[-0.0359,0.288,0.1051],[-0.04,0.2897,0.1043],[-0.0441,0.2905,0.106],[-0.0467,0.2907,0.1097],[-0.0467,0.2906,0.1142],[-0.0441,0.2907,0.1179],[-0.04,0.2916,0.1196],[-0.0359,0.2932,0.1188],[-0.0333,0.2956,0.1158],[-0.0333,0.2982,0.1121],[-0.0359,0.3005,0.1092],[-0.04,0.3022,0.1083]]},
          {"name":"Spring Hook Left","shape":"sweep","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"radius":0.0018,"segments":6,"mirror":"x","smooth":false,"path":[[-0.022,0.09,0.042],[-0.04,0.1,0.05]]},
          {"name":"Spring Top Left","shape":"sweep","parent":"Base","color":[0.85,0.86,0.88],"metallic":1,"roughness":0.15,"radius":0.0018,"segments":6,"mirror":"x","smooth":false,"path":[[-0.04,0.3,0.115],[-0.022,0.31,0.12]]},
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
    public static let doc = "Returns small, correct mesh builds to learn from or start with (pass one's `build` to meshBuild.new; keys at their defaults are left out): a street lamp (a parent chain, glow), a wooden cart (wheels turned onto an axle, a spin animation), a turret (a group pivot swinging its children), and three realistic ones built from curves: a sailboat (lofted hull, bent mast, billowing sails, swept rigging), a gnarled tree (tapered sweeps, noise bark and foliage) and a desk lamp (lathes, swept arms, helical springs, a cable). Each stands on y=0, faces -Z and gives no warnings. `name` picks one."
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
