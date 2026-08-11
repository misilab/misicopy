//
//  DemoSnapshotProvider.swift
//  MisiCopyRemote
//
//  Synthetic snapshot stream used by the "Mode démo" so users (and the
//  App Store reviewer) can explore the entire Dashboard / Stats / Journal
//  / Controls UI without owning a Mac running MisiCopy. The animation
//  cycles through running → finished → idle in a 2 min loop.
//

import Foundation

@MainActor
@Observable
final class DemoSnapshotProvider {
    private(set) var snapshot: SessionSnapshot?
    private var timer: Timer?
    private var phaseStart: Date = Date()
    private var pausedAt: Date?
    private var cancelled: Bool = false
    /// Set the moment we schedule the post-cancel restart so the ticker
    /// doesn't queue a fresh restart task every 0.5 s while we're sitting
    /// in the cancelled state.
    private var cancelRestartScheduled: Bool = false

    private static let totalBytes: Int64 = 24 * 1024 * 1024 * 1024  // 24 GB
    private static let speed: Int64 = 220 * 1024 * 1024             // 220 MB/s
    private static let runSeconds: TimeInterval = 110
    private static let idleSeconds: TimeInterval = 8
    private static let filesTotal = 142

    func start() {
        guard timer == nil else { return }
        phaseStart = Date()
        tick()
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        snapshot = nil
        pausedAt = nil
        cancelled = false
        cancelRestartScheduled = false
        phaseStart = Date()
    }

    /// Drives the iPhone's pause / resume / cancel commands when in demo
    /// mode. Without this, the reviewer would tap the controls and see
    /// nothing happen, which reads as "broken".
    func handle(_ command: RemoteCommand) {
        switch command {
        case .pause:
            guard pausedAt == nil else { return }
            pausedAt = Date()
        case .resume:
            if let pausedAt {
                // Rewind the phase start by however long we were paused,
                // so the progress picks up right where it left off.
                let pausedFor = Date().timeIntervalSince(pausedAt)
                phaseStart = phaseStart.addingTimeInterval(pausedFor)
                self.pausedAt = nil
            }
        case .cancel:
            cancelled = true
        case .ping:
            break
        case .retryFailed:
            // Demo mode never has real failures to retry — fall through
            // silently so the dashboard button doesn't read as broken.
            break
        }
        tick()
    }

    private func tick() {
        if cancelled {
            renderCancelled()
            return
        }
        if let pausedAt {
            // Freeze the progress at where we were when paused.
            renderPaused(pausedAt: pausedAt)
            return
        }
        let elapsed = Date().timeIntervalSince(phaseStart)
        let status: SessionSnapshot.Status
        let processed: Int64
        let cycleLength = Self.runSeconds + Self.idleSeconds

        if elapsed < Self.runSeconds {
            status = .running
            processed = Int64(min(Double(Self.totalBytes), Double(Self.speed) * elapsed))
        } else if elapsed < cycleLength {
            status = .finished
            processed = Self.totalBytes
        } else {
            phaseStart = Date()
            return
        }

        let progress = Double(processed) / Double(Self.totalBytes)
        let filesDone = Int(Double(Self.filesTotal) * progress)
        let currentIndex = min(Self.filesTotal, filesDone + 1)
        let currentName = String(format: "A001C%03d_demo.mxf", currentIndex)
        let etaSeconds = status == .running
            ? Int((Double(Self.totalBytes - processed) / Double(Self.speed)).rounded())
            : nil

        snapshot = SessionSnapshot(
            generatedAt: Date(),
            machineName: "Mac démo",
            sessionID: "demo-\(Int(phaseStart.timeIntervalSince1970))",
            status: status,
            startedAt: phaseStart,
            endedAt: status == .finished ? Date() : nil,
            bytesProcessed: processed,
            bytesTotal: Self.totalBytes,
            filesProcessed: filesDone,
            filesTotal: Self.filesTotal,
            bytesPerSecond: status == .running ? Self.speed : 0,
            etaSeconds: etaSeconds,
            foundCount: Self.filesTotal,
            copiedCount: filesDone,
            verifiedCount: max(0, filesDone - 2),
            failedCount: 0,
            currentFile: status == .running ? currentName : nil,
            mode: "Copie + vérification",
            algorithm: "xxhash3 (64-bit)",
            sourceNames: ["A_CAM (SDXC 256 Go)"],
            destinationNames: ["Bay 1 (Samsung T7)", "Bay 2 (LaCie 2big)"],
            recentErrors: [],
            recentLogs: makeLogs(filesDone: filesDone, status: status)
        )
    }

    private func renderPaused(pausedAt: Date) {
        let elapsed = pausedAt.timeIntervalSince(phaseStart)
        let processed = Int64(min(Double(Self.totalBytes), Double(Self.speed) * elapsed))
        let progress = Double(processed) / Double(Self.totalBytes)
        let filesDone = Int(Double(Self.filesTotal) * progress)
        snapshot?.status = .paused
        snapshot?.bytesPerSecond = 0
        snapshot?.etaSeconds = nil
        snapshot?.currentFile = String(format: "A001C%03d_demo.mxf", min(Self.filesTotal, filesDone + 1))
        snapshot?.copiedCount = filesDone
        snapshot?.bytesProcessed = processed
        snapshot?.generatedAt = Date()
    }

    private func renderCancelled() {
        snapshot?.status = .finished
        snapshot?.bytesPerSecond = 0
        snapshot?.etaSeconds = nil
        snapshot?.currentFile = nil
        snapshot?.generatedAt = Date()
        // Auto-restart a fresh cycle after a short visible "done" state.
        // Without the guard, `tick()` queues a fresh restart task every
        // 0.5 s for the duration of the cancelled state.
        guard !cancelRestartScheduled else { return }
        cancelRestartScheduled = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            // The provider may have been stopped during the wait — don't
            // resurrect cancelled state on a dormant instance.
            guard let self, self.timer != nil else { return }
            self.cancelled = false
            self.cancelRestartScheduled = false
            self.phaseStart = Date()
        }
    }

    private func makeLogs(filesDone: Int, status: SessionSnapshot.Status) -> [SnapshotLogLine] {
        let now = Date()
        var lines: [SnapshotLogLine] = []
        let prefix = "A001C"
        if filesDone >= 1 {
            lines.append(SnapshotLogLine(
                date: now.addingTimeInterval(-25),
                level: .info,
                message: "Indexation — \(Self.filesTotal) fichiers détectés"))
        }
        if filesDone >= 3 {
            lines.append(SnapshotLogLine(
                date: now.addingTimeInterval(-18),
                level: .success,
                message: "Vérifié \(prefix)\(String(format: "%03d", filesDone - 2))_demo.mxf"))
        }
        if filesDone >= 2 {
            lines.append(SnapshotLogLine(
                date: now.addingTimeInterval(-10),
                level: .success,
                message: "Vérifié \(prefix)\(String(format: "%03d", filesDone - 1))_demo.mxf"))
        }
        if status == .running, filesDone < Self.filesTotal {
            lines.append(SnapshotLogLine(
                date: now.addingTimeInterval(-2),
                level: .info,
                message: "Copie \(prefix)\(String(format: "%03d", filesDone + 1))_demo.mxf"))
        }
        if status == .finished {
            lines.append(SnapshotLogLine(
                date: now,
                level: .success,
                message: "Terminé — \(Self.filesTotal)/\(Self.filesTotal) vérifiés"))
        }
        return lines
    }
}
