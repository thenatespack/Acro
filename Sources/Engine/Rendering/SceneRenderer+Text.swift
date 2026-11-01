import Foundation

/// `SceneRenderer`'s world-text hook: `prepare` / `beginViews` gather the world's `TextMesh`es
/// (see `WorldTextRenderer`), and each view draws them after the particles, in the same pass.
/// The renderer is made with the first `TextMesh`; a world without any costs one count per frame.
extension SceneRenderer {
    func prepareWorldText(world: World) {
        if worldText == nil {
            guard world.count(of: TextMesh.self) > 0 else { return }
            do {
                worldText = try WorldTextRenderer(device: device)
            } catch {
                print("SceneRenderer: world text unavailable: \(error)")
                return
            }
        }
        worldText?.prepare(world: world, assets: assets)
    }

    func drawWorldText(in pass: RenderPass, uniforms: FrameUniforms, view: Mat4?, reversedZ: Bool) {
        guard let worldText, let view else { return }
        let eye = uniforms.cameraPos
        worldText.draw(in: pass, view: view, eye: Vec3(eye.x, eye.y, eye.z), reversedZ: reversedZ)
    }
}
