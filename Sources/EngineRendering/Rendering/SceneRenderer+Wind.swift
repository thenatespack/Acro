/// Wind sway (Wind.swift, wind.glsl): materials with `Material.wind` draw with mesh_wind.vert in
/// the lit passes and mesh_shadow_wind.vert in the shadow and depth passes, their uniform
/// buffer 2 extended with the wind block (bound to both stages). Everything else draws exactly
/// as before.
import EngineAssets
import EngineCore
import EngineGraphics
import EngineScene

extension SceneRenderer {
    /// The scene's wind and clock for this frame, from the gathered world.
    struct WindState {
        var wind = Wind.calm
        var time: Float = 0
        var previousTime: Float = 0

        /// Advances to `time` seconds with the world's `wind`. A jump (the clock wrapped, a new
        /// world) restarts the motion history, so it doesn't smear.
        mutating func advance(to time: Float, wind: Wind) {
            previousTime = abs(time - self.time) > 1 ? time : self.time
            self.time = time
            self.wind = wind
        }
    }

    /// Vec4s of the block wind.glsl declares: the material (padded to 8) and plant, axis, global, clock.
    static let windBlockVec4s = 12

    /// The material's uniforms followed by its wind and the frame's (wind.glsl's `WindData`).
    static func windBlock(_ uniforms: MaterialUniforms, wind materialWind: MaterialWind, state: WindState) -> [Vec4] {
        var block = [Vec4](repeating: .zero, count: windBlockVec4s)
        precondition(MemoryLayout<MaterialUniforms>.size <= 8 * MemoryLayout<Vec4>.stride)
        block.withUnsafeMutableBufferPointer { out in
            withUnsafeBytes(of: uniforms) { UnsafeMutableRawBufferPointer(out).copyMemory(from: $0) }
            out[8] = materialWind.plantVector
            out[9] = materialWind.axisVector
            let dir = state.wind.horizontalDirection
            out[10] = Vec4(dir.x, dir.y, state.wind.effectiveStrength, state.wind.effectiveGustiness)
            out[11] = Vec4(state.time, state.previousTime, 0, 0)
        }
        return block
    }

    /// Binds `material`'s uniform buffer 2 with its wind block, for both stages.
    func bindWind(_ uniforms: MaterialUniforms, wind: MaterialWind, in pass: RenderPass) {
        Self.windBlock(uniforms, wind: wind, state: windState).withUnsafeBytes { pass.setUniformData($0, index: 2, stage: .all) }
    }

    /// The lit shader with the swaying vertex stage (mesh_wind.vert), alpha-tested or not.
    func windShader(painted: Bool = false, alphaTested: Bool) -> ShaderSource? {
        do {
            // Painted meshes (vertex paint: leaf card variation, sculpt blends) sway through
            // mesh_paint_wind.vert, which pairs with the paint fragment shaders.
            if painted {
                return try ShaderSource.load(vertex: "mesh_paint_wind", fragment: alphaTested ? "mesh_paint_mask" : "mesh_paint",
                                             bundle: .engineResources)
            }
            return try ShaderSource.load(vertex: "mesh_wind", fragment: alphaTested ? "mesh_mask" : "mesh", bundle: .engineResources)
        } catch {
            print("SceneRenderer: wind shader unavailable: \(error)")
            return nil
        }
    }

    /// A depth-only pipeline for swaying casters: shadow (biased) or prepass, alpha-tested or not.
    func windDepthPipeline(_ variant: DepthVariant, alphaTested: Bool) -> RenderPipeline? {
        let key = WindDepthKey(variant: variant, alphaTested: alphaTested)
        if let pipeline = windDepthPipelines[key] { return pipeline }
        do {
            // Without alpha testing the fragment stage is left out (`depthOnlyFragment`).
            let shader = try ShaderSource.load(vertex: "mesh_shadow_wind", fragment: "mesh_shadow_mask", bundle: .engineResources)
            var descriptor = PipelineDescriptor(shader: shader, vertexLayout: MeshVertex.layout, instanceLayout: MeshInstance.layout)
            descriptor.target = .depthOnly
            descriptor.depthOnlyFragment = alphaTested
            descriptor.cullMode = .none
            switch variant {
            case .shadow: descriptor.depthBias = DepthBias(constant: 1.5, slopeScale: 2.5)
            case .prepass(let reversedZ): descriptor.depthCompare = reversedZ ? .greater : .less
            }
            let pipeline = try device.makePipeline(descriptor)
            windDepthPipelines[key] = pipeline
            return pipeline
        } catch {
            print("SceneRenderer: wind depth pipeline creation failed: \(error)")
            return nil
        }
    }

    struct WindDepthKey: Hashable {
        var variant: DepthVariant
        var alphaTested: Bool
    }
}
