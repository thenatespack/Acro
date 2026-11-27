/// The binding header of a GLSL ES 3.00 stage that Scripts/spirv-to-gles.c generates (see the
/// table in `ShaderSource`): its uniform blocks and samplers, by the set and binding they had in
/// the GLSL. The WebGL 2 device binds blocks to binding points and samplers to texture units with it.
struct GLESInterface: Equatable, Sendable {
    struct UniformBlock: Equatable, Sendable {
        var name: String
        /// The set and binding of the GLSL block; nil for push constants.
        var set: Int?
        var binding: Int?

        /// The WebGL 2 binding point: 0 for the per-frame block, 1 for push constants, n for
        /// uniform buffer n (set 2, binding n), 8 + n for storage buffer n read as a uniform block
        /// (set 2, binding 24 + n: the material graph templates' values); nil outside the table.
        var bindingPoint: Int? {
            guard let set, let binding else { return 1 }
            if set == 0 && binding == 0 { return 0 }
            if set == 2 && (2...7).contains(binding) { return binding }
            if set == 2 && (24...31).contains(binding) { return binding - 16 }
            return nil
        }
    }

    struct Sampler: Equatable, Sendable {
        var name: String
        var textureSet: Int
        var textureBinding: Int
        /// The sampler's set and binding (equal to the texture's for one combined in the GLSL),
        /// nil for a texture read without a sampler (texelFetch).
        var samplerSet: Int?
        var samplerBinding: Int?
        /// A `sampler2DShadow` (depth comparison).
        var shadow: Bool

        /// The engine's texture slot: 0 for set 1 (the shadow map, or the backend's own image),
        /// n for `setTexture(_:index: n)` (set 2, binding 8 + n); nil outside the table.
        var textureSlot: Int? {
            if textureSet == 1 && textureBinding == 0 { return 0 }
            if textureSet == 2 && (9...15).contains(textureBinding) { return textureBinding - 8 }
            return nil
        }

        /// For a texture at set 2, binding 24 + n: storage buffer n read as a texture (an RGBA32UI
        /// copy of the buffer, 1024 texels of 16 bytes per row: the probe-lit shaders' GLSL ES).
        var storageSlot: Int? {
            textureSet == 2 && (24...31).contains(textureBinding) ? textureBinding - 24 : nil
        }

        /// The engine's sampler slot: 0 for set 1, n for `setSampler(_:index: n)` (set 2, binding
        /// 16 + n), nil without a sampler or outside the table.
        var samplerSlot: Int? {
            guard let samplerSet, let samplerBinding else { return nil }
            if samplerSet == 1 && samplerBinding <= 1 { return 0 }
            if samplerSet == 2 && (17...23).contains(samplerBinding) { return samplerBinding - 16 }
            return nil
        }
    }

    var uniformBlocks: [UniformBlock] = []
    var samplers: [Sampler] = []

    /// Reads the `// acro-ubo` and `// acro-sampler` lines at the top of `source` (they end at
    /// the first line that is neither those nor another comment).
    init(source: String) {
        for line in source.split(separator: "\n", omittingEmptySubsequences: false).dropFirst() {
            guard line.hasPrefix("//") else { break }
            let fields = line.split(separator: " ")
            guard fields.count >= 2 else { continue }
            let numbers = fields.dropFirst(3).map { Int($0) ?? -1 }
            switch fields[1] {
            case "acro-ubo" where fields.count == 5:
                let set = numbers[0], binding = numbers[1]
                uniformBlocks.append(UniformBlock(name: String(fields[2]), set: set < 0 ? nil : set, binding: binding < 0 ? nil : binding))
            case "acro-sampler" where fields.count == 8:
                samplers.append(Sampler(name: String(fields[2]), textureSet: numbers[0], textureBinding: numbers[1],
                                        samplerSet: numbers[2] < 0 ? nil : numbers[2], samplerBinding: numbers[3] < 0 ? nil : numbers[3],
                                        shadow: numbers[4] == 1))
            default:
                continue
            }
        }
    }

    init(uniformBlocks: [UniformBlock], samplers: [Sampler]) {
        self.uniformBlocks = uniformBlocks
        self.samplers = samplers
    }
}
