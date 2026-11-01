# Networking and multiplayer (cards 624, 662, 671, 672)

Research notes, a recommendation and a phased plan, plus the implementation that backs the measurements
(`Sources/Engine/Net`; `NetworkingTests`, `NetConnectionTests`, `NetPredictionTests`, `NetHierarchyTests`, `NetBacklogTests`, `EditorNetPlayTests`;
the `net` and `netcharacter` demo scenes; editor network play; `GameRunner --server` / `--connect`).

## What the engine's games need

The engine's demos and samples point at small-team 3D and 2D action games: a character controller
on rigid-body physics (`character`), physics toys and piles (`physics`, `crowd`, `physics2d`),
sprites and HUDs. The multiplayer those games plausibly want, in order of likelihood:

1. **Co-op and small-scale versus, 2-8 players**, over the internet, one player hosting or a
   dedicated server. Players run around a physics world; the shared state is tens to a few
   hundred moving entities.
2. **Couch / LAN play** with the same code path (latency near zero, NAT not an issue).
3. **Fighting- or sports-style games with few entities and frame-exact inputs**, where rollback is
   the genre standard. Possible, not the main target.

Not targets: MMOs (interest management at scale, sharding), competitive shooters needing lag
compensation on hit scans (a later layer on top of the same model), browser clients.

Requirements that follow:

- **Server authority** for anything physical: clients can't be trusted with positions, and
  physics piles diverge as soon as two machines disagree on one contact.
- **Tolerate 50-150 ms latency and a few percent loss** without visible stalls.
- **Bandwidth**: comfortably under 256 kbit/s per client at 30 Hz for a few hundred entities
  (residential uplinks for player hosts).
- **Generic replication** from the ECS: any `Codable` component, opted in per entity, no per-type
  networking code required (hand-tuned encodings optional for hot types).
- **Testable without sockets**: deterministic simulated latency / loss, like the engine's other
  deterministic tests (input injection, fixed steps, job-system determinism).
