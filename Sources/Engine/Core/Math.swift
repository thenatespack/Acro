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

    /// Translation * rotation * scale: scales first, then rotates, then translates.
    public init(translation t: Vec3, rotation q: Quat, scale s: Vec3) {
        let r = q.matrix
        self.init(r.c0 * s.x, r.c1 * s.y, r.c2 * s.z, Vec4(t.x, t.y, t.z, 1))
    }

    /// The general inverse (cofactors over the determinant). A singular matrix yields
    /// non-finite values.
    public var inverse: Mat4 {
        // Laplace expansion: 2x2 minors of rows 0-1 (s*) and rows 2-3 (k*) of the columns.
        let (a, b, c, d) = (c0, c1, c2, c3)
        let s0 = a.x * b.y - b.x * a.y, s1 = a.x * c.y - c.x * a.y, s2 = a.x * d.y - d.x * a.y
        let s3 = b.x * c.y - c.x * b.y, s4 = b.x * d.y - d.x * b.y, s5 = c.x * d.y - d.x * c.y
        let k5 = c.z * d.w - d.z * c.w, k4 = b.z * d.w - d.z * b.w, k3 = b.z * c.w - c.z * b.w
        let k2 = a.z * d.w - d.z * a.w, k1 = a.z * c.w - c.z * a.w, k0 = a.z * b.w - b.z * a.w
        let det = s0 * k5 - s1 * k4 + s2 * k3 + s3 * k2 - s4 * k1 + s5 * k0
        let r = 1 / det
        return Mat4(
            Vec4(
                (b.y * k5 - c.y * k4 + d.y * k3) * r,
                (-a.y * k5 + c.y * k2 - d.y * k1) * r,
                (a.y * k4 - b.y * k2 + d.y * k0) * r,
                (-a.y * k3 + b.y * k1 - c.y * k0) * r),
            Vec4(
                (-b.x * k5 + c.x * k4 - d.x * k3) * r,
                (a.x * k5 - c.x * k2 + d.x * k1) * r,
                (-a.x * k4 + b.x * k2 - d.x * k0) * r,
                (a.x * k3 - b.x * k1 + c.x * k0) * r),
            Vec4(
                (b.w * s5 - c.w * s4 + d.w * s3) * r,
                (-a.w * s5 + c.w * s2 - d.w * s1) * r,
                (a.w * s4 - b.w * s2 + d.w * s0) * r,
                (-a.w * s3 + b.w * s1 - c.w * s0) * r),
            Vec4(
                (-b.z * s5 + c.z * s4 - d.z * s3) * r,
                (a.z * s5 - c.z * s2 + d.z * s1) * r,
                (-a.z * s4 + b.z * s2 - d.z * s0) * r,
                (a.z * s3 - b.z * s1 + c.z * s0) * r)
        )
    }
}

/// Unit quaternion for rotations: `x, y, z` imaginary, `w` real. Composes like matrices:
/// `a * b` rotates by `b` first, then by `a`, and `(a * b).matrix == a.matrix * b.matrix`.
public struct Quat: Equatable, Sendable, BitwiseCopyable {
    /// (x, y, z, w).
    public var vector: Vec4

