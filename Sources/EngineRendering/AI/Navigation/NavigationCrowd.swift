#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore

// Crowd avoidance: ORCA (optimal reciprocal collision avoidance, the RVO2 algorithm by van den
// Berg, Guy, Lin and Manocha) on the XZ plane.
//
// Each agent wants to move at its preferred velocity. For every neighbour within
// `neighborDistance` (the `maxNeighbors` nearest, on the same floor: heights within
// `layerHeight`), the velocities that would collide within `timeHorizon` seconds form a
// truncated cone; the agent takes its share (half, or all of it against an agent that doesn't
// avoid) of the smallest change that leaves the cone, which is a half-plane of allowed
// velocities. The new velocity is the one nearest the preferred velocity inside every
// half-plane and under the agent's top speed (a 2D linear program); when the constraints can't
// all be met (a dense crowd), the one that violates them least. Agents that already overlap
// push apart within one step. Deterministic: same input, same output.

/// One agent for `NavigationCrowd.solve`.
public struct CrowdAgent: Equatable, Sendable {
    public var position: Vec3
    /// Its velocity now (last frame's result).
    public var velocity: Vec3
    /// Where it wants to go this frame, as a velocity.
    public var preferredVelocity: Vec3
    public var radius: Float
    public var maxSpeed: Float
    /// False: it doesn't steer around others (an obstacle others avoid on their own).
    public var avoids: Bool
    /// The index of an agent this one doesn't avoid (the one it chases or walks up to).
    public var ignoring: Int?

    public init(position: Vec3, velocity: Vec3 = .zero, preferredVelocity: Vec3 = .zero, radius: Float = 0.4, maxSpeed: Float = 3,
                avoids: Bool = true, ignoring: Int? = nil) {
        self.position = position
        self.velocity = velocity
        self.preferredVelocity = preferredVelocity
        self.radius = radius
        self.maxSpeed = maxSpeed
        self.avoids = avoids
        self.ignoring = ignoring
    }
}

/// ORCA crowd avoidance (see the notes at the top of NavigationCrowd.swift).
public struct NavigationCrowd: Equatable, Sendable {
    /// Seconds ahead agents look for collisions with each other.
    public var timeHorizon: Float
    /// Agents farther apart than this (meters, between centers) ignore each other.
    public var neighborDistance: Float
    public var maxNeighbors: Int
    /// Agents more than this far apart in height are on different floors.
    public var layerHeight: Float

    public init(timeHorizon: Float = 2, neighborDistance: Float = 6, maxNeighbors: Int = 10, layerHeight: Float = 1.5) {
        self.timeHorizon = timeHorizon
        self.neighborDistance = neighborDistance
        self.maxNeighbors = maxNeighbors
        self.layerHeight = layerHeight
    }

