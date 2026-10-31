import Foundation

/// `SceneRenderer`'s particle hook: `prepare` / `beginViews` gather the world's
/// `ParticleEmitter`s, `renderShadows` / `beginViews` record their compute pass, and each
/// view draws them after the transparent meshes (the transparent stage), in the same pass.
extension SceneRenderer {
    /// Creates `particles` on the first `ParticleEmitter`, then has it schedule this frame.
    func prepareParticles(world: World, cameraPosition: Vec3) {
        if particles == nil {
            guard world.count(of: ParticleEmitter.self) > 0 else { return }
            do {
                particles = try ParticleSystem(device: device)
            } catch {
                print("SceneRenderer: particles unavailable: \(error)")
                return
            }
        }
        particles?.prepare(world: world, cameraPosition: cameraPosition)
    }

    /// Draws the particles with the view's (jittered) view-projection and camera position.
    func drawParticles(in pass: RenderPass, uniforms: FrameUniforms, reversedZ: Bool) {
        guard let particles else { return }
        let eye = uniforms.cameraPos
        particles.draw(in: pass, viewProjection: uniforms.viewProj, cameraPosition: Vec3(eye.x, eye.y, eye.z), reversedZ: reversedZ)
    }
}
