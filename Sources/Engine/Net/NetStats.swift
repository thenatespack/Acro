import Foundation

// Networking (card 671, phase 6): one connection's numbers for overlays and tools. A
// `NetStatsReport` comes from `NetClient.statsReport(prediction:)` or
// `NetServer.statsReport(for:)`; `overlayLines` formats it for the engine's debug overlay
// (`Engine.debugOverlayLines`) and the editor's network overlay, and it encodes as JSON for
// the editor's `net.stats` tool.
//
// ```swift
// engine.debugOverlayLines = { [client] in client.statsReport().overlayLines }
// ```

/// Bytes per second in and out over the last `window` seconds, from cumulative counters
/// sampled every frame.
struct NetRateMeter {
    var window: Double = 1
    private var samples: [(time: Double, bytesIn: Int, bytesOut: Int)] = []

    mutating func record(time: Double, bytesIn: Int, bytesOut: Int) {
        if let last = samples.last, time <= last.time {
            samples[samples.count - 1] = (last.time, bytesIn, bytesOut)
        } else {
            samples.append((time, bytesIn, bytesOut))
        }
        // Keep one sample at or before the window's start.
        while samples.count > 2, samples[1].time <= time - window { samples.removeFirst() }
    }

    /// (in, out) bytes per second; zero until two samples exist.
    var rates: (bytesIn: Double, bytesOut: Double) {
        guard let first = samples.first, let last = samples.last, last.time > first.time else { return (0, 0) }
        let span = last.time - first.time
        return (Double(last.bytesIn - first.bytesIn) / span, Double(last.bytesOut - first.bytesOut) / span)
    }
}

/// One connection's traffic, link quality, snapshot buffer and prediction, from either end.
public struct NetStatsReport: Codable, Equatable, Sendable {
    /// "server → client 2" or "client 2".
    public var name: String
    public var connected: Bool
    /// Smoothed round trip (milliseconds); nil until measured.
    public var rttMs: Double?
    /// Recent packets the other side didn't receive (percent).
    public var lossPercent: Double
    /// Over the last second.
    public var bytesInPerSecond: Double
    public var bytesOutPerSecond: Double
    /// Since connecting.
    public var bytesIn: Int
    public var bytesOut: Int
    public var packetsIn: Int
    public var packetsOut: Int
    /// Snapshots sent (server) or received and decoded (client).
    public var snapshots: Int
    /// Server: the last snapshot's payload to this client (bytes, before fragmenting) and the
    /// changed entities it had no room for.
    public var lastSnapshotBytes: Int?
    public var deferredEntities: Int?
    /// Client: how far behind the newest snapshot the world is shown, how much of it is
    /// buffered now (newest snapshot time minus render time) and in how many snapshots, frames
    /// where the buffer ran dry, and snapshots whose baseline was gone.
    public var interpolationDelayMs: Double?
    public var bufferedMs: Double?
    public var bufferedSnapshots: Int?
    public var starvedFrames: Int?
    public var missingBaseline: Int?
    /// Client: replicated entities, and those waiting for their parent.
    public var entities: Int?
    public var unresolvedParents: Int?
    /// Client prediction (when given one): reconciliations, corrections and the last error (m).
    public var reconciliations: Int?
    public var corrections: Int?
    public var lastCorrection: Double?

    /// The report as short lines for the debug overlay (its bitmap font is upper case).
    public var overlayLines: [String] {
        func kb(_ bytesPerSecond: Double) -> String { String(format: "%.1f", bytesPerSecond * 8 / 1000) }
        var lines = ["NET \(name.uppercased())" + (connected ? "" : " (DISCONNECTED)")]
        lines.append("RTT " + (rttMs.map { String(format: "%.0f MS", $0) } ?? "-") + String(format: "  LOSS %.1f%%", lossPercent))
        lines.append("IN \(kb(bytesInPerSecond))  OUT \(kb(bytesOutPerSecond)) KBIT/S")
        if let lastSnapshotBytes {
            lines.append("SNAPSHOTS \(snapshots)  LAST \(lastSnapshotBytes) B" + ((deferredEntities ?? 0) > 0 ? "  DEFERRED \(deferredEntities!)" : ""))
        } else {
            lines.append("SNAPSHOTS \(snapshots)" + (entities.map { "  ENTITIES \($0)" } ?? ""))
        }
        if let interpolationDelayMs {
            lines.append(String(format: "BUFFER %.0f/%.0f MS", bufferedMs ?? 0, interpolationDelayMs)
                         + "  \(bufferedSnapshots ?? 0) SNAP  STARVED \(starvedFrames ?? 0)")
        }
        if let corrections {
            lines.append("CORRECTIONS \(corrections)/\(reconciliations ?? 0)" + String(format: "  ERR %.3f M", lastCorrection ?? 0))
        }
        return lines
    }
}

extension NetClient {
    /// This client's numbers; with `prediction`, its reconciliations and corrections too.
    public func statsReport(prediction: NetCharacterPrediction? = nil) -> NetStatsReport {
        let connection = connectionStats
        let rates = self.rates.rates
        let connected = clientID != nil
        var report = NetStatsReport(
            name: clientID.map { "client \($0.value)" } ?? "client", connected: connected,
            rttMs: connection?.rtt.map { $0 * 1000 }, lossPercent: (connection?.loss ?? 0) * 100,
            bytesInPerSecond: rates.bytesIn, bytesOutPerSecond: rates.bytesOut,
            bytesIn: connection?.bytesReceived ?? 0, bytesOut: connection?.bytesSent ?? 0,
            packetsIn: connection?.packetsReceived ?? 0, packetsOut: connection?.packetsSent ?? 0,
            snapshots: stats.snapshots)
        report.interpolationDelayMs = interpolationDelay * 1000
        report.bufferedMs = renderTime.flatMap { render in latestServerTime.map { max(0, $0 - render) * 1000 } }
        report.bufferedSnapshots = bufferedSnapshotCount
        report.starvedFrames = stats.starvedFrames
        report.missingBaseline = stats.missingBaseline
        report.entities = replicatedEntityCount
        report.unresolvedParents = unresolvedParents.count
        if let prediction {
            report.reconciliations = prediction.stats.reconciliations
            report.corrections = prediction.stats.corrections
            report.lastCorrection = Double(prediction.stats.lastError)
        }
        return report
    }
}
