// Portable math built on the stdlib SIMD types (the `simd` module is Apple-only).
// Conventions: right-handed, column-major matrices, clip-space depth in [0, 1]
// (matches both Metal and Vulkan).

public typealias Vec2 = SIMD2<Float>
public typealias Vec3 = SIMD3<Float>
public typealias Vec4 = SIMD4<Float>

@inlinable public func dot(_ a: Vec3, _ b: Vec3) -> Float { (a * b).sum() }

@inlinable public func cross(_ a: Vec3, _ b: Vec3) -> Vec3 {
    Vec3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
}

@inlinable public func length(_ v: Vec3) -> Float { dot(v, v).squareRoot() }

@inlinable public func normalize(_ v: Vec3) -> Vec3 {
    let len = length(v)
    return len > 0 ? v / len : v
}

/// 4x4 column-major matrix. Memory layout is four contiguous `Vec4` columns
/// (64 bytes), identical to `float4x4` in MSL and `mat4` in GLSL.
public struct Mat4: Equatable, Sendable, BitwiseCopyable {
    public var c0, c1, c2, c3: Vec4

    @inlinable public init(_ c0: Vec4, _ c1: Vec4, _ c2: Vec4, _ c3: Vec4) {
        (self.c0, self.c1, self.c2, self.c3) = (c0, c1, c2, c3)
    }

    public static let identity = Mat4(Vec4(1, 0, 0, 0), Vec4(0, 1, 0, 0), Vec4(0, 0, 1, 0), Vec4(0, 0, 0, 1))

    @inlinable public static func * (m: Mat4, v: Vec4) -> Vec4 {
        m.c0 * v.x + m.c1 * v.y + m.c2 * v.z + m.c3 * v.w
    }

    @inlinable public static func * (a: Mat4, b: Mat4) -> Mat4 {
        Mat4(a * b.c0, a * b.c1, a * b.c2, a * b.c3)
    }

    public static func translation(_ t: Vec3) -> Mat4 {
        Mat4(Vec4(1, 0, 0, 0), Vec4(0, 1, 0, 0), Vec4(0, 0, 1, 0), Vec4(t.x, t.y, t.z, 1))
    }

    public static func scale(_ s: Vec3) -> Mat4 {
        Mat4(Vec4(s.x, 0, 0, 0), Vec4(0, s.y, 0, 0), Vec4(0, 0, s.z, 0), Vec4(0, 0, 0, 1))
    }

    /// Rotation of `angle` radians around `axis`.
    public static func rotation(angle: Float, axis: Vec3) -> Mat4 {
        let a = normalize(axis)
        let (x, y, z) = (a.x, a.y, a.z)
        let c = cosf(angle), s = sinf(angle), t = 1 - c
        return Mat4(
            Vec4(t * x * x + c, t * x * y + s * z, t * x * z - s * y, 0),
            Vec4(t * x * y - s * z, t * y * y + c, t * y * z + s * x, 0),
            Vec4(t * x * z + s * y, t * y * z - s * x, t * z * z + c, 0),
            Vec4(0, 0, 0, 1)
        )
    }

    /// Right-handed perspective projection mapping depth to [0, 1].
    public static func perspective(fovY: Float, aspect: Float, near: Float, far: Float) -> Mat4 {
        let ys = 1 / tanf(fovY * 0.5)
        let xs = ys / aspect
        let zs = far / (near - far)
        return Mat4(Vec4(xs, 0, 0, 0), Vec4(0, ys, 0, 0), Vec4(0, 0, zs, -1), Vec4(0, 0, zs * near, 0))
    }

    /// Right-handed orthographic projection mapping depth to [0, 1] (`near` → 0, `far` → 1).
    public static func orthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> Mat4 {
        let w = right - left, h = top - bottom, d = near - far
        return Mat4(
            Vec4(2 / w, 0, 0, 0),
            Vec4(0, 2 / h, 0, 0),
            Vec4(0, 0, 1 / d, 0),
            Vec4(-(right + left) / w, -(top + bottom) / h, near / d, 1)
        )
    }

    /// Right-handed view matrix looking from `eye` toward `target`.
    public static func lookAt(eye: Vec3, target: Vec3, up: Vec3 = Vec3(0, 1, 0)) -> Mat4 {
        let f = normalize(target - eye)
        let s = normalize(cross(f, up))
        let u = cross(s, f)
        return Mat4(
            Vec4(s.x, u.x, -f.x, 0),
            Vec4(s.y, u.y, -f.y, 0),
            Vec4(s.z, u.z, -f.z, 0),
            Vec4(-dot(s, eye), -dot(u, eye), dot(f, eye), 1)
        )
    }
}

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(ucrt)
import ucrt
#endif
