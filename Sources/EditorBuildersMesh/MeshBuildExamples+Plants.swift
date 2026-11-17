import EditorCore
import Engine
import Foundation

// Plant examples for `meshBuild.examples` (MeshBuildFoliage.swift, MeshBuildRibbon.swift,
// MeshBuildLeafLooks.swift): written as the file format, like the curve examples.

extension MeshBuildExamples {
    /// The plant examples, after the others in `all`.
    static var plants: [MeshBuildExample] { [shrub, pottedFern, pine] }

    /// A leafy shrub on stems, with grass and wildflowers around its foot.
    public static var shrub: MeshBuildExample {
        MeshBuildExample(name: "Shrub", about: "1.3 m tall, 2.5 m across with the grass, about 3k triangles. Five bark stems (one sweep repeated radial) carry the leaves: Shrub fills a 1.7 x 1.15 x 1.6 m ellipsoid with broadleaf cards (no parent: a child of a repeated part would be copied with it), Sprigs grows `on` the stems (naming a repeated part covers its copies). Grass and Wildflowers are upright looks: their crossed tufts stand on the floor of their boxes, as tall as size.y, scattered over the footprint; density 0.25 keeps the flowers sparse. Each foliage part is one mesh and one draw.", build: decoded(shrubJSON))
    }

    /// A fern in a terracotta pot: a lathe pot and ribbon fronds with the fern leaf look.
    public static var pottedFern: MeshBuildExample {
        MeshBuildExample(name: "Potted Fern", about: "0.9 m tall, the pot 0.38 m across, on a saucer, about 9k triangles. The pot is a lathe whose profile goes up the outside, over the rim and down the inside (a hollow pot) with a ceramic look tinted terracotta; the soil is a thin cylinder with the dirt look. Each frond is a sweep with `ribbon` (a flat double-sided strip 0.3 m wide, times `radii`: narrow at the base) and the fern leaf look, which maps one frond along the ribbon from its start, cut out by the texture's alpha. Two frond parts repeated radially (7 arching outward, 5 more upright turned 26° between them) make the plant.", build: decoded(pottedFernJSON))
    }

    /// A 3.7 m spruce: a tapered trunk, six whorls of drooping branches with needle cards.
    public static var pine: MeshBuildExample {
        MeshBuildExample(name: "Small Pine", about: "3.7 m tall, about 11k triangles. The trunk is a tapered bark sweep; each whorl is one branch sweep repeated radially (5-7 around), shorter toward the top, every other whorl turned to stagger them. Needles is one foliage part with the pineNeedles look growing `on` all six whorls (their copies included) along most of their length (`along` [0.1, 1]); Top fills a narrow ellipsoid at the tip. The baked occlusion and the needle cards' shadows darken the inside and the lower branches.", build: decoded(pineJSON))
    }