    /// The velocity each agent should move at this step (`dt` seconds), in agent order; y is 0.
    /// Agents that don't avoid keep their preferred velocity.
    public func solve(_ agents: [CrowdAgent], dt: Float) -> [Vec3] {
        let count = agents.count
        guard count > 0 else { return [] }
        // Buckets of neighborDistance on XZ.
        let size = max(neighborDistance, 0.5)
        var buckets: [Int64: [Int]] = [:]
        func key(_ x: Int, _ z: Int) -> Int64 { Int64(x) << 32 | Int64(UInt32(bitPattern: Int32(truncatingIfNeeded: z))) }
        func cell(_ p: Vec3) -> (Int, Int) { (Int((p.x / size).rounded(.down)), Int((p.z / size).rounded(.down))) }
        for (i, a) in agents.enumerated() {
            let (cx, cz) = cell(a.position)
            buckets[key(cx, cz), default: []].append(i)
        }
        var out = [Vec3](repeating: .zero, count: count)
        let step = max(dt, 1e-4)
        for i in 0..<count {
            let a = agents[i]
            let preferred = V2(a.preferredVelocity.x, a.preferredVelocity.z)
            guard a.avoids else { out[i] = Vec3(preferred.x, 0, preferred.y); continue }
            // The nearest neighbours.
            var near: [(d: Float, j: Int)] = []
            let (cx, cz) = cell(a.position)
            for bz in (cz - 1)...(cz + 1) {
                for bx in (cx - 1)...(cx + 1) {
                    for j in buckets[key(bx, bz)] ?? [] where j != i && j != a.ignoring {
                        let b = agents[j]
                        guard abs(b.position.y - a.position.y) < layerHeight else { continue }
                        let dx = b.position.x - a.position.x, dz = b.position.z - a.position.z
                        let d = dx * dx + dz * dz
                        let reach = neighborDistance + b.radius
                        guard d < reach * reach else { continue }
                        near.append((d, j))
                    }
                }
            }
            near.sort { $0.d != $1.d ? $0.d < $1.d : $0.j < $1.j }
            if near.count > maxNeighbors { near.removeLast(near.count - maxNeighbors) }

            var lines: [Line] = []
            let velocity = V2(a.velocity.x, a.velocity.z)
            let invHorizon = 1 / max(timeHorizon, 1e-3)
            for (_, j) in near {
                let b = agents[j]
                let relativePosition = V2(b.position.x - a.position.x, b.position.z - a.position.z)
                let relativeVelocity = velocity - V2(b.velocity.x, b.velocity.z)
                let distSq = relativePosition.lengthSquared
                let combinedRadius = a.radius + b.radius
                let combinedRadiusSq = combinedRadius * combinedRadius
                var direction: V2
                var u: V2
                if distSq > combinedRadiusSq {
                    // No collision yet: the cone of velocities that collide within the horizon.
                    let w = relativeVelocity - relativePosition * invHorizon
                    let wLengthSq = w.lengthSquared
                    let dot1 = w.dot(relativePosition)
                    if dot1 < 0, dot1 * dot1 > combinedRadiusSq * wLengthSq {
                        // Out through the cut-off circle.
                        let wLength = wLengthSq.squareRoot()
                        let unitW = w / max(wLength, 1e-9)
                        direction = V2(unitW.y, -unitW.x)
                        u = unitW * (combinedRadius * invHorizon - wLength)
                    } else {
                        // Out through a leg.
                        let leg = max(distSq - combinedRadiusSq, 0).squareRoot()
                        if relativePosition.det(w) > 0 {
                            direction = V2(relativePosition.x * leg - relativePosition.y * combinedRadius,
                                           relativePosition.x * combinedRadius + relativePosition.y * leg) / distSq
                        } else {
                            direction = -V2(relativePosition.x * leg + relativePosition.y * combinedRadius,
                                            -relativePosition.x * combinedRadius + relativePosition.y * leg) / distSq
                        }
                        u = direction * relativeVelocity.dot(direction) - relativeVelocity
                    }
                } else {
                    // Already overlapping: separate within this step.
                    let w = relativeVelocity - relativePosition / step
                    let wLength = w.length
                    let unitW = wLength > 1e-9 ? w / wLength : V2(1, 0)
                    direction = V2(unitW.y, -unitW.x)
                    u = unitW * (combinedRadius / step - wLength)
                }
                let share: Float = b.avoids ? 0.5 : 1
                lines.append(Line(point: velocity + u * share, direction: direction))
            }
            var result = V2(0, 0)
            let maxSpeed = max(a.maxSpeed, 0)
            let failed = Self.linearProgram2(lines, radius: maxSpeed, optimal: preferred, directionOpt: false, result: &result)
            if failed < lines.count { Self.linearProgram3(lines, begin: failed, radius: maxSpeed, result: &result) }
            out[i] = Vec3(result.x, 0, result.y)
        }
        return out
    }

    // MARK: Linear programs (RVO2)

