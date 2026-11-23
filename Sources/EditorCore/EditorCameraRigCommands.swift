import Engine

/// Camera rig tools: which rig drives the camera and where every rig puts it (`cameraRig.state`),
/// switching the live rig (`cameraRig.activate`) and pointing a rig at a target (`cameraRig.setTarget`).
@MainActor
public enum EditorCameraRigCommands {
    public static let all: [any EditorCommand.Type] = [
        CameraRigStateCommand.self,
        CameraRigActivateCommand.self,
        CameraRigSetTargetCommand.self,
    ]
}

/// One rig, as `cameraRig.state` reports it.
public struct CameraRigInfo: Codable, Equatable, Sendable {
    public var entity: EntityID
    public var name: String
    /// thirdPerson, firstPerson, topDown, sideScroller or fixed.
    public var mode: String
    public var enabled: Bool
    public var priority: Int
    public var target: EntityID?
    public var live: Bool
    /// How far the blend to it is (1: done; 0 for rigs that aren't live).
    public var blendWeight: Float
    /// Where its camera is (while playing) or would settle (editing).
    public var cameraPosition: Vec3?
    /// Where the camera wants to be, and whether a wall pulled it in from there.
    public var desiredPosition: Vec3?
    public var collisionHit: Bool
}

/// Every camera rig and which one drives which camera.
public struct CameraRigState: Codable, Equatable, Sendable {
    public var rigs: [CameraRigInfo]
    /// The live rig (by priority when not playing).
    public var live: EntityID?
    /// The camera it moves.
    public var camera: EntityID?
    /// A blend between rigs is running (playing only).
    public var blending: Bool
    public var playing: Bool
}

extension EditorSession {
    /// The state `cameraRig.state` reports: running rigs while playing, settled previews when editing.
    func cameraRigState() -> CameraRigState {
        let world = self.world
        var entities: [Entity] = []
        world.query(CameraRig.self) { entity, _ in entities.append(entity) }
        entities.sort { $0.index < $1.index }
        let live = world.liveCameraRig
        var rigs: [CameraRigInfo] = []
        for entity in entities {
            guard let rig = world.get(CameraRig.self, for: entity), let id = world.id(of: entity) else { continue }
            let probe = isPlaying ? CameraRigSystem.probe(of: entity, in: world) : CameraRigSystem.preview(entity, in: world, physics: nil)
            rigs.append(CameraRigInfo(entity: id, name: displayName(of: entity), mode: rig.mode.rawValue, enabled: rig.enabled,
                                      priority: rig.priority, target: world.resolve(rig.target).flatMap { world.id(of: $0) },
                                      live: entity == live, blendWeight: isPlaying ? rig.blendWeight : (entity == live ? 1 : 0),
                                      cameraPosition: probe?.pose.position, desiredPosition: probe?.end,
                                      collisionHit: isPlaying ? rig.probeHit : false))
        }
        let camera = live.flatMap { entity in world.get(CameraRig.self, for: entity).flatMap { CameraRigSystem.outputCamera(for: $0, entity: entity, in: world) } }
        return CameraRigState(rigs: rigs, live: live.flatMap { world.id(of: $0) }, camera: camera.flatMap { world.id(of: $0) },
                              blending: isPlaying && (world.cameraRigs?.isBlending ?? false), playing: isPlaying)
    }

    /// The entity `id` with its rig, or a tool error.
    func cameraRig(_ id: EntityID, _ title: String) throws -> (Entity, CameraRig) {
        let entity = try world.require(id)
        guard let rig = world.get(CameraRig.self, for: entity) else { throw CommandError.failed("\(title): the entity has no CameraRig") }
        return (entity, rig)
    }
}

public enum CameraRigStateCommand: EditorCommand {
    public typealias Arguments = NoArguments

    public static let id: CommandID = "cameraRig.state"
    public static let title = "Camera Rig State"
    public static let doc = """
        Lists the scene's CameraRig components (mode, enabled, priority, target, where each puts its camera and where it wants to \
        be, whether a wall pulled it in) and which rig is live, the camera it moves and whether a blend between rigs is running. \
        While playing it reports the running rigs; when editing, the live rig is the enabled one with the highest priority and \
        positions are the settled poses (no collision). Switch rigs with cameraRig.activate.
        """
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> CameraRigState {
        session.cameraRigState()
    }
}

public enum CameraRigActivateCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var entity: EntityID
        /// Seconds; nil: the rig's own blendTime (0 cuts).
        public var blendTime: Float?
        public init(entity: EntityID, blendTime: Float? = nil) {
            self.entity = entity
            self.blendTime = blendTime
        }
    }

    public static let id: CommandID = "cameraRig.activate"
    public static let title = "Activate Camera Rig"
    public static let doc = """
        Makes a CameraRig the live rig: enables it and raises its priority above every other rig's. While playing the camera \
        blends to it over blendTime seconds (default the rig's own; 0 cuts): step the game (play.step) and read cameraRig.state \
        or view.screenshot {source: "game"}. When editing it changes the saved priority (one undo step), so the scene starts on it.
        """
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> CameraRigState {
        let (entity, rig) = try session.cameraRig(arguments.entity, title)
        if let time = arguments.blendTime, time < 0 || !time.isFinite { throw CommandError.failed("\(title): blendTime must be 0 or more") }
        let world = session.world
        if session.isPlaying {
            world.activateCameraRig(entity, blendTime: arguments.blendTime)
        } else {
            var highest = Int.min
            world.query(CameraRig.self) { other, r in if other != entity { highest = max(highest, r.priority) } }
            var changed = rig
            changed.enabled = true
            if highest != Int.min, changed.priority <= highest { changed.priority = highest + 1 }
            if changed != rig {
                guard session.perform(try SetComponentCommand(entity, to: changed, in: world, label: "Activate Camera Rig")) else {
                    throw CommandError.failed("\(title): the change couldn't be applied")
                }
            }
        }
        return session.cameraRigState()
    }
}

public enum CameraRigSetTargetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var entity: EntityID
        /// What it follows; nil: none (the rig follows its own entity).
        public var target: EntityID?
        public init(entity: EntityID, target: EntityID?) {
            self.entity = entity
            self.target = target
        }
    }

    public static let id: CommandID = "cameraRig.setTarget"
    public static let title = "Set Camera Rig Target"
    public static let doc = """
        Points a CameraRig at a target entity (what it follows: a character, a vehicle); no target makes it follow its own entity. \
        While playing it changes the running rig (it glides to the new target with its damping); when editing it is one undo step.
        """
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> CameraRigState {
        let (entity, rig) = try session.cameraRig(arguments.entity, title)
        let world = session.world
        let ref = try arguments.target.map { world.ref(to: try world.require($0)) } ?? .none
        if session.isPlaying {
            world.modify(CameraRig.self, for: entity) { $0.target = ref }
        } else if rig.target != ref {
            var changed = rig
            changed.target = ref
            guard session.perform(try SetComponentCommand(entity, to: changed, in: world, label: "Set Camera Rig Target")) else {
                throw CommandError.failed("\(title): the change couldn't be applied")
            }
        }
        return session.cameraRigState()
    }
}