- **Platforms**: macOS, Linux, Windows (the engine's targets). Consoles later would bring their own
  transport and identity services, which argues for a transport abstraction from day one.

## Models compared

### Client-server with snapshot interpolation (+ client prediction / reconciliation)

The server simulates; clients send inputs and receive snapshots (Quake 3, Source, Overwatch, most
Unity / Unreal games). Remote entities are shown slightly in the past, interpolated between two
received snapshots (`interpolationDelay`, typically 2-3 snapshot intervals). The local player is
*predicted*: the client runs its own character's movement immediately from local input, and when
a snapshot arrives with the server's result for input N, it rewinds the character to that state
and re-applies inputs N+1... (reconciliation).

- Works with any amount of nondeterminism: the server's state is the truth, clients only display.
- Late join and reconnect are free (a full snapshot), and cheating is limited to inputs.
- Cost: bandwidth scales with changed state; remote entities are ~latency + delay behind;
  prediction needs the predicted code (character movement) to be re-runnable from a state, and
  interactions between a predicted player and server-simulated physics (pushing a pile) show
  corrections.

### Deterministic lockstep and rollback

Every peer runs the whole simulation; only inputs are exchanged. *Lockstep* waits for every
input for tick N before simulating N (RTS games). *Rollback* (GGPO) predicts missing remote inputs,
simulates ahead, and when the real input arrives restores a snapshot of tick N and re-simulates
to the present.

- Tiny bandwidth (inputs only), any number of entities, perfect consistency.
- Requires **bit-exact determinism across every machine in a match**, or games silently desync.
- Rollback must re-simulate several ticks per frame: the full world step, physics included, has to
  run maybe 5-8x per frame. `World.snapshot()` / `restore` exist, which helps.
- Hidden information is visible to every client (all state is everywhere); late join needs a state
  transfer anyway.

### Determinism: what this engine has (measured)

The physics engine is bit-deterministic for any job thread count on one machine (`ParallelIslandsTests`,
`JobSystemDeterminismTests`). Across machines, `NetworkingTests/physicsDeterminismFingerprint` hashes
the final poses of 60 mixed bodies after 300 single-threaded steps, plus 16,000 libm results
(`sinf`, `cosf`, `tanf`, `atan2f`, `expf`, `logf`, `powf`, `acosf`):

| Machine | physics hash | libm hash |
|---|---|---|
| macOS 27, arm64 (M5), Swift 6.4.2 | `b322fb9bb60b3002` | `59e232f0651af5e8` |
| Linux arm64 (Ubuntu 24.04 container, glibc), Swift 6.4.2 | `b322fb9bb60b3002` | `7a61f0577e1d597c` |
| Linux x86_64 (same container image, `--platform linux/amd64` under Docker Desktop's emulation), Swift 6.4.2 | `b322fb9bb60b3002` | `dac1e5a4dfeb4cd7` |

What that says:

- The physics step itself is IEEE-reproducible across OSes on arm64: same compiler, same SIMD
  lowering, and the solver only uses `+ - * /` and `sqrt` (correctly rounded everywhere) on the
  hot path.
  It is also identical on x86_64: the same hash on Linux x86_64 as on both arm64 machines (x86_64
  Swift targets SSE2 without FMA, and LLVM doesn't contract `a * b + c` into FMAs on arm64 unless
  asked, so both round every operation the same way). Caveats: the x86_64 run was emulated (the
  emulator implements SSE arithmetic exactly, but a native run and macOS x86_64 weren't tried:
  this Mac has no Rosetta installed), the scene is one 300-step pile, and the hash only covers
  what this test exercises (no character controller, no joints, no 2D physics).
- **libm differs between platforms**: Apple's libm vs glibc on the same arm64 CPU, and glibc
  arm64 vs glibc x86_64 - three different hashes. Anything game code
  computes with `sinf` / `cosf` / `atan2f` / `powf` - rotations from angles (`Quat(angle:axis:)`),
  steering, animation - diverges after one ulp, and chaotic systems (piles) amplify it within
  seconds. Windows' UCRT would be a third implementation.
- The compiler is a third risk: a different Swift version (or optimizer flags, or fused
  multiply-add contraction) may reorder or fuse floating-point operations. Lockstep needs every
  peer on the same build.

So cross-platform lockstep / rollback would need: engine-owned implementations of every
transcendental used by simulation code (or fixed-point math), a pinned toolchain, FMA contraction
explicitly controlled, and a desync detector (hash the world state every N ticks and compare).
That is real work, and it constrains game code forever. Rollback for a fighting-style game *on
one platform* (all peers the same build and architecture) is feasible later.

### Relay vs peer-to-peer

- **Dedicated server**: best experience, costs money to run; needs headless server builds (the
  engine runs a `World` without a window already: tests do it).
- **Player-hosted (listen server)**: one player's game is the server. Needs NAT traversal
  (UDP hole punching via a rendezvous server; works for ~80-90% of pairs) and a **relay fallback**
  (TURN-like; the rest), and the host's uplink is the bandwidth limit.
- **Pure P2P mesh** is only natural for lockstep / rollback with few players.
- Platform services (Steam Datagram Relay / Steam Networking Sockets, Epic Online Services P2P,
  console services) provide relays, NAT traversal and identity; a transport abstraction lets them
  plug in later without touching replication.

## Transport

All of the models above want **unreliable datagrams** for state plus a little reliable messaging
(chat, RPCs, join / leave):

| Option | Notes |
|---|---|
| UDP + own reliability layer | Universal (BSD sockets on macOS / Linux, Winsock on Windows). Acks, resend of reliable messages, fragmentation and congestion behaviour are ours to write (well-understood: Quake 3, ENet, Gaffer on Games). No encryption unless added (DTLS or a libsodium-style handshake). |
| QUIC with datagrams | Encryption, connection migration and reliable streams + unreliable datagrams (RFC 9221) in one protocol. Apple: Network.framework (`NWConnection` QUIC, datagram flows) on macOS 12+. Linux / Windows: no system QUIC; options are MsQuic (C, MIT; Windows' own QUIC, also builds on Linux / macOS) or quiche / ngtcp2. MsQuic as one vendored dependency on all three platforms is the most portable path. Needs certificates (self-signed per session for player hosts, pinned via the matchmaker). |
| ENet / yojimbo / GameNetworkingSockets | Proven C / C++ game transports with reliability channels; GameNetworkingSockets (BSD-3) adds encryption and Steam's relay protocol. A vendored C++ library like CTextureCodec's. |
| WebRTC data channels | Only if browser clients ever matter. Heavy. |

Recommendation: keep the engine's `NetTransport` protocol (unreliable datagrams, polled), ship
**plain UDP first** (done in the prototype, ~130 lines over POSIX sockets; Winsock is a small `#if`),
add a reliable-message channel and a connection handshake on top (done, card 662), then add an **encrypted transport**
behind the same protocol when anything ships over the internet: MsQuic datagrams or
GameNetworkingSockets, decided by whether Steam relays are wanted.

## Serialization: snapshots from the ECS

The prototype's approach, which scales to the target sizes:

- Entities opt in with a `Replicated` component listing component names; identity is the
  entity's `EntityID` (already persistent, 128-bit, unique across worlds), so client entities get
  the server's ids and `world.entity(for:)` is the lookup.
- The server captures, per tick, each replicated component **encoded to bytes**: `Transform`
  quantized (below) or exact, types conforming to `NetCustomEncoding` their own way, other
  components through `Codable` with `NetBinaryEncoder` (decoded on the client through
  `ComponentRegistry`). Comparing bytes is the whole change detection.
- **Delta against the last acked state**: the server keeps 64 ticks of history; each client acks
  the newest tick it has; the next snapshot is a delta against that (only changed components, new
  entities in full, removed ids). Lost packets just mean an older baseline. A client that hasn't
  acked anything recent gets a full snapshot.
- Fragmentation into 1200-byte datagrams; a lost fragment loses that snapshot only.

The prototype measured (`snapshotDeltaSize`, 200 entities with Transform + a small Codable
component): full snapshot 18,342 bytes, delta with 10 moved 629 bytes, nothing changed 21 bytes;
the `net` scene's 14 always-moving entities ~870 bytes per snapshot (~210 kbit/s at 30 Hz).

Snapshot efficiency (card 662, phase 3), what is implemented:

- **Quantized Transform** (`NetTransformEncoding.quantized`, the default): position in 1/1024 m
  steps as zigzag varints, rotation smallest-three in 32 bits, scale omitted when one (one float
  when uniform): 12-14 bytes within 500 m (`quantizedTransformPrecision`: error at most 0.83 mm and
  0.19 degrees). In a delta it is sent as **field deltas** against the client's baseline (a mask,
  the changed axes as small varints, the rotation if it changed): 2-8 bytes for a moving, turning
  entity. `.exact` (41 bytes) for what a client predicts.
- **Entity references** are gaps between indices in the baseline's sorted ids (one byte, not 16);
  a component header is one varint (name index and kind).
- **`NetBinaryEncoder` / `NetBinaryDecoder`**: tagged binary Codable (varints, raw floats, sorted
  keys, self-describing so custom `init(from:)`s work); malformed input throws. Keys are still
  spelled out, so small structs only shrink ~20% (a 16-field record 259 B vs 326 B of JSON); hot
  types get a hand-written `NetCustomEncoding` (`CharacterController`: 91 B vs ~330 B).
- **zlib** (`NetServer.compression`: `.fullSnapshots` by default, or `.all`), used only when smaller.
- **Priority and budget**: `NetServer.bandwidthLimit` (snapshot payload bytes per second per
  client); each snapshot carries the changed entities with the highest accumulated
  `Replicated.priority` that fit, the rest wait and gain priority. The server tracks what each
  client actually has (per-client sent states) so deltas stay correct, per entity since card 672
  (see "Budget backlogs" below).

Measured (`NetworkingTests`, macOS arm64; bytes the server sends one client including packet and
fragment headers, 30 Hz, 300 entities each with a rotated Transform and a small component):

| Case | kbit/s (card 662) | kbit/s (card 672) |
|---|---|---|
| Nothing moving (keep-alive cost: empty deltas, headers) | 11.5 | 11.0 |
| 30 of 300 moving and turning | 92 | 91.3 |
| All 300 moving and turning, no budget | 804 | 804 |
| The same with zlib on every snapshot | 367 | 367 |
| All 300 moving, `bandwidthLimit` 30,000 B/s, zlib | 244 (175 entities per snapshot: each updated at least every 57 ms) | 247 (188 per snapshot, every 53 ms) |

The 200-entity full snapshot is now 10,331 bytes (4,814 with zlib, vs 18,342), 10 moved 97 bytes
(vs 629), nothing changed 17. A join of 300 entities is ~35 KB over the first second and a half.
So the 256 kbit/s target holds for a few hundred entities with a typical fraction moving, and when
everything moves the budget keeps it under the target by updating each entity at ~19 Hz instead
of 30. The `net` scene's 14 movers are ~234 bytes per snapshot (~57 kbit/s, was ~210).

### Budget backlogs (card 672)

Deltas were against the newest snapshot the client acknowledged. Under a budget each snapshot
carries only some changes, so the snapshots in flight carry different entities, and only the
acknowledged one's made it into the next baseline: a large backlog drained at about one entity per
round trip, and entities appeared and vanished on the client as snapshots with and without them
were shown. What is implemented (`NetVersionedState.swift`, `Replication.swift`):

- **Versioned states**: every state the server tracks for a client (and the client rebuilds) records,
  per entity, the tick of the snapshot that set its value or removed it (tombstones are kept while
  they can matter: 32 ticks behind the baseline).
- **Acks of every snapshot**: the client acks the newest tick plus a varint field of the 32 before it
  that it doesn't have (one byte when none is missing).
- **Merged baselines**: the next snapshot's baseline is the newest acknowledged state with the
  entities of the other acknowledged snapshots (within 32 ticks) merged where they are newer. The
  snapshot lists the merged ticks that changed something (`NetSnapshot.mergedTicks`); both sides
  merge the same states the same way. Nothing backlogged: nothing to merge, nothing listed.
- **In-flight entities wait**: an entity whose current value went out in a snapshot not yet
  acknowledged comes after everything else and gains no priority until the ack, or until a later ack
  shows that snapshot missing (or ~1.5 RTT pass): then it goes again. Without a budget everything
  changed is still sent every snapshot until acknowledged, as before.
- **Display states on the client**: each received snapshot's world is the newest value of every
  entity among the snapshots received so far (by tick), so an entity from an unacknowledged snapshot
  stays. The server sends an empty entry (the newest-version marker) when a value the client may
  show from an unacknowledged snapshot differs from the current one while the baseline agrees, and
  a removal by id for an entity removed before any snapshot carrying it was acknowledged.
- **Cleanup under a tight budget**: snapshots say whether their state has every entity the server
  replicates (values may lag; the old flag needed nothing deferred), and if not, where the missing
  ones sort among the state's ids (up to 64 positions). The client despawns its own unmatched
  scene entity once no missing entity sorts next to it.
- **Wire**: packet version 3. The baseline is a varint offset and a sections byte follows (merged
  ticks, removals by id, gaps): 2 bytes smaller than the old u32 baseline when no section is used.

Measured (`NetBacklogTests`, 50 ms + 40 ms jitter, 15% loss and 5% duplication each way):

| Case | Before | After |
|---|---|---|
| 36 new entities at 600 B/s (the #671 repro), time until all are on the client | 6.5-6.6 s, ~5,000 frames of entities vanishing | 1.4-1.8 s (30 seeds: 1.47-2.0 s), none |
| 120 new entities at 6,000 B/s | 7.2 s, ~18,600 vanishing | 1.9 s (5,990 B/s sent including headers), none |
| 20 scene entities + 100 new at 600 B/s | not drained after 8 s, the unmatched scene entity never removed | drained after 5.2 s, unmatched entity removed after 1.0 s |
| 40 always-moving entities at 1,500 B/s (every snapshot defers) | the unmatched entity never removed | removed after 1.3 s |
| 200 idle entities, 10% loss: largest delta | 19 B | 17 B |

The bound the test derives: at 600 B/s a snapshot has 20 B, less than one 71-byte new entity, so
each carries the budget's minimum of one: 36 snapshots, 1.2 s, divided by the 0.85 delivery chance,
plus a few round trips for the last losses (< 2.4 s). That minimum of one entity per snapshot is
over such a small budget (about 3.3 kB/s goes out while it drains); at 6,000 B/s the rate is the
budget's (several entities per snapshot, 5,990 B/s sent).

## Security basics

- **Never trust the client**: clients send inputs (validated: rates, ranges), never state.
  The server applies them in its simulation.
- **Parse defensively**: every length and count in a packet is bounds-checked; malformed packets
  are dropped, never crash (the prototype's `ByteReader` throws; `snapshotRoundTripAndMalformedInput`
  feeds every truncation). Fuzz the decoders.
- **No amplification**: a server must not answer an unauthenticated datagram with more bytes than
  it received (reflection DDoS). Done (phase 1): connection requests are padded to 64 bytes, the
  server answers with a 20-byte challenge whose token is a keyed hash of the address, salt and a
  10 s time bucket, and allocates a slot only when the token comes back from that address
  (`handshakeRejectsBadTokensAndDoesNotAmplify`). The hash is SplitMix-style, not cryptographic:
  it proves the address, not the client's identity. The UDP transport itself still adds a table
  entry per sending address.
- **Encryption and authentication**: per-session keys from a matchmaker (connect tokens, as in
  yojimbo / netcode.io) or QUIC's TLS; without it, anyone on the path can read and spoof packets.
- **Rate limits** per address for connection attempts; cap the number of clients.
- **Don't send hidden state** (other players' inventories, enemies behind walls) when it matters:
  replication filtering per client.
- Game modules are native code: servers should not load modules from clients.

## Recommendation

**Server-authoritative client-server with snapshot interpolation, client-side prediction for the
local player, and a transport abstraction with UDP first and an encrypted transport before
anything ships.** It fits physics-heavy co-op games, works with the engine as it is (no global
determinism requirement), gives late join and reconnect for free, and the same code runs a
listen server, a dedicated server and LAN play. Lockstep / rollback stays an option for
single-platform, few-entity games, after the determinism work listed above.

## The implementation (Sources/Engine/Net)

- `NetTransport` (unreliable datagrams, polled), `LoopbackNetwork` / `LoopbackTransport`
  (in-process, deterministic latency, jitter, loss and duplication on a caller-driven clock),
  `UDPTransport` (non-blocking IPv4 POSIX sockets; macOS and Linux).
- `Replicated` component, `NetWorldState`, `NetSnapshot` (delta + wire format), `NetComponentCoder`.
- `NetServer`: snapshot capture at `sendInterval` (30 Hz), 64-tick history, per-client acked
  baseline, fragmentation. `NetClient`: handshake, reassembly, baseline
  rebuild, acks, render clock `interpolationDelay` behind the newest snapshot (steered gently, no
  extrapolation), Transform interpolation (lerp / slerp), spawn / despawn / component add and
  remove by `EntityID`, deterministic apply order.
- The `net` demo scene: 14 movers on the server (left); the client's replica (right) over 100 ms
  one-way latency and 5% loss each way, with the server's current positions as ghosts.
- Tests (`NetworkingTests`): replication converges under 10% loss, jitter and duplication with
  moves, despawns, a late spawn and component changes and removals; interpolation under 100 ms +
  5% loss is exact for linear motion (error < 1 mm, no starved frames, per-frame steps within 25%
  of the true speed); delta sizes; wire format round trip and every truncation rejected;
  fragmented 300-entity snapshots under loss; UDP on localhost; the determinism fingerprint.

Card 662 (phases 1-3) added:

- **Connection layer** (`NetConnection.swift`): the handshake above, `NetClientID`s (1, 2, ... never
  reused), `maxClients` (denied: `serverFull`), keep-alives after `keepAliveInterval` (0.1 s) of
  silence, `timeout` / `connectTimeout`, `disconnect()` on either side (sent three times), events
  (`pollEvents`: connected, disconnected with a reason, messages). Every connected packet has a
  16-bit sequence, an ack of the newest packet received plus a 32-bit field of the ones before it
  and how long the ack was held, the reliable channel's cumulative ack, and due reliable messages:
  acks ride on snapshots and input packets. Reliable messages (`send(message:)`, up to 1000 bytes)
  are numbered, resent every 1.25 RTT until acked, delivered once and in order. `connectionStats`:
  smoothed RTT (ack hold time subtracted), loss over the last 128 packets whose fate is known,
  packets / bytes. Measured (`rttAndLossEstimates`): 60 ms each way + 10% loss reads as RTT 133 ms
  (the 30 Hz / 60 Hz packet cadence adds a little) and loss 9.4% on both sides; 300 messages each
  way with sizes 3-302 B arrive once and in order under 20% loss, 40 ms jitter and 10% duplication.
- **Inputs and prediction** (`NetPrediction.swift`): `NetClient.sendInput(bytes)` numbers inputs
  and resends the newest `inputsPerPacket` (16) unacked ones in every packet; `NetServer.takeInputs`
  hands them out in order (gaps skipped) for the game's fixed tick; each snapshot carries the newest
  input applied. `NetCharacterInput` (move velocity + jump, 5 bytes, 1 mm/s),
  `PhysicsWorld.applyCharacterInput` on the server, `NetCharacterPrediction` on the client (replicate
  the character with `Replicated(components: [Transform, CharacterController], transform: .exact)`):
  predict with `PhysicsWorld.predictCharacter` (the controller step without pushes or the kinematic
  move, additive to `CharacterController`), and on each new snapshot rewind to its state, drop the
  applied inputs and replay the rest; a correction is blended out of the display over 0.1 s.
  Measured (`NetPredictionTests`): two players at 100 ms each way + 20 ms jitter + 5% loss walking
  over stairs and jumping: about 320 reconciliations each, ~14 inputs replayed per
  reconciliation, **zero corrections, error exactly 0** (same static collision world on both
  sides, bit-identical step), the prediction running up to 1.0 m ahead of the server's current
  position (the latency it hides). A server-side 1.5 m knock-back the client can't predict is
  corrected on the next snapshot (error 1.5 m) and blended out; with 30% loss client-to-server
  every input still arrives, in order.
- **Snapshot efficiency**: see "Serialization" above.
- Demo: `netcharacter` (scene 37), two players with predicted characters over the link above.

Card 671 (phases 4 and 6) added:

- **Hierarchy** (`NetEntityMapping.swift`, `Replication.swift`): every replicated entity's parent travels as
  the pseudo-component `NetHierarchy.parentKey` (`"$parent"`, the parent's 16-byte `EntityID`), so it is
  delta-encoded like a component: 18 bytes per link in a full snapshot, nothing in a delta until it changes
  (`hierarchyCost`: 200 entities as 100 roots with a child each cost 1,808 bytes more in full than 200
  roots, the same 19 bytes when idle, and moving the 100 roots costs 729 bytes instead of 1,430 for
  moving 200 flat entities). Transforms stay local. The client spawns every entity of the state first,
  then attaches each to its parent, so a child listed before its parent (ids sort that way) is fine; a
  parent the client doesn't have (not replicated, or not arrived) leaves the child a root until it
  arrives (`NetClient.unresolvedParents`); swaps that would make a cycle in between (A under B and B under
  A in one tick) are retried after the other move; replicated children of a despawned entity that are
  still in the state are detached first. Under a byte budget, a parent new to the client goes in the
  same snapshot as the children that refer to it (over budget if need be): with ~1 entity per snapshot,
  12 new three-level subtrees arrive with no frame where a child waits for its parent (without that rule
  the hierarchy hadn't converged after 6 s at 15% loss, see below). Sibling order isn't replicated.
- **Entity references:** while the server encodes a replicated component, every `Entity` in it (fields,
  optionals, arrays) is written as its target's `EntityID` (through `NetBinaryEncoder.userInfo`, which
  `Entity`'s Codable conformance reads); the client decodes it to its entity with that id, or
  `Entity.invalid` while the target hasn't arrived, remembers what each id resolved to, and decodes the
  component again when that changes, so a reference resolves the frame its target arrives and goes stale
  when the target is despawned. `EntityRef` already names its target by id and resolves through
  `World.resolve`.
- **Scene entities matched by id:** a client that loaded the same scene (or built the same world with
  the same ids) already has the server's replicated entities; they are updated in place (their handles
  and non-replicated components kept) instead of spawned again. Replicated entities the client has but
  the server's state lacks (removed before the client joined) are despawned once a snapshot shows the
  server lacks them (`despawnsUnmatchedEntities`; since card 672 this works under a budget that always
  defers something, see "Budget backlogs").
- Tests (`NetHierarchyTests`, 15% loss, 40 ms jitter, 5% duplication): children before parents, a 90°
  turned parent moving its subtree (positions within 1 cm), reparenting with a swap, parents despawned
  with and without their children, unresolved parents and the budget rule, `Entity` / `[Entity]` /
  `Entity?` / `EntityRef` fields resolving late and going stale, the same scene loaded on both sides.
- **Stats** (`NetStats.swift`): `NetClient.statsReport(prediction:)` and `NetServer.statsReport(for:)` give
  a `NetStatsReport`: RTT, loss, bytes per second in / out over the last second (`NetRateMeter`) and in
  total, packets, snapshots, the last snapshot's size and deferred entities (server), the interpolation
  delay, what is buffered (time and snapshots) and starved frames (client), replicated entities and
  unresolved parents, and with a prediction its reconciliations and corrections. `overlayLines` formats
  it; `Engine.debugOverlayLines` puts any lines under the debug overlay's frame stats.
- **Editor network play** (`EditorNetPlay.swift`, `EditorNetCommands.swift`): `net.start {clients}` makes
  the scene's world the server and N client worlds copies of the scene as play started, on a
  `LoopbackNetwork`; the Game View shows the server or a client (`net.view`), the scene view the server;
  `net.setConditions` per client and direction; `net.stats`; the viewport's overlay (`net.overlay`);
  the toolbar's Network menu. Clients only display (game input and systems run on the server).
- **`GameRunner --server` / `--connect`** (`Sources/GameRunner/NetRun.swift`, GameModule ABI 1.3
  `networkedWorld`): a game module headless as a UDP server, and clients with a window (or `--headless`).

Measured (phase 6):

| Setup | Result |
|---|---|
| `GameRunner SampleGame --server` + `--connect 127.0.0.1` (UDP, same Mac, debug) | 6 moving props: snapshots 61-67 B, 22.9 kbit/s to the client, 6.5 kbit/s back, RTT 16-22 ms (60 Hz cadence), 0% loss, buffer ~100 ms (3-4 snapshots), 0 starved frames; the client's world has the 9 entities `networkedWorld` builds (6 matched replicas), none duplicated |
| Editor, starter scene + a spinner with two arms (11 entities), client 1 at 60 ms + 10 ms jitter + 2% loss, client 2 at 150 ms + 40 ms jitter + 8% loss | RTT 165 ms and 373 ms (both ends agree within 5 ms), measured loss 1.6-2.3% and 7-9%, ~15 kbit/s to each client, 38-byte snapshots, buffer 89-131 ms; the slow client starved 7-11 frames in 30 s (its jitter is close to the 100 ms buffer) |
| `EditorNetPlayTests` (2 clients, one at 150 ms + 20 ms jitter + 10% loss, 300 frames) | fast client RTT < 60 ms, slow 300-420 ms, loss > 2%, > 1 kB/s, > 100 snapshots |

A finding from the budget work (phase 3): deltas were always against the newest acknowledged state,
so when a budget allowed only about one entity per snapshot and the round trip spanned several
snapshots, a large backlog progressed about one entity per acknowledgement round (36 new entities at
600 B/s and 15% loss took 6.5 s). Fixed by card 672: 1.4-1.8 s, see "Budget backlogs" above.

Not done yet: encryption, sibling order in replicated hierarchies, client input in editor network play
and GameRunner clients (they only display; a game sends its own input commands),
interest management (priority exists, distance-based priority is up to the game), clock sync
beyond the interpolation clock, prediction of anything but a `CharacterController` (and of a
character on moving platforms or blocked by other players: those show up as corrections; the
replicated controller doesn't carry `groundBody`), lag compensation. The server applies a
client's inputs only as they arrive (up to `max` per tick), so a client that stops sending stops
moving: fine for co-op, a speed / freeze exploit to bound in versus games.

## Phased plan (suggested cards)

1. **Net: connection layer** - **done (card 662)**: challenge / response handshake, client ids,
   timeouts and disconnect, keep-alives, a reliable ordered message channel (acks piggybacked on
   snapshots / inputs), RTT and loss estimates. Tests on `LoopbackNetwork` and UDP.
2. **Net: inputs and client prediction** - **done (card 662)**: input commands (last 16 unacked per
   packet), server applies per fixed tick, `NetCharacterPrediction` reconciles on snapshots (zero
   corrections with the same collision world, 100 ms + jitter + 5% loss). Demo: `netcharacter`.
3. **Net: snapshot efficiency** - **done (card 662)**: quantized Transform with field deltas, binary
   Codable encoder, compact entity references, per-entity priority and a byte budget, zlib. 300
   entities: 92 kbit/s with 30 moving; all moving 804 kbit/s raw, 367 with zlib, 244 under a
   30,000 B/s budget (each entity updated every 57 ms or sooner).
4. **Net: hierarchy and references** - **done (card 671)**: parent links by `EntityID` (18 bytes per link in
   full snapshots, none in deltas), any spawn order, reparenting, despawned parents, new parents sent with
   their children under a budget; `Entity` fields mapped to the client's entities once their targets
   arrive; scene entities matched by id, unmatched replicated ones removed once a snapshot shows the server lacks them (card 672: also under a budget that always defers).
5. **Net: Windows sockets and an encrypted transport** - Winsock in `UDPTransport`; MsQuic datagrams
   or GameNetworkingSockets behind `NetTransport`; connect tokens.
6. **Net: editor and tooling** - **done (card 671)**: play with N clients in the editor (`net.start`, Game View
   on the server or any client), a stats overlay in the editor and `Engine.debugOverlayLines` for games,
   `net.setConditions` / `net.stats` MCP tools, `GameRunner --server` headless over UDP and `--connect`
   (localhost: 22.9 kbit/s for 6 movers, RTT ~20 ms).
7. **Determinism (only if rollback is wanted)** - engine-owned transcendental math for simulation
   code, desync hashing, a cross-platform determinism CI job (the fingerprint test on Linux x86_64 /
   arm64 and macOS).
8. **Relay / NAT traversal** - rendezvous + hole punching service, relay fallback, or Steam / EOS.
