import EditorCore
import Engine
import Foundation

// A sculpt made with sweeps (MeshBuildSculptLooks.swift, MeshBuildMeshSDF.swift): written as the
// file format, like the curve examples.

extension MeshBuildExamples {
    /// A glazed ceramic teapot: a lathe body and lid, a swept spout and handle melted on, a lid
    /// knob in another glaze.
    public static var teapot: MeshBuildExample {
        MeshBuildExample(name: "Teapot", about: "0.42 m from spout tip to handle, 0.22 m tall, spout toward -X (on the right seen from the front). One sculpt with the ceramic look: the body and lid are lathes, the spout and handle are sweeps melted on with smooth (sweeps, lofts and deformed shapes work in sculpts like any shape), a thin torus subtracted at the lid's edge draws the lid seam and a short cylinder subtracted at the spout's tip opens it. The knob sets its own color and look, so it is drawn in a cream glaze with its own mesh and material; it melts into the lid with smooth 0.015, so the two glazes blend over about 2 cm where the surfaces meet (smooth 0 would keep a sharp line). resolution 120 keeps the 2.4 cm handle round.", build: decoded(teapotJSON))
    }

    static let teapotJSON = #"""
        {"parts": [
          {"name":"Teapot","shape":"sculpt","look":"ceramic","color":[0.16,0.34,0.5],"resolution":120},
          {"name":"Body","shape":"lathe","parent":"Teapot","segments":48,"profile":[[0,0],[0.068,0],[0.072,0.0026],[0.0776,0.0062],[0.084,0.0107],[0.09,0.016],[0.0957,0.0222],[0.1016,0.0293],[0.1072,0.037],[0.112,0.045],[0.1161,0.0534],[0.1196,0.0624],[0.1224,0.0715],[0.124,0.08],[0.1244,0.088],[0.1237,0.0956],[0.1222,0.103],[0.12,0.11],[0.117,0.1168],[0.1131,0.1233],[0.1087,0.1294],[0.104,0.135],[0.0984,0.1402],[0.092,0.1451],[0.0861,0.1491],[0.082,0.152],[0,0.152]]},
          {"name":"Lid","shape":"lathe","parent":"Teapot","segments":48,"profile":[[0,0.148],[0.082,0.148],[0.0819,0.15],[0.0819,0.1529],[0.0814,0.1564],[0.08,0.16],[0.0777,0.164],[0.0746,0.1685],[0.0708,0.173],[0.066,0.177],[0.0602,0.1806],[0.0535,0.1839],[0.046,0.1867],[0.038,0.189],[0.0283,0.1905],[0.0172,0.1912],[0.0071,0.1917],[0,0.192]]},
          {"name":"Lid Seam","shape":"torus","parent":"Teapot","position":[0,0.152,0],"size":[0.174,0.01,0.174],"blend":"subtract","smooth":0.002},
          {"name":"Spout","shape":"sweep","parent":"Teapot","radius":0.02,"radii":[1.7,1.1,0.85,0.75],"path":[[-0.07,0.05,0],[-0.14,0.07,0],[-0.175,0.115,0],[-0.2,0.175,0]],"smooth":0.02},
          {"name":"Spout Opening","shape":"cylinder","parent":"Teapot","position":[-0.201,0.178,0],"rotation":[0,0,23],"size":[0.017,0.06,0.017],"blend":"subtract","smooth":0.002},
          {"name":"Handle","shape":"sweep","parent":"Teapot","radius":0.012,"radii":[1.3,1,1,1,1.3],"path":[[0.1,0.125,0],[0.165,0.135,0],[0.196,0.095,0],[0.18,0.05,0],[0.105,0.035,0]],"smooth":0.012},
          {"name":"Knob","shape":"sphere","parent":"Teapot","position":[0,0.2,0],"size":[0.046,0.036,0.046],"smooth":0.015,"look":"ceramic","color":[0.9,0.85,0.74]}
        ]}
        """#
}