    @inlinable public init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) { vector = Vec4(x, y, z, w) }
    @inlinable public init(vector: Vec4) { self.vector = vector }

    public static let identity = Quat(0, 0, 0, 1)

    /// Rotation of `angle` radians around `axis` (right-hand rule, like `Mat4.rotation`).
    public init(angle: Float, axis: Vec3) {
        let a = normalize(axis) * sinf(angle * 0.5)
        vector = Vec4(a.x, a.y, a.z, cosf(angle * 0.5))
    }

    /// The rotation part of `m`, whose upper 3x3 must be orthonormal (no scale or shear).
    public init(rotationMatrix m: Mat4) {
        // Shepperd's method: divide by the largest of the four candidates for stability.
        let (m00, m11, m22) = (m.c0.x, m.c1.y, m.c2.z)
        let trace = m00 + m11 + m22
        if trace > 0 {
            let s = (trace + 1).squareRoot() * 2
            self.init((m.c1.z - m.c2.y) / s, (m.c2.x - m.c0.z) / s, (m.c0.y - m.c1.x) / s, 0.25 * s)
        } else if m00 > m11 && m00 > m22 {
            let s = (1 + m00 - m11 - m22).squareRoot() * 2
            self.init(0.25 * s, (m.c1.x + m.c0.y) / s, (m.c2.x + m.c0.z) / s, (m.c1.z - m.c2.y) / s)
        } else if m11 > m22 {
            let s = (1 + m11 - m00 - m22).squareRoot() * 2
            self.init((m.c1.x + m.c0.y) / s, 0.25 * s, (m.c2.y + m.c1.z) / s, (m.c2.x - m.c0.z) / s)
        } else {
            let s = (1 + m22 - m00 - m11).squareRoot() * 2
            self.init((m.c2.x + m.c0.z) / s, (m.c2.y + m.c1.z) / s, 0.25 * s, (m.c0.y - m.c1.x) / s)
        }
    }

    @inlinable public var x: Float { vector.x }
    @inlinable public var y: Float { vector.y }
    @inlinable public var z: Float { vector.z }
    @inlinable public var w: Float { vector.w }
    @inlinable public var imaginary: Vec3 { Vec3(vector.x, vector.y, vector.z) }

    @inlinable public var length: Float { (vector * vector).sum().squareRoot() }

    @inlinable public var normalized: Quat {
        let len = length
        return len > 0 ? Quat(vector: vector / len) : .identity
    }

    /// The inverse of a unit quaternion.
    @inlinable public var conjugate: Quat { Quat(-vector.x, -vector.y, -vector.z, vector.w) }

    /// The inverse of any nonzero quaternion.
    @inlinable public var inverse: Quat { Quat(vector: conjugate.vector / (vector * vector).sum()) }

    @inlinable public static func * (a: Quat, b: Quat) -> Quat {
        let (av, bv) = (a.imaginary, b.imaginary)
        let v = a.w * bv + b.w * av + cross(av, bv)
        return Quat(v.x, v.y, v.z, a.w * b.w - dot(av, bv))
    }

    /// Rotates `v` (assumes a unit quaternion).
    @inlinable public static func * (q: Quat, v: Vec3) -> Vec3 {
        let u = q.imaginary
        let t = 2 * cross(u, v)
        return v + q.w * t + cross(u, t)
    }

    /// The rotation as a matrix (assumes a unit quaternion).
    public var matrix: Mat4 {
        let (x, y, z, w) = (vector.x, vector.y, vector.z, vector.w)
        return Mat4(
            Vec4(1 - 2 * (y * y + z * z), 2 * (x * y + w * z), 2 * (x * z - w * y), 0),
            Vec4(2 * (x * y - w * z), 1 - 2 * (x * x + z * z), 2 * (y * z + w * x), 0),
            Vec4(2 * (x * z + w * y), 2 * (y * z - w * x), 1 - 2 * (x * x + y * y), 0),
            Vec4(0, 0, 0, 1)
        )
    }

    /// Spherical interpolation along the shorter arc; `t` = 0 gives `a`, 1 gives `b`
    /// (or `-b`, the same rotation).
    public static func slerp(_ a: Quat, _ b: Quat, _ t: Float) -> Quat {
        var bv = b.vector
        var d = (a.vector * bv).sum()
        if d < 0 { bv = -bv; d = -d }
        // Nearly parallel: sin(theta) ~ 0, so fall back to a normalized lerp.
        if d > 0.9995 { return Quat(vector: a.vector + (bv - a.vector) * t).normalized }
        let theta = acosf(d)
        let s = sinf(theta)
        return Quat(vector: (a.vector * sinf((1 - t) * theta) + bv * sinf(t * theta)) / s)
    }
}

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(ucrt)
import ucrt
#endif
