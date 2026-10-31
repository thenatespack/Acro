import Foundation

/// `SceneRenderer`'s particle hook: `prepare` / `beginViews` gather the world's
/// `ParticleEmitter`s, `renderShadows` / `beginViews` record their compute pass, and each
/// view draws them after the transparent meshes (the transparent stage), in the same pass.
///
/// Soft particles and depth collisions need the scene's depth, which the scene pass can't read
/// while it renders into it: when an emitter asks for it (`ParticleEmitter.needsSceneDepth`), a
/// depth prepass renders the view's opaque batches (the frame's culled list and instances, the
/// shadow shaders without bias) into a single-sample depth texture at the pass's size first:
/// `renderShadows` for the `prepare` camera (before the particles' compute pass, which collides
/// against it), `renderView` per view (soft particles only). Without such an emitter nothing
/// extra is rendered.
extension SceneRenderer {
    /// Creates `particles` on the first `ParticleEmitter`, then has it schedule this frame.
    func prepareParticles(world: World, cameraPosition: Vec3) {
        if particles == nil {
            guard world.count(of: ParticleEmitter.self) > 0 else { return }
            do {
                particles = try ParticleSystem(device: device)
                particles?.textureResolver = { [unowned self] in texture($0) }
            } catch {
                print("SceneRenderer: particles unavailable: \(error)")
                return
            }
        }
        particles?.prepare(world: world, cameraPosition: cameraPosition)
    }

    /// The `prepare` camera's depth prepass, if an emitter needs it; hands it to the particles.
    func renderParticleDepth(frame: Frame) {
        particleDepth = nil
        particles?.sceneDepth = nil
        guard let particles, particles.needsSceneDepth, let view = particleView,
              let texture = depthTexture(&particleDepthTexture, size: view.size) else { return }
        renderDepthPrepass(into: texture, list: list, instances: uploaded, viewProjection: view.viewProjection,
                           reversedZ: view.reversedZ, frame: frame)
        let depth = ParticleSceneDepth(texture: texture, viewProjection: view.viewProjection, projection: view.projection,
                                       cameraPosition: view.eye)
        particleDepth = depth
        particles.sceneDepth = depth
    }

    /// `renderView`'s depth prepass for `view`, if an emitter needs it.
    func renderViewParticleDepth(list: RenderList, instances: TransientBuffer?, view: SceneView, size: (width: Int, height: Int),
                                 frame: Frame) -> ParticleSceneDepth? {
        guard let particles, particles.needsSceneDepth else { return nil }
        var texture = viewParticleDepthTextures[[size.width, size.height]]
        if texture == nil, viewParticleDepthTextures.count >= 4 { viewParticleDepthTextures.removeAll() }
        guard let texture = depthTexture(&texture, size: size) else { return nil }
        viewParticleDepthTextures[[size.width, size.height]] = texture
        renderDepthPrepass(into: texture, list: list, instances: instances, viewProjection: view.viewProjection,
                           reversedZ: view.reversedZ, frame: frame)
        return ParticleSceneDepth(texture: texture, viewProjection: view.viewProjection, projection: view.projection,
                                  cameraPosition: view.eye)
    }

    /// `texture`, recreated at `size` if it has another.
    private func depthTexture(_ texture: inout GPUTexture?, size: (width: Int, height: Int)) -> GPUTexture? {
        if let current = texture, current.width == size.width, current.height == size.height { return current }
        do {
            texture = try device.makeTexture(TextureDescriptor(width: max(size.width, 1), height: max(size.height, 1), format: .depth32Float))
        } catch {
            print("SceneRenderer: particle depth texture of \(size.width)x\(size.height) unavailable: \(error)")
            texture = nil
        }
        return texture
    }

    /// Draws the particles with the view's (jittered) view-projection and camera position, soft
    /// against `depth` (the view's depth prepass).
    func drawParticles(in pass: RenderPass, uniforms: FrameUniforms, reversedZ: Bool, depth: ParticleSceneDepth?) {
        guard let particles else { return }
        let eye = uniforms.cameraPos
        particles.draw(in: pass, viewProjection: uniforms.viewProj, cameraPosition: Vec3(eye.x, eye.y, eye.z), reversedZ: reversedZ,
                       sceneDepth: depth)
    }
}