    struct V2: Equatable {
        var x: Float, y: Float
        init(_ x: Float, _ y: Float) { self.x = x; self.y = y }
        static func + (a: V2, b: V2) -> V2 { V2(a.x + b.x, a.y + b.y) }
        static func - (a: V2, b: V2) -> V2 { V2(a.x - b.x, a.y - b.y) }
        static prefix func - (a: V2) -> V2 { V2(-a.x, -a.y) }
        static func * (a: V2, s: Float) -> V2 { V2(a.x * s, a.y * s) }
        static func / (a: V2, s: Float) -> V2 { V2(a.x / s, a.y / s) }
        func dot(_ b: V2) -> Float { x * b.x + y * b.y }
        /// The 2D cross product (determinant of the two as columns).
        func det(_ b: V2) -> Float { x * b.y - y * b.x }
        var lengthSquared: Float { x * x + y * y }
        var length: Float { lengthSquared.squareRoot() }
    }

    /// A half-plane of allowed velocities: left of `direction` through `point`.
    struct Line {
        var point: V2
        var direction: V2
    }

    /// Optimizes on line `i` under the lines before it and the speed circle. False if infeasible.
    static func linearProgram1(_ lines: [Line], _ i: Int, radius: Float, optimal: V2, directionOpt: Bool, result: inout V2) -> Bool {
        let line = lines[i]
        let dotProduct = line.point.dot(line.direction)
        let discriminant = dotProduct * dotProduct + radius * radius - line.point.lengthSquared
        guard discriminant >= 0 else { return false }
        let sqrtDiscriminant = discriminant.squareRoot()
        var tLeft = -dotProduct - sqrtDiscriminant
        var tRight = -dotProduct + sqrtDiscriminant
        for j in 0..<i {
            let denominator = line.direction.det(lines[j].direction)
            let numerator = lines[j].direction.det(line.point - lines[j].point)
            if abs(denominator) <= 1e-6 {
                if numerator < 0 { return false }
                continue
            }
            let t = numerator / denominator
            if denominator >= 0 { tRight = min(tRight, t) } else { tLeft = max(tLeft, t) }
            if tLeft > tRight { return false }
        }
        if directionOpt {
            result = optimal.dot(line.direction) > 0 ? line.point + line.direction * tRight : line.point + line.direction * tLeft
        } else {
            let t = line.direction.dot(optimal - line.point)
            if t < tLeft { result = line.point + line.direction * tLeft }
            else if t > tRight { result = line.point + line.direction * tRight }
            else { result = line.point + line.direction * t }
        }
        return true
    }

    /// The velocity nearest `optimal` inside every line and the speed circle; returns the
    /// index of the first line it couldn't meet (`lines.count`: all met).
    static func linearProgram2(_ lines: [Line], radius: Float, optimal: V2, directionOpt: Bool, result: inout V2) -> Int {
        if directionOpt {
            result = optimal * radius
        } else if optimal.lengthSquared > radius * radius {
            result = optimal / optimal.length * radius
        } else {
            result = optimal
        }
        for i in lines.indices where lines[i].direction.det(lines[i].point - result) > 0 {
            let previous = result
            if !linearProgram1(lines, i, radius: radius, optimal: optimal, directionOpt: directionOpt, result: &result) {
                result = previous
                return i
            }
        }
        return lines.count
    }

    /// When the lines can't all be met: the velocity that violates them least.
    static func linearProgram3(_ lines: [Line], begin: Int, radius: Float, result: inout V2) {
        var distance: Float = 0
        for i in begin..<lines.count where lines[i].direction.det(lines[i].point - result) > distance {
            var projected: [Line] = []
            for j in 0..<i {
                let determinant = lines[i].direction.det(lines[j].direction)
                var point: V2
                if abs(determinant) <= 1e-6 {
                    if lines[i].direction.dot(lines[j].direction) > 0 { continue }
                    point = (lines[i].point + lines[j].point) * 0.5
                } else {
                    point = lines[i].point + lines[i].direction * (lines[j].direction.det(lines[i].point - lines[j].point) / determinant)
                }
                let d = lines[j].direction - lines[i].direction
                let len = d.length
                guard len > 1e-9 else { continue }
                projected.append(Line(point: point, direction: d / len))
            }
            let previous = result
            let direction = V2(-lines[i].direction.y, lines[i].direction.x)
            if linearProgram2(projected, radius: radius, optimal: direction, directionOpt: true, result: &result) < projected.count {
                result = previous
            }
            distance = lines[i].direction.det(lines[i].point - result)
        }
    }
}
