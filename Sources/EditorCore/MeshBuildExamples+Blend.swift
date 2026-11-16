import Engine
import Foundation

// Sculpt looks that blend across their boundary (MeshBuildSculptBlend.swift): written as the file
// format, like the curve examples.

extension MeshBuildExamples {
    /// A mossy boulder: moss pads melted onto a stone sculpt with a wide smooth, so the moss look
    /// fades into the stone instead of stopping at a line.
    public static var mossyStone: MeshBuildExample {
        MeshBuildExample(name: "Mossy Stone", about: "0.9 m long, 0.5 m high. One sculpt with the stone look and noise (1.5 cm bumps 16 cm across): two squashed spheres make the boulder; the moss is two slightly smaller spheres that poke 1-2 cm out of its top and its shoulder (so the moss follows the rock's shape), each setting its own look (grass, tinted moss green) with smooth 0.08-0.1, so the moss melts onto the stone: the two looks cross-fade over a band about as wide as the smooth (a sharp join, smooth 0, would keep a sharp line). A big box intersected last trims the base flat on y=0.", build: decoded(mossyStoneJSON))
    }

    static let mossyStoneJSON = #"""
        {"parts": [
          {"name":"Boulder","shape":"sculpt","look":"stone","color":[0.55,0.53,0.5],"resolution":96,"noise":{"amount":0.015,"scale":0.16,"seed":11}},
          {"name":"Rock","shape":"sphere","parent":"Boulder","position":[0,0.24,0],"size":[0.9,0.52,0.7]},
          {"name":"Shoulder","shape":"sphere","parent":"Boulder","position":[0.2,0.3,0.1],"size":[0.5,0.44,0.46],"smooth":0.1},
          {"name":"Moss","shape":"sphere","parent":"Boulder","position":[-0.04,0.27,-0.02],"size":[0.72,0.5,0.56],"smooth":0.1,"look":"grass","color":[0.3,0.42,0.14],"lookScale":0.3},
          {"name":"Moss Back","shape":"sphere","parent":"Boulder","position":[0.2,0.3,0.13],"size":[0.42,0.48,0.42],"smooth":0.08,"look":"grass","color":[0.3,0.42,0.14],"lookScale":0.3},
          {"name":"Trim","shape":"box","parent":"Boulder","position":[0,0.5,0],"size":[2,1,2],"blend":"intersect"}
        ]}
        """#
}