    static let shrubJSON = #"""
        {"parts": [
          {"name":"Stem","shape":"sweep","position":[0,0.001,0],"look":"bark","radius":0.028,"segments":7,"path":[[0.02,0,0],[0.02,0.12,0],[0.1,0.35,0.02],[0.2,0.58,0.05],[0.36,0.8,0.04]],"radii":[1,0.9,0.75,0.5,0.2],"repeat":{"count":5,"radial":{"axis":"y"}}},
          {"name":"Shrub","shape":"foliage","look":"broadleaf","position":[0,0.68,0],"size":[1.7,1.15,1.6],"cardSize":0.4,"seed":3},
          {"name":"Sprigs","shape":"foliage","look":"broadleaf","on":"Stem","along":[0.45,1],"cardSize":0.36,"seed":5},
          {"name":"Grass","shape":"foliage","look":"grassBlades","position":[0,0.17,0],"size":[2.3,0.34,2.2],"cardSize":0.3,"density":1.3,"seed":7},
          {"name":"Wildflowers","shape":"foliage","look":"flowers","position":[0,0.2,0],"size":[2.4,0.4,2.3],"cardSize":0.3,"density":0.25,"seed":9}
        ]}
        """#

    static let pottedFernJSON = #"""
        {"parts": [
          {"name":"Saucer","shape":"cylinder","position":[0,0.012,0],"size":[0.36,0.024,0.36],"bevel":0.008,"look":"ceramic","color":[0.6,0.33,0.22],"roughness":0.8},
          {"name":"Pot","shape":"lathe","parent":"Saucer","position":[0,0.012,0],"segments":32,"look":"ceramic","color":[0.6,0.33,0.22],"roughness":0.8,"profile":[[0,0],[0.12,0],[0.135,0.015],[0.17,0.25],[0.19,0.26],[0.19,0.29],[0.17,0.29],[0.15,0.04],[0,0.04]]},
          {"name":"Soil","shape":"cylinder","parent":"Pot","position":[0,0.25,0],"size":[0.31,0.02,0.31],"look":"dirt"},
          {"name":"Frond","shape":"sweep","parent":"Soil","look":"fern","ribbon":0.3,"path":[[0.02,0,0],[0.08,0.25,0],[0.26,0.45,0],[0.5,0.42,0]],"radii":[0.35,1,1,0.7],"repeat":{"count":7,"radial":{"axis":"y"}}},
          {"name":"Upright Frond","shape":"sweep","parent":"Soil","rotation":[0,26,0],"look":"fern","ribbon":0.26,"path":[[0.01,0,0],[0.04,0.3,0],[0.14,0.55,0],[0.3,0.62,0]],"radii":[0.35,1,1,0.7],"repeat":{"count":5,"radial":{"axis":"y"}}}
        ]}
        """#

    static let pineJSON = #"""
        {"parts": [
          {"name":"Trunk","shape":"sweep","look":"bark","color":[0.42,0.3,0.22],"radius":0.1,"segments":10,"path":[[0,0,0],[0,1.2,0],[-0.02,2.4,0.02],[0,3.7,0]],"radii":[1.3,0.8,0.45,0.08]},
          {"name":"Whorl 1","shape":"sweep","parent":"Trunk","look":"bark","radius":0.032,"segments":6,"path":[[0.04,0.62,0],[0.6,0.5,0],[1.15,0.44,0],[1.45,0.5,0]],"radii":[1,0.7,0.4,0.12],"repeat":{"count":7,"radial":{"axis":"y"}}},
          {"name":"Whorl 2","shape":"sweep","parent":"Trunk","rotation":[0,26,0],"look":"bark","radius":0.03,"segments":6,"path":[[0.04,1.05,0],[0.5,0.95,0],[0.95,0.9,0],[1.22,0.95,0]],"radii":[1,0.7,0.4,0.12],"repeat":{"count":7,"radial":{"axis":"y"}}},
          {"name":"Whorl 3","shape":"sweep","parent":"Trunk","look":"bark","radius":0.026,"segments":6,"path":[[0.04,1.5,0],[0.42,1.42,0],[0.78,1.38,0],[1.0,1.42,0]],"radii":[1,0.7,0.4,0.12],"repeat":{"count":6,"radial":{"axis":"y"}}},
          {"name":"Whorl 4","shape":"sweep","parent":"Trunk","rotation":[0,30,0],"look":"bark","radius":0.022,"segments":6,"path":[[0.03,1.95,0],[0.34,1.88,0],[0.62,1.85,0],[0.8,1.89,0]],"radii":[1,0.7,0.4,0.12],"repeat":{"count":6,"radial":{"axis":"y"}}},
          {"name":"Whorl 5","shape":"sweep","parent":"Trunk","look":"bark","radius":0.018,"segments":6,"path":[[0.03,2.4,0],[0.26,2.35,0],[0.46,2.33,0],[0.6,2.37,0]],"radii":[1,0.7,0.4,0.12],"repeat":{"count":5,"radial":{"axis":"y"}}},
          {"name":"Whorl 6","shape":"sweep","parent":"Trunk","rotation":[0,36,0],"look":"bark","radius":0.014,"segments":6,"path":[[0.02,2.82,0],[0.18,2.79,0],[0.32,2.78,0],[0.42,2.81,0]],"radii":[1,0.7,0.4,0.12],"repeat":{"count":5,"radial":{"axis":"y"}}},
          {"name":"Needles","shape":"foliage","parent":"Trunk","look":"pineNeedles","on":["Whorl 1","Whorl 2","Whorl 3","Whorl 4","Whorl 5","Whorl 6"],"along":[0.1,1],"cardSize":0.42,"density":1.4,"seed":1},
          {"name":"Top","shape":"foliage","parent":"Trunk","look":"pineNeedles","position":[0,3.3,0],"size":[0.55,1.0,0.55],"cardSize":0.32,"density":1.5,"seed":2}
        ]}
        """#
}
