# Networking and multiplayer (card 624)

Research notes, a recommendation and a phased plan, plus the prototype that backs the measurements
(`Sources/Engine/Net`, `Tests/EngineTests/NetworkingTests.swift`, the `net` demo scene).

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
add a reliable-message channel and a connection handshake on top, then add an **encrypted transport**
behind the same protocol when anything ships over the internet: MsQuic datagrams or
GameNetworkingSockets, decided by whether Steam relays are wanted.

## Serialization: snapshots from the ECS

The prototype's approach, which scales to the target sizes:

- Entities opt in with a `Replicated` component listing component names; identity is the
  entity's `EntityID` (already persistent, 128-bit, unique across worlds), so client entities get
  the server's ids and `world.entity(for:)` is the lookup.
- The server captures, per tick, each replicated component **encoded to bytes**: `Transform` as 40
  raw bytes, other components through `Codable` as sorted-key JSON (decoded on the client through
  `ComponentRegistry`). Comparing bytes is the whole change detection.
- **Delta against the last acked state**: the server keeps 64 ticks of history; each client acks
  the newest tick it has; the next snapshot is a delta against that (only changed components, new
  entities in full, removed ids). Lost packets just mean an older baseline. A client that hasn't
  acked anything recent gets a full snapshot.
- Fragmentation into 1200-byte datagrams; a lost fragment loses that snapshot only.

Measured (`snapshotDeltaSize`): 200 entities with Transform + a small Codable component: full
snapshot 18,342 bytes, delta with 10 moved 629 bytes, nothing changed 21 bytes (header only).
The `net` scene's 14 always-moving entities cost ~870 bytes per snapshot (~210 kbit/s at 30 Hz).

Next steps for size, in order of payoff: quantize Transforms (position to 1 mm in a 16-bit range
per sector, smallest-three quaternion in 32 bits, scale omitted when one) for ~10 bytes instead of
40; a compact binary `Encoder` for Codable components instead of JSON (field-wise deltas become
possible); per-entity priority and a bandwidth budget (send far / slow entities less often);
zlib over large full snapshots (CZlib is already linked).

## Security basics

- **Never trust the client**: clients send inputs (validated: rates, ranges), never state.
  The server applies them in its simulation.
- **Parse defensively**: every length and count in a packet is bounds-checked; malformed packets
  are dropped, never crash (the prototype's `ByteReader` throws; `snapshotRoundTripAndMalformedInput`
  feeds every truncation). Fuzz the decoders.
- **No amplification**: a server must not answer an unauthenticated datagram with more bytes than
  it received (reflection DDoS). Connection setup should use a challenge / cookie before the server
  allocates state or sends snapshots (the prototype's `hello` doesn't yet).
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

## The prototype (Sources/Engine/Net)

- `NetTransport` (unreliable datagrams, polled), `LoopbackNetwork` / `LoopbackTransport`
  (in-process, deterministic latency, jitter, loss and duplication on a caller-driven clock),
  `UDPTransport` (non-blocking IPv4 POSIX sockets; macOS and Linux).
- `Replicated` component, `NetWorldState`, `NetSnapshot` (delta + wire format), `NetComponentCoder`.
- `NetServer`: snapshot capture at `sendInterval` (30 Hz), 64-tick history, per-client acked
  baseline, fragmentation. `NetClient`: hello until the first snapshot, reassembly, baseline
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

Not in the prototype: inputs and prediction, reliable messages / RPCs, connection handshake,
timeouts and disconnects, encryption, hierarchy (only root entities; Transforms replicate as local),
`Entity` references inside replicated components (handles are per world; use `EntityID`),
interest management, quantization, bandwidth budgets, clock sync beyond the interpolation clock.

## Phased plan (suggested cards)

1. **Net: connection layer** - challenge / response handshake, client ids, timeouts and disconnect,
   keep-alives, a reliable ordered message channel (acks piggybacked on snapshots / inputs), RTT and
   loss estimates. Tests on `LoopbackNetwork`.
2. **Net: inputs and client prediction** - an input-command stream (redundantly sent: last N
   inputs per packet), server applies per tick; the client predicts its own character with the same
   systems and reconciles on snapshots (needs a re-runnable character step on the fixed timestep).
   Demo: `character` with two players over a laggy loopback.
3. **Net: snapshot efficiency** - quantized Transform, binary Codable encoder, per-entity priority
   and a byte budget, zlib for full snapshots; measure against the 256 kbit/s target with 300 entities.
4. **Net: hierarchy and references** - replicate parents (by `EntityID`) and `EntityRef` fields,
   scene-entities matched by id instead of spawned (both sides load the same scene).
5. **Net: Windows sockets and an encrypted transport** - Winsock in `UDPTransport`; MsQuic datagrams
   or GameNetworkingSockets behind `NetTransport`; connect tokens.
6. **Net: editor and tooling** - play with N clients in the editor (one process, several worlds, like
   the `net` scene), a network stats overlay (bytes, loss, RTT, interpolation buffer), MCP tools to
   set simulated conditions, `swift run GameRunner --server` headless.
7. **Determinism (only if rollback is wanted)** - engine-owned transcendental math for simulation
   code, desync hashing, a cross-platform determinism CI job (the fingerprint test on Linux x86_64 /
   arm64 and macOS).
8. **Relay / NAT traversal** - rendezvous + hole punching service, relay fallback, or Steam / EOS.
