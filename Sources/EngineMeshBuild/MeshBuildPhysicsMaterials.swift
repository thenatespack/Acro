// Physics materials of mesh builds and terrains (PhysicsMaterial.swift): what placed copies are
// made of, for colliders' friction, bounce and density and for footstep, impact and scrape
// effects.
//
// - Mesh builds: a part's `physicsMaterial`, else the material its `look` implies (oak → wood,
//   rusty metal → metal…). The prefab root gets the most common one (ties: the first part's), so
//   a `Collider` added to a placed copy uses it; parts made of something else get their own
//   `PhysicsSurface` (for colliders under them).
// - Terrains: each layer's `physicsMaterial`. Chunk colliders get a `PhysicsSurface` whose grid
//   names, per terrain cell, the material of the layer painted most there (cells of layers
//   without one use the chunk's most common material).
import EngineAssets
import EngineCore
import EnginePhysics
import EngineScene

extension MeshBuildLook {
    /// The built-in physics material the look is made of.
    public var physicsMaterial: String {
        switch self {
        case .wood, .paintedWood, .planks, .bark: "wood"
        case .brushedMetal, .polishedMetal, .paintedMetal, .rustyMetal, .gold, .copper, .brass: "metal"
        case .stone, .cobblestone: "stone"
        case .concrete: "concrete"
        case .brick: "brick"
        case .ceramic: "ceramic"
        case .plastic: "plastic"
        case .rubber: "rubber"
        case .glass: "glass"
        case .fabric, .leather: "fabric"
        case .dirt: "dirt"
        case .grass: "grass"
        }
    }
}

extension MeshBuildPart {
    /// The part's physics material: `physicsMaterial`, else its look's; nil for neither.
    public var resolvedPhysicsMaterial: String? {
        if let name = physicsMaterial?.trimmingCharacters(in: .whitespaces), !name.isEmpty { return name }
        return resolvedLook?.physicsMaterial
    }
}

extension MeshBuildImporter {
    /// Gives `nodes` (one per part of `build`) their physics surfaces and returns the root's;
    /// warns about names that are neither built-in nor a `.physmat` file in the project.
    static func assignPhysicsSurfaces(_ build: MeshBuild, to nodes: inout [PrefabNode], _ context: inout ImportContext) -> PhysicsSurface? {
        let names = build.parts.map(\.resolvedPhysicsMaterial)
        var warned: Set<String> = []
        for (part, name) in zip(build.parts, names) {
            guard let name, part.physicsMaterial != nil, !warned.contains(name) else { continue }
            let known = PhysicsMaterial.builtIn(named: name) != nil
                || (name.hasSuffix(".physmat") && context.assetsByPath[name.hasPrefix("Assets/") ? String(name.dropFirst(7)) : name] != nil)
                || name.hasPrefix(AssetReference.scheme)
            if !known {
                warned.insert(name)
                context.warn("part '\(part.name)': physicsMaterial '\(name)' is neither a built-in (\(PhysicsMaterial.builtInNames.joined(separator: ", "))) nor a .physmat file")
            }
        }
        // The most common material (ties: the first part's) for the root.
        var counts: [String: Int] = [:]
        var order: [String] = []
        for name in names.compactMap({ $0 }) {
            if counts[name] == nil { order.append(name) }
            counts[name, default: 0] += 1
        }
        guard let main = order.max(by: { counts[$0]! < counts[$1]! || (counts[$0]! == counts[$1]! && order.firstIndex(of: $0)! > order.firstIndex(of: $1)!) })
        else { return nil }
        for i in nodes.indices where i < names.count {
            if let name = names[i], name != main { nodes[i].physicsSurface = PhysicsSurface(material: name) }
        }
        return PhysicsSurface(material: main)
    }
}

extension Terrain {
    /// Chunk `(cx, cz)`'s physics surface: per cell, the physics material of the layer painted
    /// most there. Nil when no layer names one.
    public func chunkPhysicsSurface(_ cx: Int, _ cz: Int) -> PhysicsSurface? {
        let named = layers.map { $0.physicsMaterial.trimmingCharacters(in: .whitespaces) }
        guard named.contains(where: { !$0.isEmpty }) else { return nil }
        var palette: [String] = []
        var index: [String: UInt8] = [:]
        for name in named where !name.isEmpty && index[name] == nil && palette.count < 255 {
            index[name] = UInt8(palette.count)
            palette.append(name)
        }
        let range = chunkRange(cx, cz)
        let columns = range.x.upperBound - range.x.lowerBound, rows = range.z.upperBound - range.z.lowerBound
        guard columns > 0, rows > 0 else { return nil }
        var cells = [UInt8](repeating: 255, count: columns * rows)
        var counts = [Int](repeating: 0, count: palette.count)
        for row in 0..<rows {
            for column in 0..<columns {
                let x = range.x.lowerBound + column, z = range.z.lowerBound + row
                // The layer with the most weight over the cell's four corners.
                var best = -1
                var bestWeight: Float = 0
                for layer in layers.indices {
                    let w = weight(layer: layer, x: x, z: z) + weight(layer: layer, x: x + 1, z: z)
                        + weight(layer: layer, x: x, z: z + 1) + weight(layer: layer, x: x + 1, z: z + 1)
                    if w > bestWeight {
                        bestWeight = w
                        best = layer
                    }
                }
                guard best >= 0, let slot = index[named[best]] else { continue }
                cells[row * columns + column] = slot
                counts[Int(slot)] += 1
            }
        }
        let main = counts.indices.max { counts[$0] < counts[$1] || (counts[$0] == counts[$1] && $0 > $1) }.map { palette[$0] } ?? palette[0]
        let origin = position(x: range.x.lowerBound, z: range.z.lowerBound)
        return PhysicsSurface(material: main, regions: PhysicsSurfaceGrid(materials: palette, origin: origin, cellSize: cellSize,
                                                                           columns: columns, rows: rows, cells: cells))
    }
}
