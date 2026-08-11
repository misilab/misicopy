//
//  CopyEngine.swift
//  MisiCopy
//
//  Orchestrates: file enumeration → copy to each destination →
//  checksum verification → activity log + stats.
//

import Foundation
import SwiftUI
import AppKit
import UserNotifications

/// Token-bucket rate limiter shared by every concurrent copy pipeline,
/// so the user's bandwidth cap applies to the AGGREGATE throughput —
/// two cards copying in parallel split the budget instead of each
/// getting the full cap. The bucket holds at most one second of budget,
/// which absorbs chunk-sized bursts without letting the average drift.
actor BandwidthLimiter {
    private var allowance: Double = 0
    private var lastCheck = Date()

    /// Accounts `bytes` against the shared budget and sleeps just long
    /// enough to keep the aggregate rate at `bytesPerSecond`.
    func consume(_ bytes: Int, bytesPerSecond: Double) async {
        guard bytesPerSecond > 0 else { return }
        let now = Date()
        allowance = min(bytesPerSecond,
                        allowance + now.timeIntervalSince(lastCheck) * bytesPerSecond)
        lastCheck = now
        allowance -= Double(bytes)
        if allowance < 0 {
            let wait = -allowance / bytesPerSecond
            try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
        }
    }
}

extension FileManager {
    /// Size of the regular file at `path`, or nil when it doesn't exist
    /// or isn't a regular file — one syscall for existence + type + size.
    /// Callable off the main actor (resume checks run detached).
    nonisolated func regularFileSize(atPath path: String) -> Int64? {
        guard let attrs = try? attributesOfItem(atPath: path),
              (attrs[.type] as? FileAttributeType) == .typeRegular
        else { return nil }
        return (attrs[.size] as? NSNumber)?.int64Value
    }
}

/// Coalesces per-chunk progress callbacks (1 MiB granularity from
/// ChecksumCalculator) into ≥8 MiB flushes so a 100 GB verification
/// schedules ~12 000 main-actor hops instead of ~100 000.
nonisolated final class ProgressBatcher: @unchecked Sendable {
    private let lock = NSLock()
    private var pending = 0
    private let threshold: Int
    private let onFlush: @Sendable (Int) -> Void

    init(threshold: Int = 8 << 20, onFlush: @escaping @Sendable (Int) -> Void) {
        self.threshold = threshold
        self.onFlush = onFlush
    }

    func add(_ bytes: Int) {
        lock.lock()
        pending += bytes
        let flush = pending >= threshold ? pending : 0
        if flush > 0 { pending = 0 }
        lock.unlock()
        if flush > 0 { onFlush(flush) }
    }

    /// Flushes the remainder — call once after the hashed read completes.
    func finish() {
        lock.lock()
        let rest = pending
        pending = 0
        lock.unlock()
        if rest > 0 { onFlush(rest) }
    }
}

@MainActor
@Observable
final class CopyEngine {

    // MARK: - User settings
    var mode: CopyMode = .verified
    var algorithm: ChecksumAlgorithm = .xxhash3_64
    var sources: [Source] = []
    var destinations: [Destination] = []
    var preserveStructure: Bool = true
    var simulation: Bool = false
    var language: AppLanguage = .fr
    var ejectAfterCopy: Bool = false
    var notifyOnFinish: Bool = true
    var skipSystemFiles: Bool = true
    var organizeByDate: Bool = false
    /// 0 = unlimited. Otherwise enforce maximum throughput in bytes/sec.
    var bandwidthLimitMBs: Double = 0
    /// When non-empty, files are renamed at the destination according to
    /// the token-based template (see FilenameTemplate).
    var renamingTemplate: String = ""
    var includePDFThumbnails: Bool = true
    /// Comma-separated list of file extensions to keep (e.g. "mxf, mov, wav").
    /// Empty = no inclusion filter (all extensions allowed). Persisted to
    /// UserDefaults so the user's filter selection survives quit / reboot.
    var extensionWhitelist: String = "" {
        didSet { UserDefaults.standard.set(extensionWhitelist, forKey: "extensionWhitelist") }
    }
    /// Comma-separated list of file extensions to skip (e.g. "xmp, log, thm").
    /// Empty = no exclusion filter. Persisted (see `extensionWhitelist`).
    var extensionBlacklist: String = "" {
        didSet { UserDefaults.standard.set(extensionBlacklist, forKey: "extensionBlacklist") }
    }
    /// Skip files whose destination already exists with a matching checksum.
    var skipDuplicates: Bool = false
    /// Copy multiple source cards concurrently (one pipeline per source)
    /// instead of processing all files sequentially. Persisted so the
    /// user's choice survives restarts.
    var parallelSourceCopies: Bool = false {
        didSet { UserDefaults.standard.set(parallelSourceCopies, forKey: "parallelSourceCopies") }
    }
    /// When a removable volume is detected, add it automatically as a source
    /// without showing the suggestion banner.
    var watchAutoAddSource: Bool = false
    /// When `watchAutoAddSource` triggers and destinations are configured,
    /// kick off the copy automatically.
    var watchAutoStart: Bool = false
    /// Preserve macOS Finder tags on destination files.
    var preserveFinderTags: Bool = false
    /// Recreate symbolic links at destination instead of skipping them.
    var followSymbolicLinks: Bool = false
    /// URL of an incoming Slack webhook — posts a notification on completion.
    var slackWebhookURL: String = ""
    /// Generic POST endpoint (Zapier, Make.com, Email-relay, etc.).
    var genericWebhookURL: String = ""
    /// When `true`, every destination is reorganised at copy time into the
    /// DIT-standard folder layout: `<projet>/01_RUSHES/<JJMMAA>/<cam>/<card>/…`,
    /// the PDF report lands in `00_INFOS/`, the MHL in `02_MHL/`, and the
    /// `03_PROXY/<date>/` and `04_LUT/` skeleton folders are created empty.
    var ditMode: Bool = false
    /// Project name used as the top-level folder when `ditMode` is on.
    var projectName: String = ""
    /// Customisable folder slot names for the DIT structure. Defaults are
    /// the industry-standard layout but every name is user-editable in
    /// Settings → Structure DIT.
    var ditFolderInfos: String = "00_INFOS"
    var ditFolderRushes: String = "01_RUSHES"
    var ditFolderMHL: String = "02_MHL"
    var ditFolderProxy: String = "03_PROXY"
    var ditFolderLUT: String = "04_LUT"
    /// Prefix of the auto-generated DIT report filename. Final form is
    /// `<prefix>_<JJMMAA>.pdf`.
    var ditReportPrefix: String = "rapport_DIT"
    /// Extra user-defined empty folders to create at the project root in
    /// addition to the standard five (e.g. "05_EDIT", "06_DELIVERABLES").
    /// Persisted in the engine; managed in Settings → Structure DIT.
    var ditExtraFolders: [String] = []
    /// When `true` (and DIT mode is on), each card dump lands in its own
    /// `REEL_NNN/` subfolder under the camera folder. Counter is per
    /// camera, persisted in `.misicopy-project.json` at the project root,
    /// and only committed when the copy succeeds — a failed dump can be
    /// retried with the same REEL number.
    var reelSubfolderEnabled: Bool = false

    var l10n: Localization { Localization(language: language) }

    /// Defaults applied when the user taps "Réinitialiser" in DIT settings.
    static let defaultDITFolderInfos = "00_INFOS"
    static let defaultDITFolderRushes = "01_RUSHES"
    static let defaultDITFolderMHL = "02_MHL"
    static let defaultDITFolderProxy = "03_PROXY"
    static let defaultDITFolderLUT = "04_LUT"
    static let defaultDITReportPrefix = "rapport_DIT"

    /// Date stamp used as the per-day folder name under `01_RUSHES/`.
    /// Captured once at copy start so a session that crosses midnight
    /// stays consistent. All sessions of the same day share this folder.
    private var ditDateStamp: String = ""

    /// Time stamp (HHmmss) appended to report / MHL filenames so two
    /// sessions on the same day don't overwrite each other.
    private var ditTimeStamp: String = ""

    /// Project name snapshot taken at copy start. Reading the live
    /// `projectName` mid-run would break path consistency if the user
    /// edited the field while files were still landing on disk — and
    /// would let `commitReels` write the manifest into a different
    /// project folder than the one that actually received files.
    private var ditProjectNameSnapshot: String = ""

    /// Camera tag per source URL, snapshotted at copy start. Prevents a
    /// race where the user changes the dropdown — or the background
    /// `detectCameraTag` task finishes — mid-copy, which would split
    /// a single clip across two `*_CAM/` folders.
    private var ditTagSnapshot: [URL: CameraTag] = [:]

    /// Volumes already consumed by a successful copy in this session.
    /// Watch-mode skips them so a sleep/wake cycle (which remounts the
    /// card and re-fires `didMountNotification`) doesn't silently re-copy
    /// the same card. Cleared explicitly when the user reinserts a card
    /// after physical eject.
    private var recentlyConsumedVolumes: Set<URL> = []

    /// Per-URL "about to clear the consumed-volumes guard" tasks. macOS
    /// emits a real unmount during sleep/wake on some Macs; we delay the
    /// guard removal so a quick remount keeps the volume protected. Only
    /// after ~30 s of true absence do we consider the card "really
    /// physically removed" and ready to be re-copied on next insertion.
    private var unmountClearTasks: [URL: Task<Void, Never>] = [:]

    /// REEL folder name per source URL, allocated at copy start when the
    /// REEL feature is on. Empty when the feature is off — callers fall
    /// back to `item.sourceRootName`.
    private var ditReelSnapshot: [URL: String] = [:]

    /// Transient end-of-copy outcome surfaced for ~6s so the UI can show
    /// a success / failure / cancelled flash banner. Auto-clears so the
    /// banner fades out by itself without the UI needing a timer.
    enum CompletionFlash: Equatable {
        case success(verified: Int, totalBytes: Int64)
        case failure(failed: Int)
        case cancelled
    }
    private(set) var completionFlash: CompletionFlash?
    private var completionFlashTask: Task<Void, Never>?

    /// End-of-run summary surfaced as a MODAL dialog on top of the
    /// transient flash banner. Only set for the final run of a chain
    /// (never between queued jobs) and skippable via Settings → General.
    struct CompletionSummary: Equatable {
        let success: Bool
        let verifyOnly: Bool
        let verified: Int
        let failed: Int
        let totalBytes: Int64
        let duration: TimeInterval
    }
    var completionSummary: CompletionSummary?

    /// Preflight failure surfaced as a blocking dialog BEFORE any byte is
    /// written: a destination doesn't have enough free space for the
    /// indexed source volume.
    struct PreflightIssue: Equatable {
        let destinationName: String
        let neededBytes: Int64
        let freeBytes: Int64
        var missingBytes: Int64 { max(0, neededBytes - freeBytes) }
    }
    var preflightIssue: PreflightIssue?
    /// User preference: show the end-of-copy dialog. On by default;
    /// plateau users running full-auto chains can switch it off.
    var completionDialogEnabled: Bool = true {
        didSet { UserDefaults.standard.set(completionDialogEnabled, forKey: "completionDialogEnabled") }
    }

    // MARK: - Runtime state
    private(set) var files: [FileItem] = []
    private(set) var logs: [LogEntry] = []
    private(set) var stats: CopyStats = .empty
    private(set) var isRunning: Bool = false
    /// True during run()'s tail (report writing, webhooks, eject) after
    /// `isRunning` flipped back to false. start() and watch auto-start
    /// refuse to launch while set — otherwise a second run could reset
    /// `files`/`stats` while the first run's tail still reads them.
    private(set) var isFinalizing: Bool = false

    // MARK: - Run snapshots
    // The user can change these settings in the UI while a run is in
    // flight; the engine must keep using the values captured at start,
    // otherwise a mid-run mode switch reroutes the remaining files (e.g.
    // verified → verifyOnly would stop copying and mark files verified),
    // and an algorithm switch would make source and destination hashes
    // incomparable.
    private var runMode: CopyMode = .verified
    private var runAlgorithm: ChecksumAlgorithm = .xxhash3_64
    private var runSimulation: Bool = false

    /// The saved session / resume ledger belongs only to real copy runs:
    /// verify-only and simulation must neither write nor clear it. Use
    /// this inside a run; use `nextRunOwnsSession` at pre-run call sites
    /// (before beginRun snapshots the settings).
    private var runOwnsSession: Bool { runMode != .verifyOnly && !runSimulation }
    private var nextRunOwnsSession: Bool { mode != .verifyOnly && !simulation }

    /// Read or written bytes each destination costs per source byte for
    /// the current run — 1 for the copy itself, +1 for the verification
    /// read, +1 for the double-verified source re-read. Derived, so it
    /// can never go stale between runs.
    private var runUnitsPerDest: Int64 {
        if runSimulation { return 1 }
        switch runMode {
        case .fast, .verifyOnly: return 1
        case .verified: return 2
        case .doubleVerified: return 3
        }
    }
    /// Date folder used by `organizeByDate`, frozen at run start (and
    /// restored on resume so remaining files join the original folder).
    private var organizeDateStamp: String = ""

    /// Destinations split at run start: primaries are written from the
    /// source card (phase 1); cascades are fed from the FIRST primary
    /// once the primary copy is fully verified (phase 2), so the card
    /// is released as early as possible.
    private var runPrimaries: [Destination] = []
    private var runCascades: [Destination] = []
    private(set) var currentFileName: String?
    private(set) var startDate: Date?
    private(set) var endDate: Date?
    private(set) var suggestedRemovable: [Source] = []
    private(set) var queue: [CopyJob] = []
    private(set) var isPaused: Bool = false
    private let sessionStore = SessionStore()
    let history = HistoryStore()
    private let ditSettingsStore = JSONFileStore(filename: "dit-settings.json")
    /// One shared limiter for the whole engine — see `BandwidthLimiter`.
    private let bandwidthLimiter = BandwidthLimiter()
    /// Depth-1 verification pipeline, one chain per source root: while
    /// file N+1 is being copied, the verification of file N runs in its
    /// root's task. The next process() call for the same root awaits it
    /// before kicking off its own verify. Keyed per root so parallel
    /// source copies each keep their own pipeline.
    private var verifyTasks: [URL: Task<Void, Never>] = [:]

    // MARK: - Interrupted-copy resume

    /// Files verified during the current run (or carried over from the
    /// interrupted run being resumed). Key = `<sourceRootPath>\u{0}<rel>`,
    /// value = source checksum ("" in fast mode). Persisted throttled to
    /// the session store so a cancel — or a crash — can resume later.
    private var completedThisRun: [String: String] = [:]

    /// Completed-file map loaded from the saved session (via the resume
    /// banner) or armed by a cancel. Consumed by the next run(): matching
    /// files whose destinations still hold a same-size copy are skipped.
    private var pendingResumeCompleted: [String: String] = [:]

    /// Exact destination paths written for each completed file (same key
    /// as `completedThisRun`). Resume validates these recorded paths —
    /// not a re-derivation from today's settings.
    private var completedTargets: [String: [String]] = [:]
    private var pendingResumeTargets: [String: [String]] = [:]

    /// Layout stamps of the interrupted run (DIT date folder, organize-by-
    /// date folder, per-source REEL names), armed alongside the resume map
    /// so the resumed run writes the remaining files into the SAME folders.
    private var pendingResumeStamps: (dit: String, organize: String, reels: [String: String])?

    /// Last time the in-progress session (with its completed-file map)
    /// was flushed to disk. Saves are throttled to one every 2 s so a
    /// 10 000-file card doesn't hammer the disk with JSON writes.
    private var lastProgressSave = Date.distantPast

    weak var license: LicenseManager?

    // MARK: - Internals
    /// Surfaces the cancel-pending state to the UI so the button can
    /// show "Annulation enregistrée" and disable itself between the
    /// click and the actual cancellation. Without this, the user clicks
    /// repeatedly because nothing visible changes immediately.
    private(set) var cancelRequested = false

    /// When `true`, the next `beginRun()` reuses the already-populated
    /// `files` array as-is and `run()` iterates only `retryIndices`
    /// instead of re-enumerating from disk. Consumed by `run()` so a
    /// subsequent normal `start()` re-enumerates as usual.
    private var retryingFailedOnly = false

    /// Indices into `files` to re-process on the next retry run. Populated
    /// by `retryFailedFiles()`, drained by `run()`. The previously-
    /// verified entries stay in `files` untouched, so the end-of-run PDF
    /// / MHL reports still cover the full original set.
    private var retryIndices: [Int] = []
    private var speedSamples: [(Date, Int64)] = []
    private nonisolated(unsafe) var volumeObservers: [Any] = []
    private var notificationsAuthorized: Bool? = nil

    static let systemFileBlocklist: Set<String> = [
        ".DS_Store", ".Spotlight-V100", ".Trashes", ".fseventsd",
        ".TemporaryItems", ".DocumentRevisions-V100",
        ".com.apple.timemachine.donotpresent", ".com.apple.metadata",
        ".VolumeIcon.icns", "$RECYCLE.BIN", "System Volume Information",
        ".AppleDouble", ".LSOverride", "Thumbs.db", "desktop.ini"
    ]

    init() {
        startObservingRemovableVolumes()
        loadDITSettings()
        // Restore extension filters from previous launch.
        if let w = UserDefaults.standard.string(forKey: "extensionWhitelist") {
            extensionWhitelist = w
        }
        if let b = UserDefaults.standard.string(forKey: "extensionBlacklist") {
            extensionBlacklist = b
        }
        parallelSourceCopies = UserDefaults.standard.bool(forKey: "parallelSourceCopies")
        if UserDefaults.standard.object(forKey: "completionDialogEnabled") != nil {
            completionDialogEnabled = UserDefaults.standard.bool(forKey: "completionDialogEnabled")
        }
    }

    // MARK: - DIT settings persistence

    /// Codable snapshot of the configurable DIT layout. Persisted to JSON
    /// so the user's folder names + extras + report prefix + the toggle
    /// + project name all survive app restarts.
    private struct DITSettingsSnapshot: Codable {
        var folderInfos: String
        var folderRushes: String
        var folderMHL: String
        var folderProxy: String
        var folderLUT: String
        var reportPrefix: String
        var extraFolders: [String]
        // Added in 1.3.0 — optional so older JSON files still decode and
        // the old defaults kick in for users upgrading.
        var enabled: Bool?
        var projectName: String?
        // Added in 1.6.0 — REEL subfolder per dump.
        var reelSubfolder: Bool?
    }

    private func loadDITSettings() {
        guard let s = ditSettingsStore.load(as: DITSettingsSnapshot.self) else { return }
        ditFolderInfos = s.folderInfos
        ditFolderRushes = s.folderRushes
        ditFolderMHL = s.folderMHL
        ditFolderProxy = s.folderProxy
        ditFolderLUT = s.folderLUT
        ditReportPrefix = s.reportPrefix
        ditExtraFolders = s.extraFolders
        if let enabled = s.enabled { ditMode = enabled }
        if let name = s.projectName { projectName = name }
        if let reel = s.reelSubfolder { reelSubfolderEnabled = reel }
    }

    /// Persists the DIT folder customisations + the toggle + the project
    /// name. Call after any change in Settings → Structure DIT or in the
    /// main window's DIT section.
    func saveDITSettings() {
        ditSettingsStore.save(DITSettingsSnapshot(
            folderInfos: ditFolderInfos,
            folderRushes: ditFolderRushes,
            folderMHL: ditFolderMHL,
            folderProxy: ditFolderProxy,
            folderLUT: ditFolderLUT,
            reportPrefix: ditReportPrefix,
            extraFolders: ditExtraFolders,
            enabled: ditMode,
            projectName: projectName,
            reelSubfolder: reelSubfolderEnabled
        ))
    }

    nonisolated deinit {
        for observer in volumeObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    /// Surfaces a transient end-of-copy flash for the UI banner. The
    /// previous flash (if any) is cancelled so back-to-back jobs don't
    /// pile up and the banner always represents the latest outcome.
    private func flashCompletion(_ outcome: CompletionFlash) {
        completionFlashTask?.cancel()
        completionFlash = outcome
        completionFlashTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            guard !Task.isCancelled else { return }
            self?.completionFlash = nil
        }
    }

    // MARK: - Public commands

    func addSource(_ url: URL) {
        guard !sources.contains(where: { $0.url == url }) else { return }
        let keys: Set<URLResourceKey> = [.volumeURLKey, .volumeIsRemovableKey,
                                         .volumeIsEjectableKey, .volumeIsInternalKey]
        let values = try? url.resourceValues(forKeys: keys)
        let isRemovable = values?.volumeIsRemovable == true
        let isInternal = values?.volumeIsInternal == true
        let isEjectable = (values?.volumeIsEjectable == true || isRemovable) && !isInternal
        let volumeURL = values?.volume
        // Detect synchronously — the scan is bounded to 300 entries so the
        // worst case stays well below a hundred ms even on slow card
        // readers, and it removes the race with watchAutoStart (which used
        // to start the copy before the async detection finished).
        // Sound recorders never expose A###_/B### filenames, so probe for
        // audio dominance first and only fall back to camera-letter parsing
        // when the source doesn't look like an audio card.
        let detectedTag: CameraTag = {
            if Self.isAudioDominant(in: url) { return .son }
            return Self.detectCameraTag(in: url) ?? .a
        }()
        sources.append(Source(url: url,
                              volumeURL: volumeURL,
                              isEjectable: isEjectable,
                              isRemovableMedia: isRemovable,
                              cameraTag: detectedTag))
        log(.info, l10n.logSourceSelected(url.lastPathComponent))
    }

    /// Scans the source root for a clip name that signals which camera the
    /// card came from. Matches the typical pro naming conventions:
    ///   • RED   : `A001_C001_0617HS.R3D`         → `A###_`
    ///   • ARRI  : `A001C001_220607_R1AB.mxf`     → `A###C`
    ///   • Sony  : `B007C015_220607_R1S1.mxf`     → `B###C`
    /// Returns the matching `CameraTag` (.a / .b / .c / .d) or `nil` when
    /// nothing identifiable is found — the caller falls back to `.a` and
    /// the user can override via the per-source picker.
    nonisolated private static func detectCameraTag(in url: URL) -> CameraTag? {
        let fm = FileManager.default
        // `[_C]` after the 3 digits catches both RED's `A001_…` and the
        // ARRI/Sony glued style `A001C001_…`.
        guard let pattern = try? NSRegularExpression(pattern: #"^([A-D])\d{3}[_C]"#)
        else { return nil }

        func tagFor(_ name: String) -> CameraTag? {
            guard let m = pattern.firstMatch(in: name,
                                             range: NSRange(name.startIndex..., in: name)),
                  let letterRange = Range(m.range(at: 1), in: name)
            else { return nil }
            switch String(name[letterRange]).lowercased() {
            case "a": return .a
            case "b": return .b
            case "c": return .c
            case "d": return .d
            default: return nil
            }
        }

        // Walk the tree with a hard cap so we never block the caller —
        // most cards reveal the answer in the first dozen entries.
        let enumerator = fm.enumerator(at: url,
                                       includingPropertiesForKeys: [.isRegularFileKey],
                                       options: [.skipsHiddenFiles])
        var checked = 0
        while let next = enumerator?.nextObject() as? URL, checked < 300 {
            if let tag = tagFor(next.lastPathComponent) { return tag }
            checked += 1
        }
        return nil
    }

    /// Scans the source root for a clip name that exposes a REEL number
    /// matching the camera convention `[A-D]NNN_…` (RED) or `[A-D]NNNC…`
    /// (ARRI/Sony). Returns the parsed 3-digit number (e.g. `A006_…` →
    /// `6`) so the REEL folder can mirror what's literally on the card —
    /// the DIT plateau workflow most users actually have. Returns `nil`
    /// when nothing matches and the caller should fall back to the
    /// sequential counter.
    nonisolated private static func detectReelNumber(in url: URL) -> Int? {
        guard let pattern = try? NSRegularExpression(pattern: #"^[A-D](\d{3})[_C]"#)
        else { return nil }

        func numberFor(_ name: String) -> Int? {
            guard let m = pattern.firstMatch(in: name,
                                             range: NSRange(name.startIndex..., in: name)),
                  let digitsRange = Range(m.range(at: 1), in: name)
            else { return nil }
            return Int(name[digitsRange])
        }

        // Single-file drop: parse directly from the filename.
        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        if !isDir { return numberFor(url.lastPathComponent) }

        let fm = FileManager.default
        let enumerator = fm.enumerator(at: url,
                                       includingPropertiesForKeys: [.isRegularFileKey],
                                       options: [.skipsHiddenFiles])
        var checked = 0
        while let next = enumerator?.nextObject() as? URL, checked < 300 {
            if let n = numberFor(next.lastPathComponent) { return n }
            checked += 1
        }
        return nil
    }

    /// Returns true when the source looks like a sound recorder card or a
    /// single audio file. Same 300-entry cap as `detectCameraTag` so we
    /// never block the UI.
    ///   • single audio file dropped → true
    ///   • folder with ≥ 70 % audio files (min 2 scanned) → true
    nonisolated private static func isAudioDominant(in url: URL) -> Bool {
        // Single-file drop: trust the extension directly.
        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        if !isDir { return CameraFormatDetector.isAudio(url) }

        let fm = FileManager.default
        let enumerator = fm.enumerator(at: url,
                                       includingPropertiesForKeys: [.isRegularFileKey],
                                       options: [.skipsHiddenFiles])
        var audio = 0
        var other = 0
        var checked = 0
        while let next = enumerator?.nextObject() as? URL, checked < 300 {
            let isFile = (try? next.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false
            if isFile {
                if CameraFormatDetector.isAudio(next) { audio += 1 } else { other += 1 }
            }
            checked += 1
        }
        let total = audio + other
        guard total >= 2 else { return false }
        return Double(audio) / Double(total) >= 0.7
    }

    func removeSource(_ source: Source) {
        sources.removeAll { $0.id == source.id }
    }

    func acceptSuggestedSource(_ source: Source) {
        if !sources.contains(where: { $0.url == source.url }) {
            sources.append(source)
            log(.info, l10n.logSourceSelected(source.displayName))
        }
        suggestedRemovable.removeAll { $0.id == source.id }
    }

    func dismissSuggestion(_ source: Source) {
        suggestedRemovable.removeAll { $0.id == source.id }
    }

    func addDestination(_ url: URL) {
        guard !destinations.contains(where: { $0.url == url }) else { return }
        let destination = Destination(url: url)
        destinations.append(destination)
        log(.info, l10n.logDestAdded(url.lastPathComponent))
        measureDestinationSpeed(destination)
    }

    func removeDestination(_ destination: Destination) {
        destinations.removeAll { $0.id == destination.id }
        destinationSpeeds.removeValue(forKey: destination.url)
    }

    // MARK: - Destination speed badges

    /// Measured sequential write speed (MB/s) per destination URL —
    /// displayed as a badge so the user can tell at a glance which drive
    /// is the fast one (direct) and which is the slow one (cascade
    /// candidate). Cached per VOLUME in UserDefaults: a drive's class
    /// doesn't change between sessions, so a known disk shows instantly.
    private(set) var destinationSpeeds: [URL: Double] = [:]
    private var speedProbesInFlight: Set<URL> = []

    /// Benchmarks `destination` with a small 64 MB probe (~1 s). Serves
    /// the cached value unless `force` — clicking the badge re-measures.
    func measureDestinationSpeed(_ destination: Destination, force: Bool = false) {
        let url = destination.url
        guard !speedProbesInFlight.contains(url) else { return }
        let volume = (try? url.resourceValues(forKeys: [.volumeURLKey]).volume) ?? url
        let cacheKey = "driveSpeed:\(volume.path)"
        if !force, let cached = UserDefaults.standard.object(forKey: cacheKey) as? Double {
            destinationSpeeds[url] = cached
            return
        }
        // Never write a probe file while a copy is hammering the disks.
        guard !isRunning, !isFinalizing else { return }
        speedProbesInFlight.insert(url)
        Task { [weak self] in
            let result = try? await DriveSpeedTester.benchmark(at: url,
                                                               sampleSize: 64 * 1_000_000)
            guard let self else { return }
            self.speedProbesInFlight.remove(url)
            guard let result else { return }
            self.destinationSpeeds[url] = result.writeMBs
            UserDefaults.standard.set(result.writeMBs, forKey: cacheKey)
            self.log(.info, self.l10n.logDestSpeedMeasured(destination.displayName,
                                                           mbs: result.writeMBs))
        }
    }

    /// Flips a destination between direct (fed from the card) and
    /// cascade (fed from the first direct destination after the primary
    /// copy is verified). Locked during a run — the split is snapshotted
    /// at start.
    /// Set when the user tries to flip the LAST direct destination to
    /// cascade — the UI presents an explanatory alert bound to it.
    var showCascadeNeedsDirectAlert: Bool = false

    func toggleCascade(_ destination: Destination) {
        guard !isRunning else { return }
        guard let index = destinations.firstIndex(where: { $0.id == destination.id }) else { return }
        // Refuse to flip the last direct destination: a cascade needs at
        // least one direct destination to feed from. Explained via an
        // alert rather than a buried log line.
        if !destinations[index].isCascade {
            let directCount = destinations.filter { !$0.isCascade }.count
            if directCount <= 1 {
                showCascadeNeedsDirectAlert = true
                return
            }
        }
        destinations[index].isCascade.toggle()
        log(.info, destinations[index].isCascade
            ? l10n.logCascadeEnabled(destinations[index].displayName)
            : l10n.logCascadeDisabled(destinations[index].displayName))
    }

    /// Ejects the volume backing `destination`. Runs the synchronous
    /// `unmountAndEjectDevice` off the main actor so the UI never hangs.
    /// The volume URL is resolved from the destination path because the
    /// user may have picked a subfolder of the drive.
    func ejectDestination(_ destination: Destination) {
        guard !isRunning else { return }
        let url = destination.url
        let volumeURL = (try? url.resourceValues(forKeys: [.volumeURLKey]).volume) ?? url
        log(.info, l10n.logEjectAttempt(volumeURL.lastPathComponent))
        Task { [weak self] in
            let outcome: Result<Void, Error> = await Task.detached {
                do {
                    try NSWorkspace.shared.unmountAndEjectDevice(at: volumeURL)
                    return .success(())
                } catch {
                    return .failure(error)
                }
            }.value
            guard let self else { return }
            switch outcome {
            case .success:
                self.destinations.removeAll { $0.id == destination.id }
                self.log(.success, self.l10n.logEjected(volumeURL.lastPathComponent))
            case .failure(let error):
                let ns = error as NSError
                let detail = "\(error.localizedDescription) [\(ns.domain) #\(ns.code)]"
                self.log(.warning, self.l10n.logEjectFailed(volumeURL.lastPathComponent, detail))
            }
        }
    }

    func clearLogs() {
        logs.removeAll()
    }

    // MARK: - MHL verification

    func verifyMHL(at mhlURL: URL, sourceRoot: URL?) {
        guard !isRunning, !isFinalizing else { return }
        isRunning = true
        startDate = Date()
        endDate = nil
        stats = .empty
        files = []
        currentFileName = nil
        cancelRequested = false
        ioBytesForSpeed = 0
        speedSamples = [(Date(), 0)]

        Task { await runVerify(mhlURL: mhlURL, sourceRoot: sourceRoot) }
    }

    private func runVerify(mhlURL: URL, sourceRoot: URL?) async {
        let access = mhlURL.startAccessingSecurityScopedResource()
        let rootAccess = sourceRoot?.startAccessingSecurityScopedResource() ?? false
        defer {
            if access { mhlURL.stopAccessingSecurityScopedResource() }
            if rootAccess { sourceRoot?.stopAccessingSecurityScopedResource() }
        }

        log(.info, l10n.logVerifyStart(mhlURL.lastPathComponent))
        let entries: [MHLEntry]
        do {
            entries = try MHLVerifier.parse(mhlURL)
        } catch {
            log(.error, l10n.logVerifyParseFailed(error.localizedDescription))
            isRunning = false
            endDate = Date()
            return
        }

        let root = sourceRoot ?? mhlURL.deletingLastPathComponent()
        stats.found = entries.count
        stats.totalBytes = entries.reduce(0) { $0 + $1.size }
        log(.info, l10n.logFilesFound(count: entries.count,
                                      bytes: formatBytes(stats.totalBytes)))

        for entry in entries {
            if cancelRequested { break }
            currentFileName = (entry.relativePath as NSString).lastPathComponent
            let result = await MHLVerifier.verify(entry: entry, in: root)
            applyChunk(Int(entry.size))
            switch result.status {
            case .match:
                stats.verified += 1
                log(.success, l10n.logVerifyMatch(entry.relativePath))
            case .mismatch(let found):
                stats.failed += 1
                log(.error, l10n.logVerifyMismatch(entry.relativePath,
                                                   expected: entry.expectedHash,
                                                   found: found))
            case .missing:
                stats.failed += 1
                log(.error, l10n.logVerifyMissing(entry.relativePath))
            case .readError(let reason):
                stats.failed += 1
                log(.error, l10n.logVerifyReadError(entry.relativePath, reason))
            }
        }

        endDate = Date()
        isRunning = false
        currentFileName = nil

        if cancelRequested {
            log(.warning, l10n.logCancelled)
        } else if stats.failed == 0 {
            log(.success, l10n.logVerifyDoneOK(stats.verified))
        } else {
            log(.error, l10n.logVerifyDoneWithErrors(stats.failed))
        }
        sendCompletionNotification(success: stats.failed == 0 && !cancelRequested)
    }

    // MARK: - Presets

    func applyPreset(_ preset: Preset) {
        mode = preset.mode
        algorithm = preset.algorithm
        preserveStructure = preset.preserveStructure
        ejectAfterCopy = preset.ejectAfterCopy
        notifyOnFinish = preset.notifyOnFinish
        skipSystemFiles = preset.skipSystemFiles
        organizeByDate = preset.organizeByDate
        log(.info, l10n.logPresetApplied(preset.name))
    }

    func capturePreset(named name: String) -> Preset {
        Preset(
            name: name,
            mode: mode,
            algorithm: algorithm,
            preserveStructure: preserveStructure,
            ejectAfterCopy: ejectAfterCopy,
            notifyOnFinish: notifyOnFinish,
            skipSystemFiles: skipSystemFiles,
            organizeByDate: organizeByDate
        )
    }

    func cancel() {
        guard isRunning, !cancelRequested else { return }
        cancelRequested = true
        isPaused = false
        log(.warning, l10n.logCancelRequested)
    }

    func togglePause() {
        guard isRunning else { return }
        isPaused.toggle()
        log(.info, isPaused ? l10n.logPaused : l10n.logResumed)
    }

    /// Suspension point used by the copy pipeline to honour the pause flag.
    nonisolated func waitWhilePausedFromBackground() async {
        while await MainActor.run(body: { self.isPaused && !self.cancelRequested }) {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    @MainActor func runDriveSpeedTest(at folder: URL) {
        Task {
            log(.info, l10n.logSpeedTestStart(folder.lastPathComponent))
            do {
                let result = try await DriveSpeedTester.benchmark(at: folder)
                log(.success, l10n.logSpeedTestResult(
                    folder: folder.lastPathComponent,
                    writeMBs: result.writeMBs,
                    readMBs: result.readMBs))
            } catch {
                log(.error, l10n.logSpeedTestFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - Queue

    func captureJob() -> CopyJob {
        CopyJob(
            sources: sources, destinations: destinations,
            mode: mode, algorithm: algorithm,
            preserveStructure: preserveStructure,
            ejectAfterCopy: ejectAfterCopy,
            notifyOnFinish: notifyOnFinish,
            skipSystemFiles: skipSystemFiles,
            organizeByDate: organizeByDate,
            simulation: simulation
        )
    }

    private func applyJob(_ job: CopyJob) {
        sources = job.sources
        destinations = job.destinations
        mode = job.mode
        algorithm = job.algorithm
        preserveStructure = job.preserveStructure
        ejectAfterCopy = job.ejectAfterCopy
        notifyOnFinish = job.notifyOnFinish
        skipSystemFiles = job.skipSystemFiles
        organizeByDate = job.organizeByDate
        simulation = job.simulation
    }

    func enqueueCurrent() {
        guard !sources.isEmpty, !destinations.isEmpty else {
            log(.error, l10n.logQueueNeedsSrcDest)
            return
        }
        let job = captureJob()
        queue.append(job)
        log(.info, l10n.logJobQueued(job.summary))
    }

    func removeFromQueue(_ jobID: UUID) {
        queue.removeAll { $0.id == jobID }
    }

    /// Moves a queued job one slot toward the front (`up == true`) or the
    /// back. The front of the queue runs first — this is how the user
    /// prioritises pending cards.
    func moveQueueJob(_ jobID: UUID, up: Bool) {
        guard let index = queue.firstIndex(where: { $0.id == jobID }) else { return }
        let target = up ? index - 1 : index + 1
        guard queue.indices.contains(target) else { return }
        queue.swapAt(index, target)
    }

    func clearQueue() {
        queue.removeAll()
    }

    // MARK: - Session restore

    var resumableSession: SavedSession? { sessionStore.saved }

    func resumeLastSession() {
        guard let saved = sessionStore.saved else { return }
        mode = saved.mode
        algorithm = saved.algorithm
        preserveStructure = saved.preserveStructure
        ejectAfterCopy = saved.ejectAfterCopy
        notifyOnFinish = saved.notifyOnFinish
        skipSystemFiles = saved.skipSystemFiles
        organizeByDate = saved.organizeByDate
        sources.removeAll()
        destinations.removeAll()
        for path in saved.sourcePaths { addSource(URL(fileURLWithPath: path)) }
        for path in saved.destinationPaths { addDestination(URL(fileURLWithPath: path)) }
        if let cascadePaths = saved.cascadeDestinationPaths {
            for i in destinations.indices where cascadePaths.contains(destinations[i].path) {
                destinations[i].isCascade = true
            }
        }
        // Arm the resume map — the next run() skips these files as long
        // as the destinations still hold a same-size copy — along with
        // the recorded target paths and the interrupted run's layout
        // stamps (DIT date, organize-by-date folder, REEL names).
        pendingResumeCompleted = saved.completedFiles ?? [:]
        pendingResumeTargets = saved.completedTargets ?? [:]
        if saved.resumeDitDateStamp != nil || saved.resumeOrganizeDateStamp != nil
            || saved.resumeReelFolders != nil {
            pendingResumeStamps = (dit: saved.resumeDitDateStamp ?? "",
                                   organize: saved.resumeOrganizeDateStamp ?? "",
                                   reels: saved.resumeReelFolders ?? [:])
        }
        log(.info, l10n.logSessionResumed)
        dismissResumableSession()
    }

    func dismissResumableSession() {
        sessionStore.clear()
    }

    private func saveCurrentSession() {
        sessionStore.save(currentSessionSnapshot())
    }

    /// Same as `saveCurrentSession()` but performs the JSON encode + disk
    /// write off the main actor. Used by the throttled mid-run progress
    /// saves: serializing a 40 000-entry completed map on the main thread
    /// every 2 s would hitch the UI for the whole copy.
    private func saveCurrentSessionInBackground() {
        sessionStore.saveInBackground(currentSessionSnapshot())
    }

    private func currentSessionSnapshot() -> SavedSession {
        // The layout stamps only matter when the snapshot carries resume
        // data — they travel with the completed map they belong to.
        let hasResume = !completedThisRun.isEmpty
        var reels: [String: String] = [:]
        if hasResume {
            for (url, reel) in ditReelSnapshot { reels[url.path] = reel }
        }
        return SavedSession(
            savedAt: Date(),
            sourcePaths: sources.map(\.path),
            destinationPaths: destinations.map(\.path),
            mode: mode, algorithm: algorithm,
            preserveStructure: preserveStructure,
            ejectAfterCopy: ejectAfterCopy,
            notifyOnFinish: notifyOnFinish,
            skipSystemFiles: skipSystemFiles,
            organizeByDate: organizeByDate,
            completedFiles: completedThisRun.isEmpty ? nil : completedThisRun,
            completedTargets: completedTargets.isEmpty ? nil : completedTargets,
            resumeDitDateStamp: hasResume ? ditDateStamp : nil,
            resumeOrganizeDateStamp: hasResume ? organizeDateStamp : nil,
            resumeReelFolders: reels.isEmpty ? nil : reels,
            cascadeDestinationPaths: {
                let cascades = destinations.filter(\.isCascade).map(\.path)
                return cascades.isEmpty ? nil : cascades
            }()
        )
    }

    /// Stable identity of a file across runs — source root + relative
    /// path. Size is re-checked at resume time against the destination.
    private static func completionKey(root: URL, relativePath: String) -> String {
        root.path + "\u{0}" + relativePath
    }

    /// Marks `item` as secured for resume purposes — with the EXACT
    /// destination paths it was written to — and flushes the session to
    /// disk (throttled, off-main). Never called in simulation (nothing
    /// landed on disk); no-op in verify-only runs (they don't own the
    /// session). Uses the run snapshots, not the live settings.
    private func recordCompletion(of item: FileItem, checksum: String?, targets: [URL]) {
        guard runOwnsSession else { return }
        let key = Self.completionKey(root: item.sourceRoot, relativePath: item.relativePath)
        completedThisRun[key] = checksum ?? ""
        completedTargets[key] = targets.map(\.path)
        if Date().timeIntervalSince(lastProgressSave) >= 2 {
            lastProgressSave = Date()
            saveCurrentSessionInBackground()
        }
    }

    /// Resume pass: matches the enumerated `files` against the armed
    /// resume map and marks the validated ones `.verified`. The
    /// existence/size checks run in ONE detached batch — tens of
    /// thousands of `stat()` calls on a big card would freeze the UI if
    /// done on the main actor. Returns the number of files skipped.
    private func applyResumeSkips() async -> Int {
        struct Candidate: Sendable {
            let index: Int
            let key: String
            let hash: String
            let size: Int64
            let recordedPaths: [String]?
        }
        var candidates: [Candidate] = []
        for i in files.indices {
            let key = Self.completionKey(root: files[i].sourceRoot,
                                         relativePath: files[i].relativePath)
            guard let storedHash = pendingResumeCompleted[key] else { continue }
            candidates.append(Candidate(index: i, key: key, hash: storedHash,
                                        size: files[i].size,
                                        recordedPaths: pendingResumeTargets[key]))
        }
        guard !candidates.isEmpty else { return 0 }

        // Cascade destinations are filled in phase 2 (idempotently), so
        // a completed file only needs its PRIMARY copies to still exist.
        let destinationCount = runPrimaries.count
        let checked: [Bool] = await Task.detached(priority: .userInitiated) { [candidates] in
            let fm = FileManager.default
            return candidates.map { c in
                guard let paths = c.recordedPaths, paths.count >= destinationCount
                else { return false }
                return paths.allSatisfy { fm.regularFileSize(atPath: $0) == c.size }
            }
        }.value

        var skipped = 0
        for (c, ok) in zip(candidates, checked) {
            var holds = ok
            // Legacy sessions (pre-1.9.2) carry no recorded paths — fall
            // back to recomputing today's path. Rare, so main-actor cost
            // is acceptable.
            if !holds && c.recordedPaths == nil {
                holds = destinationsStillHold(files[c.index])
            }
            guard holds else { continue }
            files[c.index].status = .verified
            if !c.hash.isEmpty { files[c.index].sourceChecksum = c.hash }
            completedThisRun[c.key] = c.hash
            completedTargets[c.key] = c.recordedPaths
                ?? destinations.map { destinationURL(for: files[c.index], in: $0).path }
            skipped += 1
        }
        return skipped
    }

    /// True when every configured destination still holds `item` with
    /// the exact same size — the cheap sanity check that gates skipping
    /// a file on resume. A missing or truncated copy fails the check and
    /// the file is recopied.
    private func destinationsStillHold(_ item: FileItem) -> Bool {
        let fm = FileManager.default
        return destinations.allSatisfy { destination in
            let target = destinationURL(for: item, in: destination)
            return fm.regularFileSize(atPath: target.path) == item.size
        }
    }

    func start() {
        guard !isRunning, !isFinalizing else { return }
        // MisiCopy is now free — no licence gate. The licence key only
        // silences the donation reminder on quit (.licensed status).
        guard !sources.isEmpty else {
            log(.error, l10n.logNoSource)
            return
        }
        guard !destinations.isEmpty else {
            log(.error, l10n.logNoDestination)
            return
        }

        // A normal start always re-enumerates the sources — make sure a
        // stale retry flag from a previous interaction can't sneak in.
        retryingFailedOnly = false
        retryIndices = []
        // Verify-only runs never touch the saved session: they must not
        // overwrite (or later clear) the resume state of an interrupted
        // copy the user may still want to finish.
        if nextRunOwnsSession { saveCurrentSession() }
        requestNotificationAuthorizationIfNeeded()
        beginRun()
    }

    /// Count of files that ended the last run in a failed state. Surfaced
    /// to the UI so the "Recopier les fichiers en erreur" button can show
    /// its badge and stay hidden when there's nothing to retry.
    var failedFileCount: Int {
        files.reduce(0) { acc, item in
            if case .failed = item.status { return acc + 1 }
            return acc
        }
    }

    /// Re-runs the pipeline with ONLY the files that failed during the
    /// previous run. Sources, destinations and the existing `files`
    /// array stay intact — verified entries keep their status so the
    /// end-of-run PDF / MHL still describe the full original set. Only
    /// the failed items get their status reset to .pending and their
    /// indices queued in `retryIndices`. The retry-run's `stats` reflect
    /// only the failed-subset work being redone. Disabled while a run
    /// is in flight or when there's nothing to retry.
    func retryFailedFiles() {
        guard !isRunning, !isFinalizing else { return }
        guard !sources.isEmpty, !destinations.isEmpty else { return }
        var indices: [Int] = []
        for i in files.indices {
            if case .failed = files[i].status {
                files[i].status = .pending
                files[i].sourceChecksum = nil
                files[i].destinationChecksums = [:]
                indices.append(i)
            }
        }
        guard !indices.isEmpty else { return }
        retryIndices = indices
        retryingFailedOnly = true
        log(.info, l10n.logRetryFailedStart(count: indices.count))
        // Same session rule as start(): a verify-only retry must not
        // overwrite the resume state of an interrupted copy.
        if nextRunOwnsSession { saveCurrentSession() }
        requestNotificationAuthorizationIfNeeded()
        beginRun()
    }

    private func beginRun() {
        cancelRequested = false
        isRunning = true
        isFinalizing = false
        startDate = Date()
        endDate = nil
        stats = .empty
        // Freeze the settings the pipeline depends on — the UI stays
        // interactive during a run and a mid-run change must not reroute
        // files or make hashes incomparable.
        runMode = mode
        runAlgorithm = algorithm
        runSimulation = simulation
        // Split direct vs cascade destinations. Verify-only ignores the
        // cascade flag (it verifies every destination), and if the user
        // flagged EVERYTHING as cascade there is nothing to feed from —
        // fall back to treating all destinations as direct.
        runPrimaries = destinations.filter { !$0.isCascade }
        runCascades = destinations.filter(\.isCascade)
        if runPrimaries.isEmpty || runMode == .verifyOnly {
            if runPrimaries.isEmpty && !runCascades.isEmpty {
                log(.warning, l10n.logCascadeAllFallback)
            }
            runPrimaries = destinations
            runCascades = []
        }
        // The destination layout may have changed since the last run.
        verifyContainersCache = [:]
        // Cancel any in-flight 6s completion-flash from the previous
        // run so its banner doesn't sit on top of the new progress bar.
        completionFlashTask?.cancel()
        completionFlash = nil
        // On a retry pass, `files` still holds the full original set
        // (the failed items have already been reset to .pending in
        // `retryFailedFiles()`); wiping it would drop the verified
        // entries that the end-of-run PDF / MHL still need to describe.
        if !retryingFailedOnly { files = [] }
        currentFileName = nil
        ioBytesForSpeed = 0
        speedSamples = [(Date(), 0)]

        // Snapshot the date and time used by the DIT folder layout so a
        // session that runs past midnight stays internally consistent
        // AND two sessions on the same day don't overwrite each other's
        // report / MHL files.
        let stamp = DateFormatter()
        stamp.dateFormat = "ddMMyy"
        ditDateStamp = stamp.string(from: startDate ?? Date())
        let time = DateFormatter()
        time.dateFormat = "HHmmss"
        ditTimeStamp = time.string(from: startDate ?? Date())
        let organize = DateFormatter()
        organize.dateFormat = "yyyy-MM-dd"
        organizeDateStamp = organize.string(from: startDate ?? Date())

        // Freeze the per-source camera tag for the whole run, so a late
        // detection or a user-driven picker change can't reroute clips
        // mid-copy.
        ditTagSnapshot = Dictionary(uniqueKeysWithValues: sources.map { ($0.url, $0.cameraTag) })

        // Freeze the project name too — the field is bound to the live
        // text input and a mid-run edit would split files between two
        // top-level folders.
        ditProjectNameSnapshot = sanitizedProjectName

        // Allocate REEL_NNN/ folders for each source (per camera). The
        // counter is only committed to the project manifest on success.
        // Verify-only still resolves REEL folders (to find the existing
        // copy) but never creates the skeleton on disk.
        allocateReels()

        // Resuming an interrupted copy: restore the interrupted run's
        // layout stamps so the remaining files land in the SAME folders
        // (same DIT date, same organize-by-date folder, same REEL_NNN)
        // instead of splitting the card across two layouts.
        if !pendingResumeCompleted.isEmpty, runOwnsSession,
           let stamps = pendingResumeStamps {
            if !stamps.dit.isEmpty { ditDateStamp = stamps.dit }
            if !stamps.organize.isEmpty { organizeDateStamp = stamps.organize }
            for source in sources {
                if let reel = stamps.reels[source.url.path] {
                    ditReelSnapshot[source.url] = reel
                }
            }
        }

        if ditActive && runMode != .verifyOnly { createDITSkeleton() }

        Task { await run() }
    }

    /// Creates the empty DIT-standard folder skeleton on each destination,
    /// using the user-configurable folder names from Settings → DIT.
    /// `<rushes>/` is implicitly created when the first file is copied.
    private func createDITSkeleton() {
        guard !runSimulation else { return }
        let fm = FileManager.default
        for destination in destinations {
            let root = ditRoot(in: destination)
            var folders: [URL] = [
                root.appending(path: nonEmpty(ditFolderInfos, fallback: Self.defaultDITFolderInfos)),
                root.appending(path: nonEmpty(ditFolderMHL, fallback: Self.defaultDITFolderMHL)),
                root.appending(path: nonEmpty(ditFolderProxy, fallback: Self.defaultDITFolderProxy)).appending(path: ditDateStamp),
                root.appending(path: nonEmpty(ditFolderLUT, fallback: Self.defaultDITFolderLUT))
            ]
            for extra in ditExtraFolders {
                let cleaned = Self.sanitizedComponent(extra)
                if !cleaned.isEmpty {
                    folders.append(root.appending(path: cleaned))
                }
            }
            for folder in folders {
                try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
            }
        }
    }

    /// Trims, strips path separators (`/` and `\`) and leading dots so a
    /// user-supplied folder name can never escape the project root or
    /// turn into a hidden / `..` directory. Falls back to `fallback`
    /// when the result is empty.
    private func nonEmpty(_ value: String, fallback: String) -> String {
        let cleaned = Self.sanitizedComponent(value)
        return cleaned.isEmpty ? fallback : cleaned
    }

    /// Same sanitisation as `nonEmpty`, but returns the empty string when
    /// the input is blank — used for `projectName` where we need to know
    /// whether to skip DIT routing entirely.
    private static func sanitizedComponent(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "" }
        let invalid = CharacterSet(charactersIn: "/\\")
        var cleaned = trimmed
            .components(separatedBy: invalid)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
        while cleaned.hasPrefix(".") { cleaned.removeFirst() }
        return cleaned
    }

    // MARK: - Pipeline

    private func run() async {
        // Acquire security-scoped access (sandbox).
        let sourceAccess = sources.map { ($0.url, $0.url.startAccessingSecurityScopedResource()) }
        let destAccess = destinations.map { ($0.url, $0.url.startAccessingSecurityScopedResource()) }

        // Build the list of `files` indices we'll iterate this run.
        // - Normal run: enumerate sources, fill `files`, walk every index.
        // - Retry run: `files` is preserved with the verified entries
        //   intact; only the indices stored in `retryIndices` get
        //   re-processed.
        let indicesToProcess: [Int]
        var resumeSkipped = 0
        if retryingFailedOnly {
            retryingFailedOnly = false
            indicesToProcess = retryIndices
            retryIndices = []
            log(.info, l10n.logRetryFailedIndexing(count: indicesToProcess.count))
        } else {
            log(.info, l10n.logIndexing)
            var found: [FileItem] = []
            for source in sources {
                found.append(contentsOf: enumerateFiles(in: source.url))
            }
            files = found
            // Resume pass — files secured before an interruption are
            // marked verified up-front and excluded from this run's
            // workload. Validation uses the RECORDED destination paths
            // of the interrupted run (existence + size), not a
            // re-derivation from today's settings. Verify-only runs and
            // simulations deliberately ignore (and preserve) the resume
            // map: verify re-reads every byte by design, and a dry-run
            // must not consume the armed copy-resume state.
            if runOwnsSession {
                completedThisRun = [:]
                completedTargets = [:]
                if !pendingResumeCompleted.isEmpty {
                    resumeSkipped = await applyResumeSkips()
                }
                pendingResumeCompleted = [:]
                pendingResumeTargets = [:]
                pendingResumeStamps = nil
            }
            indicesToProcess = files.indices.filter { i in
                if case .verified = files[i].status { return false }
                return true
            }
            if resumeSkipped > 0 {
                stats.verified += resumeSkipped
                stats.copied += resumeSkipped
                log(.info, l10n.logResumeSkipped(count: resumeSkipped))
            }
        }
        stats.found = indicesToProcess.count + resumeSkipped
        // Two separate budgets:
        // - totalBytes = the DATA VOLUME of the run (bytes written for a
        //   copy, bytes verified for verify-only). This is what the
        //   banner, the history and the reports display.
        // - workBudget = every byte the run has to read or write (copy +
        //   verification re-reads), driving the progress bar so it only
        //   reaches 100 % when the trailing verifications finish.
        let totalSourceBytes = indicesToProcess.reduce(Int64(0)) { $0 + files[$1].size }
        if runMode == .verifyOnly {
            let destCount = Int64(max(1, destinations.count))
            stats.totalBytes = totalSourceBytes
            stats.workBudget = runSimulation
                ? totalSourceBytes
                : totalSourceBytes * (1 + destCount)
        } else {
            // Cascades cost one write each plus one verification read
            // (they are fed from the primary, not the card).
            let primaryCount = Int64(max(1, runPrimaries.count))
            let cascadeCount = Int64(runCascades.count)
            let cascadeUnits: Int64 = (runSimulation || runMode == .fast) ? 1 : 2
            stats.totalBytes = totalSourceBytes * (primaryCount + cascadeCount)
            stats.workBudget = totalSourceBytes * runUnitsPerDest * primaryCount
                + totalSourceBytes * cascadeUnits * cascadeCount
        }
        log(.info, l10n.logFilesFound(count: indicesToProcess.count, bytes: formatBytes(totalSourceBytes)))

        // Preflight — every destination (direct AND cascade) will receive
        // the full indexed volume; refuse to start rather than discover a
        // full disk at 80 %. Skipped for simulations and verify-only runs
        // (nothing is written).
        if !runSimulation && runMode != .verifyOnly && totalSourceBytes > 0 {
            for destination in destinations {
                let free = Self.freeSpace(at: destination.url)
                if free >= 0 && free < totalSourceBytes {
                    let issue = PreflightIssue(destinationName: destination.displayName,
                                               neededBytes: totalSourceBytes,
                                               freeBytes: free)
                    log(.error, l10n.logPreflightSpace(destination.displayName,
                                                       missing: formatBytes(issue.missingBytes)))
                    preflightIssue = issue
                    for (url, granted) in sourceAccess where granted {
                        url.stopAccessingSecurityScopedResource()
                    }
                    for (url, granted) in destAccess where granted {
                        url.stopAccessingSecurityScopedResource()
                    }
                    endDate = Date()
                    isRunning = false
                    currentFileName = nil
                    cancelRequested = false
                    return
                }
            }
        }

        if runSimulation {
            log(.warning, l10n.logSimulation)
        }

        // Multi-card mode: one concurrent pipeline per source root, so
        // several cards offload at the same time. Sequential otherwise.
        let groups = Dictionary(grouping: indicesToProcess) { files[$0].sourceRoot }
        if parallelSourceCopies && groups.count > 1 {
            log(.info, l10n.logParallelSources(count: groups.count))
            await withTaskGroup(of: Void.self) { group in
                for (_, indices) in groups {
                    group.addTask { @MainActor [weak self] in
                        guard let self else { return }
                        for index in indices {
                            if self.cancelRequested { break }
                            await self.process(fileIndex: index)
                        }
                    }
                }
            }
        } else {
            for index in indicesToProcess {
                if cancelRequested { break }
                await process(fileIndex: index)
            }
        }

        // Drain the deferred-verify pipelines before we mark the run as
        // finished — otherwise the last file's verify could still be in
        // flight when we write the PDF / MHL reports.
        for task in verifyTasks.values { await task.value }
        verifyTasks = [:]

        // Phase 2 — cascade. The primary copy is fully verified, so the
        // source cards are no longer needed: announce it (and auto-eject
        // right away if the option is on), then feed the cascade
        // destinations from the first primary. The sources' security
        // scopes must be dropped BEFORE ejecting — macOS refuses to
        // unmount a volume with open sandbox handles.
        var ejectedEarly = false
        var sourceScopesReleased = false
        if !runCascades.isEmpty && !cancelRequested {
            log(.info, l10n.logSourcesFreed)
            if ejectAfterCopy && !runSimulation && stats.failed == 0 {
                for (url, granted) in sourceAccess where granted {
                    url.stopAccessingSecurityScopedResource()
                }
                sourceScopesReleased = true
                await ejectEjectableSources(didSucceed: true)
                ejectedEarly = true
            }
            await runCascadePhase()
        }

        endDate = Date()
        isRunning = false
        // Guard the tail (report writing, webhooks, eject, chaining):
        // start() and watch auto-start refuse to launch a new run until
        // this flips back, so a second run can't reset files/stats while
        // we still read them below.
        isFinalizing = true
        defer { isFinalizing = false }
        currentFileName = nil

        // When the current run is going to chain a queued job in a moment,
        // skip the "success" flash so the banner doesn't sit visible on top
        // of the next job's already-running progress for 6 s. Errors and
        // cancellations still flash — those are signals the user needs.
        let willChain = !cancelRequested && !queue.isEmpty
        let didSucceed: Bool
        if cancelRequested {
            log(.warning, l10n.logCancelled)
            didSucceed = false
            flashCompletion(.cancelled)
            // Real interruption support: flush the completed-file map,
            // the recorded target paths and the layout stamps, and arm
            // them so the very next start (or the resume banner after a
            // relaunch) picks up exactly where this run stopped — in the
            // same folders.
            if !completedThisRun.isEmpty && runOwnsSession {
                pendingResumeCompleted = completedThisRun
                pendingResumeTargets = completedTargets
                var reels: [String: String] = [:]
                for (url, reel) in ditReelSnapshot { reels[url.path] = reel }
                pendingResumeStamps = (dit: ditDateStamp,
                                       organize: organizeDateStamp,
                                       reels: reels)
                saveCurrentSession()
                log(.info, l10n.logResumeSaved(count: completedThisRun.count))
            }
        } else if stats.failed == 0 {
            log(.success, l10n.logDone(verified: stats.verified, found: stats.found))
            await writePDFReports()
            didSucceed = true
            if !willChain {
                flashCompletion(.success(verified: stats.verified, totalBytes: stats.totalBytes))
            }
        } else {
            log(.error, l10n.logDoneWithErrors(stats.failed))
            await writePDFReports()
            didSucceed = false
            flashCompletion(.failure(failed: stats.failed))
        }

        // Modal end-of-run summary — only for the LAST run of a chain
        // (a dialog between queued jobs would sit on top of the next
        // job's progress) and never for a user-initiated cancel.
        if completionDialogEnabled && !cancelRequested && !willChain,
           let start = startDate, let end = endDate {
            completionSummary = CompletionSummary(
                success: didSucceed,
                verifyOnly: runMode == .verifyOnly,
                verified: stats.verified,
                failed: stats.failed,
                totalBytes: stats.totalBytes,
                duration: end.timeIntervalSince(start)
            )
        }

        // Burn the allocated REEL numbers into the project manifest only
        // on a fully successful run, so a failed/cancelled dump can be
        // retried with the same REEL number.
        if didSucceed && runMode != .verifyOnly { commitReels() }
        // Mark every source volume just consumed so watch mode won't
        // silently re-trigger a copy on the next remount (sleep/wake,
        // transient USB hiccup, …). Physical eject clears this set.
        // Verify-only runs don't consume the card — the user may still
        // want to offload it afterwards.
        if didSucceed && runMode != .verifyOnly && !runSimulation {
            for source in sources {
                if let volumeURL = source.volumeURL {
                    recentlyConsumedVolumes.insert(volumeURL)
                }
                recentlyConsumedVolumes.insert(source.url)
            }
        }
        // Release the project-name snapshot so a later read of
        // `ditRoot(in:)` outside a run reflects the live field again.
        ditProjectNameSnapshot = ""
        ditReelSnapshot = [:]

        // Release security-scoped access BEFORE attempting eject, otherwise
        // macOS refuses to unmount due to open file handles. (Already done
        // early when the cascade ejected the sources ahead of phase 2.)
        if !sourceScopesReleased {
            for (url, granted) in sourceAccess where granted {
                url.stopAccessingSecurityScopedResource()
            }
        }
        for (url, granted) in destAccess where granted {
            url.stopAccessingSecurityScopedResource()
        }

        sendCompletionNotification(success: didSucceed)
        await sendWebhooks(success: didSucceed)
        if ejectAfterCopy && !cancelRequested && !runSimulation && !ejectedEarly {
            await ejectEjectableSources(didSucceed: didSucceed)
        }

        // Successful or not, the session is done — clear the saved snapshot
        // and the resume map (a cancel keeps both, see above). Verify-only
        // runs and simulations never owned the session, so they must not
        // clear it either — an interrupted copy stays resumable across a
        // verification or a dry-run.
        if !cancelRequested && runOwnsSession {
            sessionStore.clear()
            completedThisRun = [:]
            completedTargets = [:]
        }

        // Record a transfer toward the trial counter (skip pure cancel).
        if !cancelRequested {
            license?.recordTransferCompletion()
        }

        // Persist to history (skip pure cancel — keep failures, they're informative).
        if let start = startDate, let end = endDate {
            history.append(SessionRecord(
                startDate: start, endDate: end,
                sourcePaths: sources.map(\.path),
                destinationPaths: destinations.map(\.path),
                mode: runMode, algorithm: runAlgorithm,
                found: stats.found, copied: stats.copied,
                verified: stats.verified, failed: stats.failed,
                totalBytes: stats.totalBytes, simulation: runSimulation
            ))
        }

        // Chain next queued job if any (and current was not cancelled).
        if !cancelRequested, let nextJob = queue.first {
            queue.removeFirst()
            log(.info, l10n.logQueueStarting(nextJob.summary))
            applyJob(nextJob)
            // A chained verify-only job must not overwrite the saved
            // session (it would never be cleared and would resurface as
            // a phantom resume banner).
            if nextRunOwnsSession { saveCurrentSession() }
            beginRun()
        } else {
            // Clear the cancel-pending flag now that the run has fully
            // terminated. Without this, the start button stays in its
            // "Interruption enregistrée" / disabled visual state between
            // an interrupted run and the next manual start.
            cancelRequested = false
        }
    }

    private func writePDFReports() async {
        guard !runSimulation else { return }
        // Verify-only promises to write NOTHING to the destinations — no
        // PDF, no MHL. The user can still export reports via the File
        // menu; log a reminder so the absence isn't mistaken for a bug.
        guard runMode != .verifyOnly else {
            log(.info, l10n.logVerifyNoReportWritten)
            return
        }
        guard let start = startDate, let end = endDate else { return }
        let combinedSourceURL: URL? = sources.count == 1 ? sources[0].url : nil

        // Snapshot every value that the detached task needs so we never
        // touch MainActor-isolated state from off-main.
        struct Job: Sendable {
            let input: PDFReportInput
            let displayName: String
            let mhlPath: URL?
            let mhlSources: [(URL, [FileItem])]
            let l10n: Localization
            let algorithm: ChecksumAlgorithm
            let start: Date
            let end: Date
        }
        var jobs: [Job] = []
        for destination in destinations {
            var input = PDFReportInput(
                sourceURL: combinedSourceURL,
                destination: destination,
                mode: runMode,
                algorithm: runAlgorithm,
                files: files,
                stats: stats,
                startDate: start,
                endDate: end,
                l10n: l10n,
                includeThumbnails: includePDFThumbnails
            )
            var mhlPath: URL? = nil
            var mhlSources: [(URL, [FileItem])] = []
            if ditActive {
                let infosFolder = nonEmpty(ditFolderInfos, fallback: Self.defaultDITFolderInfos)
                let mhlFolder = nonEmpty(ditFolderMHL, fallback: Self.defaultDITFolderMHL)
                let reportPrefix = nonEmpty(ditReportPrefix, fallback: Self.defaultDITReportPrefix)
                input.outputDirectory = ditRoot(in: destination).appending(path: infosFolder)
                input.filenameOverride = "\(reportPrefix)_\(ditDateStamp)_\(ditTimeStamp).pdf"
                mhlPath = ditRoot(in: destination).appending(path: mhlFolder)
                mhlSources = sources.map { src in
                    (src.url, files.filter { $0.sourceRoot == src.url })
                }
            }
            jobs.append(Job(input: input,
                            displayName: destination.displayName,
                            mhlPath: mhlPath,
                            mhlSources: mhlSources,
                            l10n: l10n,
                            algorithm: algorithm,
                            start: start, end: end))
        }
        let dateStamp = ditDateStamp
        let timeStamp = ditTimeStamp

        // Heavy work (PDF rendering + MHL serialization) on a detached task
        // so the main actor stays responsive — vital for the SwiftUI UI.
        struct Outcome: Sendable {
            let ok: Bool
            let pdfFilename: String
            let displayName: String
        }
        let outcomes: [Outcome] = await Task.detached {
            var results: [Outcome] = []
            for job in jobs {
                let url = PDFReportGenerator.write(job.input)
                results.append(Outcome(
                    ok: url != nil,
                    pdfFilename: url?.lastPathComponent ?? "",
                    displayName: job.displayName
                ))
                if let mhlRoot = job.mhlPath {
                    try? FileManager.default.createDirectory(
                        at: mhlRoot, withIntermediateDirectories: true)
                    for (sourceURL, sourceFiles) in job.mhlSources where !sourceFiles.isEmpty {
                        let xml = MHLExporter.makeXML(
                            source: sourceURL,
                            destinations: [job.input.destination],
                            files: sourceFiles,
                            algorithm: job.algorithm,
                            startDate: job.start, endDate: job.end
                        )
                        let safeName = sourceURL.lastPathComponent
                            .replacingOccurrences(of: "/", with: "_")
                        let mhlURL = mhlRoot.appending(path: "\(dateStamp)_\(timeStamp)_\(safeName).mhl")
                        try? xml.write(to: mhlURL, atomically: true, encoding: .utf8)
                    }
                }
            }
            return results
        }.value

        for outcome in outcomes {
            if outcome.ok {
                log(.success, l10n.pdfReportWritten(outcome.pdfFilename, in: outcome.displayName))
            } else {
                log(.error, l10n.pdfReportFailed(outcome.displayName))
            }
        }
    }

    private func process(fileIndex: Int) async {
        if runMode == .verifyOnly {
            await processVerifyOnly(fileIndex: fileIndex)
            return
        }
        var item = files[fileIndex]
        currentFileName = item.displayName

        // Source hash is computed lazily — populated during the first
        // copy via the single-pass `parallelCopy` (read once, fan-out to
        // N destinations + hash in the same pass), or up-front via the
        // separate read when `skipDuplicates` needs to check a possibly
        // existing destination before copying.
        var sourceHash: String?

        // Pass 1 — resolve every destination's target, handling
        // skipDuplicates per-destination. Each surviving (destination,
        // target) pair becomes a pending parallel copy.
        var destinationsToVerify: [(Destination, URL)] = []
        // Every primary destination's target, dup-skipped or not —
        // recorded with the completion so resume can validate the EXACT
        // written paths. Cascade destinations are handled in phase 2.
        var allTargets: [URL] = []
        for destination in runPrimaries {
            if cancelRequested { return }
            let target = destinationURL(for: item, in: destination)
            allTargets.append(target)

            if skipDuplicates && !runSimulation && runMode != .fast,
               FileManager.default.fileExists(atPath: target.path) {
                if sourceHash == nil {
                    do {
                        item.status = .verifying
                        files[fileIndex] = item
                        sourceHash = try await ChecksumCalculator.checksum(
                            for: item.sourceURL, algorithm: runAlgorithm)
                        item.sourceChecksum = sourceHash
                    } catch {
                        fail(&item, at: fileIndex,
                             reason: l10n.logSourceReadError(error.localizedDescription))
                        return
                    }
                }
                if let existing = try? await ChecksumCalculator.checksum(for: target, algorithm: runAlgorithm),
                   existing == sourceHash {
                    log(.info, l10n.logDuplicateSkipped(item.displayName, destination.displayName))
                    item.destinationChecksums[destination.url] = existing
                    // Credit the skipped write as data volume, and the
                    // whole avoided work (copy + verify reads) toward the
                    // progress budget so the bar still lands on 100 %.
                    applyChunk(Int(item.size))
                    applyVerifyChunk(Int(item.size * (runUnitsPerDest - 1)))
                    continue
                }
            }
            destinationsToVerify.append((destination, target))
        }

        // Pass 2 — single parallel copy to every surviving destination.
        // One source read fans out to all destinations simultaneously, so
        // two-destination jobs no longer take twice as long.
        do {
            if runSimulation {
                applyChunk(Int(item.size) * destinationsToVerify.count)
            } else if !destinationsToVerify.isEmpty {
                for (_, target) in destinationsToVerify {
                    try ensureParent(for: target)
                    if FileManager.default.fileExists(atPath: target.path) {
                        try FileManager.default.removeItem(at: target)
                    }
                }
                item.status = .copying(progress: 0)
                files[fileIndex] = item

                let urls = destinationsToVerify.map(\.1)
                let needsHash = (runMode != .fast && sourceHash == nil)
                let resolvedHash = try await parallelCopy(
                    from: item.sourceURL,
                    size: item.size,
                    to: urls,
                    algorithm: needsHash ? runAlgorithm : nil
                ) { [weak self] delta in
                    Task { @MainActor in self?.applyChunk(delta) }
                }
                if needsHash {
                    sourceHash = resolvedHash
                    item.sourceChecksum = resolvedHash
                }
            }
        } catch {
            let destLabel = destinationsToVerify
                .map(\.0.displayName)
                .joined(separator: ", ")
            fail(&item, at: fileIndex,
                 reason: l10n.logCopyError(destination: destLabel,
                                           message: error.localizedDescription))
            return
        }

        // Preserve macOS Finder tags / xattr if requested.
        if preserveFinderTags && !runSimulation {
            for target in allTargets {
                copyFinderTags(from: item.sourceURL, to: target)
            }
        }

        item.status = (runMode == .fast || runSimulation) ? .copied : .verifying
        files[fileIndex] = item

        // Simulation never touches the disk, so there's nothing real to
        // verify — record success straight away exactly like `.fast` mode.
        if runMode == .fast || runSimulation {
            stats.copied += 1
            if runMode != .fast { stats.verified += 1 }
            recordCompletion(of: item, checksum: item.sourceChecksum, targets: allTargets)
            if item.cameraFormat != .unknown {
                log(.success, "\(item.displayName) — OK [\(item.cameraFormat.shortBadge)]")
            } else {
                log(.success, l10n.logFileOK(item.displayName))
            }
            return
        }

        // For verified modes, `stats.copied` is incremented INSIDE the
        // verify task on success, so a verify failure isn't double-counted
        // (would otherwise increment both `copied` and `failed`).

        // Sanity guard — we should never reach a verified mode without a
        // computed source hash. If we somehow do, fail loudly rather than
        // comparing destinations against an empty string (which would make
        // every file look corrupted).
        guard let validatedHash = sourceHash else {
            fail(&item, at: fileIndex,
                 reason: l10n.logVerifyError(l10n.errMissingSourceChecksum))
            return
        }

        // 3. Verify is deferred so we can already start the next file's copy.
        //    A depth-1 pipeline (await previous before scheduling next) caps
        //    the overlap so we don't thrash the disk with parallel reads.
        //    Keyed per source root so parallel cards don't serialize each
        //    other's verifications.
        await verifyTasks[item.sourceRoot]?.value
        let capturedHash = validatedHash
        let capturedDests = destinationsToVerify
        let capturedTargets = allTargets
        let capturedFormat = item.cameraFormat
        let capturedName = item.displayName
        let capturedMode = runMode
        let capturedAlgo = runAlgorithm
        let capturedSourceURL = item.sourceURL
        verifyTasks[item.sourceRoot] = Task { [weak self] in
            guard let self else { return }
            await self.runDeferredVerification(
                fileIndex: fileIndex,
                sourceHash: capturedHash,
                sourceURL: capturedSourceURL,
                destinations: capturedDests,
                allTargets: capturedTargets,
                mode: capturedMode,
                algorithm: capturedAlgo,
                cameraFormat: capturedFormat,
                displayName: capturedName
            )
        }
    }

    /// Runs the destination verification for a single file. Invoked on the
    /// engine's MainActor via a `Task`, so the next file's copy can already
    /// be in flight while this runs.
    private func runDeferredVerification(
        fileIndex: Int,
        sourceHash: String,
        sourceURL: URL,
        destinations: [(Destination, URL)],
        allTargets: [URL],
        mode: CopyMode,
        algorithm: ChecksumAlgorithm,
        cameraFormat: CameraFormat,
        displayName: String
    ) async {
        guard fileIndex < files.count else { return }
        var item = files[fileIndex]

        // Verification reads count toward the progress budget — batched
        // so a 1 MiB-granular hash doesn't spawn one main-actor Task per
        // chunk (~100 000 hops on a 100 GB verify).
        let batcher = verifyProgressBatcher()
        defer { batcher.finish() }
        for (destination, target) in destinations {
            if cancelRequested { return }
            do {
                let destHash = try await ChecksumCalculator.checksum(for: target, algorithm: algorithm,
                                                                     onChunk: batcher.add)
                item.destinationChecksums[destination.url] = destHash
                guard destHash == sourceHash else {
                    fail(&item, at: fileIndex, reason: l10n.logChecksumMismatch(destination.displayName))
                    return
                }
                if mode == .doubleVerified {
                    let reHash = try await ChecksumCalculator.checksum(for: sourceURL, algorithm: algorithm,
                                                                       onChunk: batcher.add)
                    guard reHash == sourceHash else {
                        fail(&item, at: fileIndex, reason: l10n.logSourceUnstable)
                        return
                    }
                    log(.info, l10n.logDoubleVerifyPass(displayName))
                }
            } catch {
                fail(&item, at: fileIndex, reason: l10n.logVerifyError(error.localizedDescription))
                return
            }
        }

        item.status = .verified
        files[fileIndex] = item
        stats.copied += 1
        stats.verified += 1
        recordCompletion(of: item, checksum: sourceHash, targets: allTargets)
        if cameraFormat != .unknown {
            log(.success, "\(displayName) — OK [\(cameraFormat.shortBadge)]")
        } else {
            log(.success, l10n.logFileOK(displayName))
        }
    }

    /// Verify-only pipeline for a single file: hash the source, then hash
    /// the existing copy in every destination and compare. Never writes a
    /// byte. The copy is located by searching every plausible layout (see
    /// `existingCopyCandidates`), so it is found even when today's
    /// settings differ from the ones that produced it.
    private func processVerifyOnly(fileIndex: Int) async {
        var item = files[fileIndex]
        currentFileName = item.displayName

        if runSimulation {
            applyChunk(Int(item.size))
            item.status = .verified
            files[fileIndex] = item
            stats.verified += 1
            log(.success, l10n.logFileOK(item.displayName))
            return
        }

        item.status = .verifying
        files[fileIndex] = item
        let batcher = verifyProgressBatcher()
        defer { batcher.finish() }

        // The source read counts as the run's "data volume" (totalBytes =
        // source bytes for verify-only); the destination reads below only
        // count toward the work budget.
        let dataBatcher = dataProgressBatcher()
        defer { dataBatcher.finish() }
        let sourceHash: String
        do {
            await waitWhilePausedFromBackground()
            sourceHash = try await ChecksumCalculator.checksum(
                for: item.sourceURL, algorithm: runAlgorithm, onChunk: dataBatcher.add)
            item.sourceChecksum = sourceHash
        } catch {
            fail(&item, at: fileIndex,
                 reason: l10n.logSourceReadError(error.localizedDescription))
            return
        }

        var verifiedTargets: [URL] = []
        for destination in destinations {
            if cancelRequested { return }
            await waitWhilePausedFromBackground()
            // The copy being verified may have been made with different
            // settings than today's (another day's DIT date folder, an
            // older REEL number, structure DIT off, plain layout…), so we
            // search every plausible layout. Several candidates can exist
            // when multiple cards share the same relative paths (Sony
            // PRIVATE/M4ROOT/CLIP/C0001.MP4 on every card) — hash them in
            // order and accept the first that MATCHES, so another card's
            // identically-named file can't produce a false mismatch.
            let candidates = existingCopyCandidates(for: item, in: destination)
            guard !candidates.isEmpty else {
                let expected = destinationURL(for: item, in: destination)
                fail(&item, at: fileIndex,
                     reason: l10n.logVerifyMissing(expected.path))
                return
            }
            var matched: URL? = nil
            var firstFoundHash: String? = nil
            for candidate in candidates {
                if cancelRequested { return }
                do {
                    let destHash = try await ChecksumCalculator.checksum(
                        for: candidate, algorithm: runAlgorithm, onChunk: batcher.add)
                    if firstFoundHash == nil { firstFoundHash = destHash }
                    if destHash == sourceHash {
                        matched = candidate
                        item.destinationChecksums[destination.url] = destHash
                        break
                    }
                } catch {
                    // Unreadable candidate — try the next plausible one.
                    continue
                }
            }
            guard let matched else {
                if let found = firstFoundHash {
                    item.destinationChecksums[destination.url] = found
                }
                fail(&item, at: fileIndex,
                     reason: l10n.logChecksumMismatch(destination.displayName))
                return
            }
            verifiedTargets.append(matched)
        }

        item.status = .verified
        files[fileIndex] = item
        stats.verified += 1
        recordCompletion(of: item, checksum: sourceHash, targets: verifiedTargets)
        log(.success, l10n.logVerifyMatch(item.displayName))
    }

    // MARK: - Cascade (phase 2)

    /// Feeds every cascade destination from the FIRST primary destination
    /// — the card is no longer touched. Idempotent: a file already
    /// present on a cascade target with a matching checksum is skipped,
    /// so an interrupted cascade can simply be re-run. Verification
    /// compares each cascade copy (and the feed read itself) against the
    /// file's source checksum, so the chain of custody from the card is
    /// preserved even though the card is gone.
    /// True while phase 2 (cascade) is feeding the slow destinations —
    /// the cards themselves are already released. Surfaced to the iPhone
    /// app so the DIT knows from their pocket that the card can go.
    private(set) var isCascading = false

    private func runCascadePhase() async {
        guard let feedDestination = runPrimaries.first else { return }
        isCascading = true
        defer { isCascading = false }
        log(.info, l10n.logCascadeStart(feed: feedDestination.displayName,
                                        count: runCascades.count))
        for index in files.indices {
            if cancelRequested { return }
            var item = files[index]
            let isSecured: Bool = {
                if case .verified = item.status { return true }
                if case .copied = item.status { return true }
                return false
            }()
            guard isSecured else { continue }
            currentFileName = item.displayName

            if runSimulation {
                applyChunk(Int(item.size) * runCascades.count)
                continue
            }

            // Resolve targets, skipping copies that already match.
            var pendingTargets: [(Destination, URL)] = []
            for destination in runCascades {
                let target = destinationURL(for: item, in: destination)
                if FileManager.default.regularFileSize(atPath: target.path) == item.size {
                    if runMode == .fast {
                        applyChunk(Int(item.size))
                        continue
                    }
                    if let expected = item.sourceChecksum,
                       let existing = try? await ChecksumCalculator.checksum(
                            for: target, algorithm: runAlgorithm),
                       existing == expected {
                        item.destinationChecksums[destination.url] = existing
                        applyChunk(Int(item.size))
                        applyVerifyChunk(Int(item.size))
                        continue
                    }
                }
                pendingTargets.append((destination, target))
            }

            do {
                if !pendingTargets.isEmpty {
                    for (_, target) in pendingTargets {
                        try ensureParent(for: target)
                        if FileManager.default.fileExists(atPath: target.path) {
                            try FileManager.default.removeItem(at: target)
                        }
                    }
                    let feed = destinationURL(for: item, in: feedDestination)
                    let feedHash = try await parallelCopy(
                        from: feed,
                        size: item.size,
                        to: pendingTargets.map(\.1),
                        algorithm: runMode == .fast ? nil : runAlgorithm
                    ) { [weak self] delta in
                        Task { @MainActor in self?.applyChunk(delta) }
                    }

                    if runMode != .fast {
                        // The feed read doubles as a free re-check of the
                        // primary copy.
                        if let expected = item.sourceChecksum,
                           let feedHash, feedHash != expected {
                            fail(&item, at: index,
                                 reason: l10n.logCascadeFeedMismatch(feedDestination.displayName))
                            continue
                        }
                        let batcher = verifyProgressBatcher()
                        var mismatch = false
                        for (destination, target) in pendingTargets {
                            if cancelRequested { break }
                            let hash = try await ChecksumCalculator.checksum(
                                for: target, algorithm: runAlgorithm, onChunk: batcher.add)
                            item.destinationChecksums[destination.url] = hash
                            guard hash == (item.sourceChecksum ?? feedHash ?? hash) else {
                                fail(&item, at: index,
                                     reason: l10n.logChecksumMismatch(destination.displayName))
                                mismatch = true
                                break
                            }
                        }
                        batcher.finish()
                        if mismatch { continue }
                    }
                }
            } catch {
                let label = pendingTargets.map(\.0.displayName).joined(separator: ", ")
                fail(&item, at: index,
                     reason: l10n.logCopyError(destination: label,
                                               message: error.localizedDescription))
                continue
            }

            files[index] = item
            recordCascadeTargets(of: item)
        }
        if runOwnsSession { saveCurrentSessionInBackground() }
        log(.info, l10n.logCascadeDone(count: runCascades.count))
    }

    /// Extends a completed file's resume record with its cascade paths,
    /// so a later resume knows the cascade copies exist too.
    private func recordCascadeTargets(of item: FileItem) {
        guard runOwnsSession else { return }
        let key = Self.completionKey(root: item.sourceRoot, relativePath: item.relativePath)
        guard completedThisRun[key] != nil else { return }
        var paths = completedTargets[key] ?? []
        for destination in runCascades {
            let path = destinationURL(for: item, in: destination).path
            if !paths.contains(path) { paths.append(path) }
        }
        completedTargets[key] = paths
    }

    /// Shared batcher for verification progress: coalesces the hashing
    /// chunks and credits them to the WORK budget (not the data volume).
    private func verifyProgressBatcher() -> ProgressBatcher {
        ProgressBatcher { [weak self] delta in
            Task { @MainActor in self?.applyVerifyChunk(delta) }
        }
    }

    /// Same, but crediting DATA progress (volume + work) — used for the
    /// verify-only source read.
    private func dataProgressBatcher() -> ProgressBatcher {
        ProgressBatcher { [weak self] delta in
            Task { @MainActor in self?.applyChunk(delta) }
        }
    }

    // MARK: - Verify-only target resolution

    /// Per-destination cache of "container" folders that may hold copied
    /// files: every DIT dump folder (all dates × cams × REELs under the
    /// project's rushes tree) plus date-organized folders at the root.
    /// Built once per destination per run — scanning per file would cost
    /// three directory listings × 40 000 frames.
    private var verifyContainersCache: [URL: [URL]] = [:]

    private func verifyContainers(for destination: Destination) -> [URL] {
        if let cached = verifyContainersCache[destination.url] { return cached }
        let fm = FileManager.default
        var containers: [URL] = []

        func subdirectories(of url: URL) -> [URL] {
            (try? fm.contentsOfDirectory(at: url,
                                         includingPropertiesForKeys: [.isDirectoryKey],
                                         options: [.skipsHiddenFiles]))?
                .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
                ?? []
        }

        // DIT layout: <project>/<rushes>/<date>/<cam>/<dump>/ — walk every
        // date, camera and dump folder so an older date stamp or another
        // REEL number still gets found.
        if ditActive {
            let rushes = ditRoot(in: destination)
                .appending(path: nonEmpty(ditFolderRushes, fallback: Self.defaultDITFolderRushes))
            for dateDir in subdirectories(of: rushes) {
                for camDir in subdirectories(of: dateDir) {
                    containers.append(camDir)
                    containers.append(contentsOf: subdirectories(of: camDir))
                }
            }
        }

        // Organize-by-date layout: <destination>/<yyyy-MM-dd>/<card>/…
        let datePattern = try? NSRegularExpression(pattern: #"^\d{4}-\d{2}-\d{2}$"#)
        for child in subdirectories(of: destination.url) {
            let name = child.lastPathComponent
            if let p = datePattern,
               p.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) != nil {
                containers.append(child)
            }
        }

        verifyContainersCache[destination.url] = containers
        return containers
    }

    /// Finds the existing copies of `item` inside `destination`, whatever
    /// layout the original copy used. Tries the path today's settings
    /// would produce first, then the classic layouts, then every DIT
    /// dump / date container. Returns an ORDERED list (size-matching
    /// candidates first, capped at 5) — the caller hashes them in order
    /// and accepts the first match, so an identically-named file from
    /// another card can't cause a false mismatch.
    private func existingCopyCandidates(for item: FileItem, in destination: Destination) -> [URL] {
        let fm = FileManager.default
        var candidates: [URL] = [destinationURL(for: item, in: destination)]

        // Classic non-DIT layouts.
        candidates.append(destination.url
            .appending(path: item.sourceRootName)
            .appending(path: item.relativePath))
        candidates.append(destination.url.appending(path: item.relativePath))
        candidates.append(destination.url.appending(path: item.displayName))

        for container in verifyContainers(for: destination) {
            candidates.append(container.appending(path: item.relativePath))
            candidates.append(container.appending(path: item.displayName))
            candidates.append(container
                .appending(path: item.sourceRootName)
                .appending(path: item.relativePath))
        }

        var seen = Set<String>()
        var sizeMatches: [URL] = []
        var others: [URL] = []
        for url in candidates {
            let path = url.path
            guard seen.insert(path).inserted else { continue }
            guard let size = fm.regularFileSize(atPath: path) else { continue }
            if size == item.size {
                sizeMatches.append(url)
                // Size matches rank ahead of the rest, so five of them
                // fill the result whatever comes later.
                if sizeMatches.count == 5 { break }
            } else if others.count < 5 {
                others.append(url)
            }
        }
        return Array((sizeMatches + others).prefix(5))
    }

    private func fail(_ item: inout FileItem, at index: Int, reason: String) {
        item.status = .failed(reason: reason)
        files[index] = item
        stats.failed += 1
        log(.error, "\(item.displayName) — \(reason)")
    }

    // MARK: - Stats / speed

    /// Total I/O counter feeding the speed readout — covers both copy
    /// writes and verification reads so the meter never drops to zero
    /// during the trailing verification phase.
    private var ioBytesForSpeed: Int64 = 0

    /// Credits DATA progress (bytes written for a copy, source bytes
    /// hashed for a verify-only run) — advances both the displayed
    /// volume and the work budget.
    private func applyChunk(_ delta: Int) {
        stats.bytesProcessed += Int64(delta)
        stats.workDone += Int64(delta)
        recordSpeedSample(delta)
    }

    /// Credits WORK-only progress (verification re-reads): moves the
    /// progress bar without inflating the displayed data volume.
    private func applyVerifyChunk(_ delta: Int) {
        stats.workDone += Int64(delta)
        recordSpeedSample(delta)
    }

    private func recordSpeedSample(_ delta: Int) {
        ioBytesForSpeed += Int64(delta)
        let now = Date()
        speedSamples.append((now, ioBytesForSpeed))
        speedSamples.removeAll { now.timeIntervalSince($0.0) > 3 }
        if let first = speedSamples.first, speedSamples.count > 1 {
            let dt = now.timeIntervalSince(first.0)
            let db = ioBytesForSpeed - first.1
            stats.bytesPerSecond = dt > 0 ? Double(db) / dt : 0
        }
    }

    // MARK: - File ops

    private func enumerateFiles(in root: URL) -> [FileItem] {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        let exists = fm.fileExists(atPath: root.path, isDirectory: &isDir)
        #if DEBUG
        log(.info, "Index → \(root.path) exists:\(exists) dir:\(isDir.boolValue)")
        #endif
        guard exists else { return [] }

        // Single file case
        if !isDir.boolValue {
            if isSystemFile(name: root.lastPathComponent) { return [] }
            let size = fm.regularFileSize(atPath: root.path) ?? 0
            return [FileItem(sourceRoot: root,
                             sourceURL: root,
                             relativePath: root.lastPathComponent,
                             size: size)]
        }

        // Probe: can we list the top of `root` at all? If this fails, the
        // sandbox or filesystem is rejecting the read.
        #if DEBUG
        do {
            let top = try fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            log(.info, "Top-level entries in \(root.lastPathComponent): \(top.count)")
        } catch {
            log(.error, "contentsOfDirectory failed: \(error.localizedDescription)")
        }
        #endif

        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .isSymbolicLinkKey]
        // Note: NEVER use .skipsPackageDescendants here — macOS treats
        // some camera folders (BDMV from Panasonic Lumix AVCHD, .AVCHD,
        // .RDC from RED, etc.) as bundles, which would hide their
        // contents from the enumerator and return 0 files.
        let weakSelf = self
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles],
            errorHandler: { url, error in
                #if DEBUG
                Task { @MainActor in
                    weakSelf.log(.warning, "Enum error at \(url.lastPathComponent): \(error.localizedDescription)")
                }
                #else
                _ = weakSelf  // silence unused-capture warning in release
                _ = url; _ = error
                #endif
                return true  // continue with next item
            }
        ) else {
            #if DEBUG
            log(.error, "Enumerator creation failed for \(root.path)")
            #endif
            return []
        }

        let rootPath = root.path(percentEncoded: false)
        var result: [FileItem] = []
        var seen = 0
        var notRegular = 0
        var systemSkipped = 0
        var extSkipped = 0
        for case let url as URL in enumerator {
            seen += 1
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else {
                notRegular += 1; continue
            }
            guard values.isRegularFile == true else {
                notRegular += 1; continue
            }

            if isSystemFile(name: url.lastPathComponent) { systemSkipped += 1; continue }
            let components = url.pathComponents
            if skipSystemFiles, components.contains(where: { Self.systemFileBlocklist.contains($0) }) {
                systemSkipped += 1; continue
            }
            let ext = url.pathExtension.lowercased()
            if !whitelistedExtensions.isEmpty,
               !whitelistedExtensions.contains(ext) { extSkipped += 1; continue }
            if blacklistedExtensions.contains(ext) { extSkipped += 1; continue }

            let size = Int64(values.fileSize ?? 0)
            let abs = url.path(percentEncoded: false)
            let rel: String
            if abs.hasPrefix(rootPath) {
                rel = String(abs.dropFirst(rootPath.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            } else {
                rel = url.lastPathComponent
            }
            var item = FileItem(sourceRoot: root, sourceURL: url, relativePath: rel, size: size)
            item.cameraFormat = CameraFormatDetector.detect(at: url)
            item.clipFamily = CameraFormatDetector.clipFamily(at: url)
            result.append(item)
        }
        #if DEBUG
        log(.info, "Index ← seen:\(seen) kept:\(result.count) notRegular:\(notRegular) system:\(systemSkipped) ext:\(extSkipped)")
        #endif
        return result
    }

    private func isSystemFile(name: String) -> Bool {
        guard skipSystemFiles else { return false }
        if Self.systemFileBlocklist.contains(name) { return true }
        if name.hasPrefix("._") { return true }   // AppleDouble
        return false
    }

    private var whitelistedExtensions: Set<String> { parseExtensions(extensionWhitelist) }
    private var blacklistedExtensions: Set<String> { parseExtensions(extensionBlacklist) }

    private func parseExtensions(_ raw: String) -> Set<String> {
        let cleaned = raw
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
            .split(whereSeparator: { ", ;\t\n".contains($0) })
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return Set(cleaned)
    }

    /// Whether the DIT folder-structure feature is fully configured for
    /// this session (toggle on AND a usable project name provided).
    private var ditActive: Bool {
        ditMode && !sanitizedProjectName.isEmpty
    }

    /// Sanitised version of `projectName` — strips slashes and leading
    /// dots so the user can't escape the destination root by typing
    /// `../escape` or naming the project `.hidden`.
    private var sanitizedProjectName: String {
        Self.sanitizedComponent(projectName)
    }

    private func ditRoot(in destination: Destination) -> URL {
        // Prefer the snapshot during a run so a live edit of `projectName`
        // doesn't divert in-flight writes (and the manifest commit) to a
        // different folder than the one we created the skeleton in.
        let name = ditProjectNameSnapshot.isEmpty ? sanitizedProjectName : ditProjectNameSnapshot
        return destination.url.appending(path: name)
    }

    /// Resolves the `<cam>` folder for `item` from the snapshot taken at
    /// copy start. Reading the live `sources` array would let a late tag
    /// detection (or user picker change) reroute clips mid-copy.
    private func ditCameraFolder(for item: FileItem) -> String {
        let tag = ditTagSnapshot[item.sourceRoot] ?? .a
        return tag.folderName
    }

    // MARK: - REEL counter (per-project manifest)

    /// Persisted next-REEL counter per camera folder name. Lives at the
    /// project root so the same project keeps incrementing across app
    /// restarts and across multiple destinations.
    private struct ProjectManifest: Codable {
        /// camera folder name (e.g. "A_CAM") → highest REEL number used.
        var reelCounters: [String: Int] = [:]
    }

    private static let projectManifestName = ".misicopy-project.json"

    private func projectManifestURL(in destination: Destination) -> URL {
        ditRoot(in: destination).appending(path: Self.projectManifestName)
    }

    private func loadProjectManifest(in destination: Destination) -> ProjectManifest {
        let url = projectManifestURL(in: destination)
        guard let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(ProjectManifest.self, from: data)
        else { return ProjectManifest() }
        return manifest
    }

    private func projectManifestExists(in destination: Destination) -> Bool {
        FileManager.default.fileExists(atPath: projectManifestURL(in: destination).path)
    }

    private func saveProjectManifest(_ manifest: ProjectManifest, in destination: Destination) {
        let url = projectManifestURL(in: destination)
        let parent = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(manifest) {
            try? data.write(to: url, options: [.atomic])
        }
    }

    /// Scans `camURL` for existing `REEL_NNN/` folders and returns the
    /// highest number found, or 0 if none. Defends against a manifest
    /// that's gone missing or out of sync with the actual disk layout.
    /// Only directories are counted — a stray file named `REEL_042`
    /// won't bump the counter.
    private func existingReelMax(in camURL: URL) -> Int {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(at: camURL,
                                                        includingPropertiesForKeys: [.isDirectoryKey],
                                                        options: [.skipsHiddenFiles])
        else { return 0 }
        guard let regex = try? NSRegularExpression(pattern: #"^REEL_(\d{3,})$"#)
        else { return 0 }
        var maxN = 0
        for entry in entries {
            let isDir = (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            guard isDir else { continue }
            let name = entry.lastPathComponent
            if let m = regex.firstMatch(in: name,
                                        range: NSRange(name.startIndex..., in: name)),
               let r = Range(m.range(at: 1), in: name),
               let n = Int(name[r]) {
                maxN = max(maxN, n)
            }
        }
        return maxN
    }

    /// Allocates one `REEL_NNN/` folder per source, per camera. Numbering
    /// is per camera across the whole project (e.g. A_CAM/REEL_007 +
    /// B_CAM/REEL_002). The allocation is tentative: it's only persisted
    /// to the project manifest after the copy succeeds, so a cancelled
    /// run leaves the counter untouched.
    private func allocateReels() {
        ditReelSnapshot = [:]
        guard ditActive && reelSubfolderEnabled && !runSimulation else { return }
        var counters: [String: Int] = [:]
        let rushesSegment = nonEmpty(ditFolderRushes, fallback: Self.defaultDITFolderRushes)
        for destination in destinations {
            let manifest = loadProjectManifest(in: destination)
            for (cam, n) in manifest.reelCounters {
                counters[cam] = max(counters[cam] ?? 0, n)
            }
            // The disk scan is a safety net for when the manifest is
            // missing (first-ever dump on the project, or user deleted
            // the file). When the manifest exists we trust it — that's
            // what makes cancel-then-retry reuse the same REEL number:
            // the manifest hasn't been committed yet, so the previous
            // (partial) REEL_NNN/ folder on disk is ignored.
            guard !projectManifestExists(in: destination) else { continue }
            for source in sources {
                let camFolder = (ditTagSnapshot[source.url] ?? .a).folderName
                let camURL = ditRoot(in: destination)
                    .appending(path: rushesSegment)
                    .appending(path: ditDateStamp)
                    .appending(path: camFolder)
                let diskMax = existingReelMax(in: camURL)
                counters[camFolder] = max(counters[camFolder] ?? 0, diskMax)
            }
        }
        // Try the camera-filename convention first: `A006_…` → REEL_006,
        // `B017C001_…` → REEL_017. This keeps the destination's REEL
        // number aligned with what's literally written on the card, which
        // is the workflow DIT plateaus already enforce manually.
        //
        // Pass 1 — claim every source whose name parses to a valid REEL
        // number (>= 1, not yet taken by another source in this run).
        // Doing this in two passes ensures parsed cards always win over
        // sequential ones: if cards A and C both look like `A006`, and C
        // also has its own A009 file, C still gets REEL_009 instead of
        // being bumped to a generated sequential after A's REEL_006.
        var usedNumbers: [String: Set<Int>] = [:]
        var pendingSources: [Source] = []
        for source in sources {
            let camFolder = (ditTagSnapshot[source.url] ?? .a).folderName
            if let p = Self.detectReelNumber(in: source.url),
               p >= 1,
               !(usedNumbers[camFolder]?.contains(p) ?? false) {
                usedNumbers[camFolder, default: []].insert(p)
                counters[camFolder] = max(counters[camFolder] ?? 0, p)
                ditReelSnapshot[source.url] = String(format: "REEL_%03d", p)
            } else {
                pendingSources.append(source)
            }
        }
        // Pass 2 — fill the remaining sources sequentially, skipping any
        // number already claimed in pass 1 (so we never overwrite the
        // parsed allocations). Verify-only points at the LAST committed
        // reel instead of allocating a new one — the goal is to find the
        // folder the previous copy actually wrote, not create a new slot.
        for source in pendingSources {
            let camFolder = (ditTagSnapshot[source.url] ?? .a).folderName
            var next = (counters[camFolder] ?? 0) + (runMode == .verifyOnly ? 0 : 1)
            next = max(next, 1)
            while usedNumbers[camFolder]?.contains(next) == true {
                next += 1
            }
            counters[camFolder] = next
            usedNumbers[camFolder, default: []].insert(next)
            ditReelSnapshot[source.url] = String(format: "REEL_%03d", next)
        }
    }

    /// Wipes the REEL counter manifest from every configured destination
    /// so the next dump restarts at `REEL_001`. Intended for the "new
    /// project on this drive" workflow — the user finished a project
    /// and wants the counter back to zero without renaming the folder.
    /// Blocked mid-run: `commitReels()` at the end of the active copy
    /// would otherwise re-persist the snapshot's REEL numbers and
    /// silently undo the reset.
    func resetReelCounter() {
        guard !isRunning else { return }
        let fm = FileManager.default
        var deletedCount = 0
        for destination in destinations {
            let url = projectManifestURL(in: destination)
            if fm.fileExists(atPath: url.path) {
                try? fm.removeItem(at: url)
                deletedCount += 1
            }
        }
        ditReelSnapshot = [:]
        log(.info, l10n.logReelCounterReset(destinations: deletedCount))
    }

    /// Persists the allocated REEL numbers to every destination's project
    /// manifest. Called only after a fully successful copy so a failed
    /// run can be retried with the same REEL number.
    private func commitReels() {
        guard ditActive && reelSubfolderEnabled && !runSimulation else { return }
        var perCamMax: [String: Int] = [:]
        for source in sources {
            let camFolder = (ditTagSnapshot[source.url] ?? .a).folderName
            guard let reelName = ditReelSnapshot[source.url] else { continue }
            let digits = reelName.replacingOccurrences(of: "REEL_", with: "")
            if let n = Int(digits) {
                perCamMax[camFolder] = max(perCamMax[camFolder] ?? 0, n)
            }
        }
        for destination in destinations {
            var manifest = loadProjectManifest(in: destination)
            for (cam, n) in perCamMax {
                manifest.reelCounters[cam] = max(manifest.reelCounters[cam] ?? 0, n)
            }
            saveProjectManifest(manifest, in: destination)
        }
    }

    /// When REEL mode is active, returns the allocated `REEL_NNN/` for
    /// `item`'s source root. Falls back to the original `sourceRootName`
    /// (legacy behaviour) when REEL is off or when allocation was skipped
    /// for some reason.
    private func ditDumpFolder(for item: FileItem) -> String {
        if reelSubfolderEnabled, let reel = ditReelSnapshot[item.sourceRoot] {
            return reel
        }
        return item.sourceRootName
    }

    /// File extensions routed to `04_LUT/` when the DIT structure is on.
    /// Covers every common LUT format (Cube, 3DL, IRIDAS, ICC profiles).
    private static let lutExtensions: Set<String> = [
        "cube", "3dl", "lut", "csp", "itx", "icc", "icm", "look", "dctl"
    ]

    private func isLUTFile(_ item: FileItem) -> Bool {
        let ext = (item.relativePath as NSString).pathExtension.lowercased()
        return Self.lutExtensions.contains(ext)
    }

    private func destinationURL(for item: FileItem, in destination: Destination) -> URL {
        if ditActive {
            // LUT files bypass the per-camera/per-day routing and land
            // directly in `04_LUT/` — matches DIT plateau workflow: LUTs
            // belong with the project, not with the day's rushes.
            if isLUTFile(item) {
                let lutFolder = nonEmpty(ditFolderLUT, fallback: Self.defaultDITFolderLUT)
                let root = ditRoot(in: destination).appending(path: lutFolder)
                return root.appending(path: item.displayName)
            }
            let root = ditRoot(in: destination)
                .appending(path: nonEmpty(ditFolderRushes, fallback: Self.defaultDITFolderRushes))
                .appending(path: ditDateStamp)
                .appending(path: ditCameraFolder(for: item))
                .appending(path: ditDumpFolder(for: item))
            if preserveStructure {
                return root.appending(path: item.relativePath)
            }
            return root.appending(path: item.displayName)
        }
        var folder = destination.url
        if organizeByDate {
            // Frozen at run start (and restored on resume) so a session
            // crossing midnight — or resumed the next day — keeps writing
            // into the folder it started in.
            folder = folder.appending(path: organizeDateStamp)
        }
        folder = folder.appending(path: item.sourceRootName)

        let template = FilenameTemplate(raw: renamingTemplate)
        let useTemplate = template.isEnabled
        // The O(n) index scan only matters when a {counter} token can
        // actually be rendered — skipping it otherwise avoids an O(n²)
        // sweep on 40 000-frame sequences.
        let counter = useTemplate
            ? (files.firstIndex(where: { $0.id == item.id }) ?? 0) + 1
            : 0

        if preserveStructure {
            if useTemplate {
                let parent = (item.relativePath as NSString).deletingLastPathComponent
                let newName = template.apply(to: item, counter: counter, sessionStart: startDate ?? Date())
                if parent.isEmpty {
                    return folder.appending(path: newName)
                }
                return folder.appending(path: parent).appending(path: newName)
            }
            return folder.appending(path: item.relativePath)
        }

        let leaf = useTemplate
            ? template.apply(to: item, counter: counter, sessionStart: startDate ?? Date())
            : item.displayName
        return folder.appending(path: leaf)
    }

    private func ensureParent(for url: URL) throws {
        let parent = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
    }

    private func copyFinderTags(from src: URL, to dst: URL) {
        guard let values = try? src.resourceValues(forKeys: [.tagNamesKey]),
              let tags = values.tagNames, !tags.isEmpty else { return }
        try? (dst as NSURL).setResourceValue(tags as NSArray, forKey: .tagNamesKey)
    }

    /// Picks an I/O buffer size proportional to the file size. Tiny
    /// files don't benefit from giant buffers and benefit from staying
    /// responsive; large files saturate the I/O subsystem with 16 MB
    /// chunks, ~15-25 % faster on Thunderbolt + NVMe than the previous
    /// fixed 4 MB. `nonisolated` so detached copy tasks can read it.
    nonisolated private static func chunkSize(for fileSize: Int64) -> Int {
        if fileSize >= 100 << 20 { return 16 << 20 }  // ≥100 MB → 16 MB chunks
        if fileSize >= 10 << 20  { return 8 << 20 }   // ≥10 MB → 8 MB chunks
        return 4 << 20                                 //         → 4 MB chunks
    }

    /// On copies of large source files (≥100 MB), bypass the unified
    /// buffer cache so the system stays responsive — important when
    /// dumping 256 GB cards on a Mac the DIT is also using to play
    /// proxies / write notes.
    nonisolated private static func enableNoCacheIfLarge(_ handle: FileHandle, fileSize: Int64) {
        guard fileSize >= 100 << 20 else { return }
        _ = fcntl(handle.fileDescriptor, F_NOCACHE, 1)
    }

    /// Single-pass copy from `src` to N destinations in parallel — one
    /// source read fans out to every destination simultaneously. Returns
    /// the source hash when `algorithm` is non-nil, otherwise nil.
    private func parallelCopy(
        from src: URL,
        size fileSize: Int64,
        to targets: [URL],
        algorithm: ChecksumAlgorithm?,
        onChunk: @escaping @Sendable (Int) -> Void
    ) async throws -> String? {
        await waitWhilePausedFromBackground()
        let throttleBytesPerSecond = bandwidthLimitMBs > 0
            ? bandwidthLimitMBs * 1_000_000
            : 0
        let limiter = bandwidthLimiter
        let chunkSize = Self.chunkSize(for: fileSize)
        let destCount = max(1, targets.count)

        return try await Task.detached(priority: .userInitiated) { () -> String? in
            guard let input = try? FileHandle(forReadingFrom: src) else {
                throw ChecksumError.cannotOpenFile(src)
            }
            defer { try? input.close() }
            Self.enableNoCacheIfLarge(input, fileSize: fileSize)

            var outputs: [FileHandle] = []
            outputs.reserveCapacity(targets.count)
            for dst in targets {
                FileManager.default.createFile(atPath: dst.path, contents: nil)
                guard let h = try? FileHandle(forWritingTo: dst) else {
                    outputs.forEach { try? $0.close() }
                    throw ChecksumError.cannotOpenFile(dst)
                }
                outputs.append(h)
            }
            defer { outputs.forEach { try? $0.close() } }

            let hasher: CopyHasher? = algorithm.map { CopyHasher($0) }

            // Read one chunk INSIDE an autorelease pool. Foundation's
            // `FileHandle.read(upToCount:)` returns an autoreleased,
            // NSData-backed `Data`; in a tight detached-task loop the pool
            // never drains until the task ends, so every chunk of a big
            // file piles up in memory. A 40-80 GB copy grew MisiCopy to
            // ~44 GB RAM and macOS force-quit it. Draining per read keeps
            // only the live chunk — the returned Data escapes the pool via
            // the strong binding, so its bytes survive but the autorelease
            // +1 is released each iteration.
            func readChunk() throws -> Data {
                try autoreleasepool { try input.read(upToCount: chunkSize) ?? Data() }
            }

            var current = try readChunk()
            while !current.isEmpty {
                if Task.isCancelled { throw CancellationError() }
                let chunkToWrite = current

                // Fire the parallel fan-out write as a detached task so we
                // can prefetch the next source chunk while the destinations
                // are flushing — this is the double-buffer pipeline that
                // hides source-read latency behind destination writes.
                let writeTask = Task.detached(priority: .userInitiated) { () -> Int in
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        for output in outputs {
                            group.addTask {
                                // Same autorelease discipline on the write
                                // side — NSFileHandle.write spins up
                                // autoreleased temporaries proportional to
                                // the chunk.
                                try autoreleasepool { try output.write(contentsOf: chunkToWrite) }
                            }
                        }
                        for try await _ in group { }
                    }
                    return chunkToWrite.count
                }

                hasher?.update(data: chunkToWrite)

                // Prefetch the next chunk while the writers flush. Capture
                // a read error so we always settle the pending write first.
                let readResult: Result<Data, Error>
                do {
                    readResult = .success(try readChunk())
                } catch {
                    readResult = .failure(error)
                }

                let bytes = try await writeTask.value
                onChunk(bytes * destCount)

                // Global throttle: the shared token bucket meters the
                // aggregate source throughput across every concurrent
                // pipeline (multi-card mode), not each copy separately.
                if throttleBytesPerSecond > 0 {
                    await limiter.consume(bytes, bytesPerSecond: throttleBytesPerSecond)
                }

                switch readResult {
                case .success(let data): current = data
                case .failure(let error): throw error
                }
            }

            return hasher?.finalize()
        }.value
    }

    // MARK: - Removable volumes

    private func startObservingRemovableVolumes() {
        refreshSuggestedRemovables()
        let mount = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didMountNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            guard let self else { return }
            Task { @MainActor in self.handleVolumeMount(note: note) }
        }
        let unmount = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didUnmountNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            guard let self else { return }
            Task { @MainActor in self.handleVolumeUnmount(note: note) }
        }
        volumeObservers = [mount, unmount]
    }

    private func refreshSuggestedRemovables() {
        let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeIsRemovableKey, .volumeIsLocalKey],
            options: [.skipHiddenVolumes]
        ) ?? []
        for url in urls {
            considerVolume(url)
        }
    }

    private func handleVolumeMount(note: Notification) {
        guard let url = note.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
        // A quick remount after a transient unmount (sleep/wake, USB
        // hiccup) cancels the pending guard removal — the volume is
        // treated as the same physical card and stays protected.
        unmountClearTasks[url]?.cancel()
        unmountClearTasks.removeValue(forKey: url)
        considerVolume(url)
    }

    private func handleVolumeUnmount(note: Notification) {
        guard let url = note.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
        suggestedRemovable.removeAll { $0.url == url }
        sources.removeAll { $0.url == url }
        // Don't immediately clear the consumed-volumes guard. A real
        // physical eject leaves the volume gone for many seconds; sleep/
        // wake remounts the same card in under a second. We schedule the
        // clear in 30 s and cancel it on remount, so transient cycles
        // can't accidentally re-trigger auto-copy.
        unmountClearTasks[url]?.cancel()
        unmountClearTasks[url] = Task { @MainActor [weak self, url] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard !Task.isCancelled, let self else { return }
            self.recentlyConsumedVolumes.remove(url)
            self.unmountClearTasks.removeValue(forKey: url)
        }
    }

    private func considerVolume(_ url: URL) {
        // Skip the system root volume itself.
        if url.path == "/" { return }
        // Hard-skip any path under the system tree — guards against the
        // APFS `Data` volume mounting under `/System/Volumes/Data` and
        // similar OS-internal mounts that don't always report
        // `volumeIsRootFileSystem = true`.
        if url.path.hasPrefix("/System/") || url.path.hasPrefix("/private/") { return }
        let keys: Set<URLResourceKey> = [.volumeIsRemovableKey, .volumeIsEjectableKey,
                                         .volumeIsInternalKey, .volumeIsRootFileSystemKey]
        guard let values = try? url.resourceValues(forKeys: keys) else { return }
        // Hard-skip the boot volume — that's the only one we must never touch.
        if values.volumeIsRootFileSystem == true { return }
        if isTimeMachineVolume(url) { return }
        let isRemovable = values.volumeIsRemovable == true
        let isEjectable = values.volumeIsEjectable == true || isRemovable
        let isCameraLayout = Self.looksLikeCameraVolume(url)
        // Accept any volume that's removable or ejectable — built-in SD card
        // readers report `volumeIsInternal == true` even though the card
        // itself is removable, so we DO NOT filter on `isInternal` anymore.
        // ALSO accept volumes whose root layout looks like a camera card
        // (ARRI Codex, Sony XDCAM, etc. — drivers that don't expose the
        // removable/ejectable flags but clearly contain footage).
        guard isEjectable || isCameraLayout else { return }
        if sources.contains(where: { $0.url == url }) { return }
        // Volumes already consumed by a successful copy in this session
        // never re-trigger watch-mode. Sleep/wake or transient remount
        // events would otherwise silently re-copy the same card.
        if recentlyConsumedVolumes.contains(url) { return }
        // Camera-only volumes (DCIM, Clips, Footage, …) that aren't
        // explicitly ejectable are very likely archive drives the user
        // wants to KEEP plugged in. Don't auto-add them via watch mode —
        // only via the manual "card detected" suggestion banner.
        let isCameraOnlyNotEjectable = isCameraLayout && !isEjectable

        // Card memory: annotate with previous offload info when available,
        // but do NOT block the normal auto-add / suggestion flow — the
        // early-return that was here caused a regression where no source
        // ever appeared (watch-mode cards were silently swallowed).
        let previous = lastSuccessfulOffload(volumePath: url.path)
        if let previous {
            log(.info, l10n.logKnownCardDetected(url.lastPathComponent,
                                                 when: l10n.formattedDateTime(previous.date)))
        }

        // Watch-folder mode: silently auto-add (and optionally auto-start).
        if watchAutoAddSource && !isCameraOnlyNotEjectable {
            addSource(url)
            log(.info, l10n.logWatchAutoAdded(url.lastPathComponent))
            if watchAutoStart && !destinations.isEmpty && !isRunning && !isFinalizing {
                // Never auto-start a VERIFICATION on a freshly inserted
                // card — nothing has been copied yet, every file would
                // fail as "missing" and fire failure notifications.
                if mode == .verifyOnly {
                    log(.warning, l10n.logWatchAutoStartSkippedVerify)
                } else {
                    log(.info, l10n.logWatchAutoStarted)
                    start()
                }
            }
            return
        }

        if suggestedRemovable.contains(where: { $0.url == url }) { return }
        // Pass previousOffload so the suggestion banner can show the
        // "already offloaded on…" hint without blocking normal usage.
        suggestedRemovable.append(Source(url: url, isEjectable: true,
                                         isRemovableMedia: isRemovable,
                                         previousOffload: previous))
    }

    /// Most recent successful REAL offload of the volume at `volumePath`,
    /// from the session history (newest first). Matches both the volume
    /// itself and any source folder inside it. Verify-only sessions and
    /// simulations don't count — nothing was copied.
    private func lastSuccessfulOffload(volumePath: String) -> PreviousOffload? {
        let normalized = volumePath.hasSuffix("/") ? String(volumePath.dropLast()) : volumePath
        guard let record = history.records.first(where: { record in
            !record.simulation && record.didSucceed && record.mode != .verifyOnly
                && record.sourcePaths.contains { path in
                    let p = path.hasSuffix("/") ? String(path.dropLast()) : path
                    return p == normalized || p.hasPrefix(normalized + "/")
                }
        }) else { return nil }
        return PreviousOffload(date: record.startDate,
                               files: record.verified,
                               bytes: record.totalBytes)
    }

    /// True when the root of `url` contains directory markers typical of
    /// camera capture media. Lets us catch volumes that pro drivers
    /// (ARRI Codex, Codex Vault, Codex Capture Drive…) mount without
    /// proper removable/ejectable URL resource flags.
    private static func looksLikeCameraVolume(_ url: URL) -> Bool {
        let markers = [
            "Codex", "CODEX",          // Codex Capture Drive
            "Clips", "OCN",             // ARRI ALEXA / Mini / 65
            "DCIM",                      // SD-style cameras (LUMIX, GoPro, mirrorless)
            "PRIVATE",                   // Sony / Panasonic AVCHD root
            "XDROOT", "M4ROOT", "AVCHD", // Sony XDCAM / Panasonic
            "CONTENTS",                  // RED Mag (some firmwares)
            "Footage"                    // Codex Vault
        ]
        let fm = FileManager.default
        for marker in markers {
            let candidate = url.appending(path: marker, directoryHint: .isDirectory)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: candidate.path, isDirectory: &isDir), isDir.boolValue {
                return true
            }
        }
        return false
    }

    private func isTimeMachineVolume(_ url: URL) -> Bool {
        let name = url.lastPathComponent.lowercased()
        if name.contains("time machine") || name.contains("timemachine") { return true }
        if url.pathExtension == "sparsebundle" || url.pathExtension == "backupbundle" { return true }
        // Check for Time Machine root marker file
        let marker = url.appending(path: ".com.apple.timemachine.donotpresent")
        if FileManager.default.fileExists(atPath: marker.path) { return true }
        let backupDB = url.appending(path: "Backups.backupdb")
        if FileManager.default.fileExists(atPath: backupDB.path) { return true }
        return false
    }

    private func ejectEjectableSources(didSucceed: Bool) async {
        // Let the OS flush pending writes / release caches before eject.
        try? await Task.sleep(nanoseconds: 700_000_000)

        let workspace = NSWorkspace.shared
        var attempts = 0
        var processedVolumes: Set<URL> = []
        for source in sources {
            // Always re-query at eject time — don't trust the cached value
            // (the source may have been added before this code path existed).
            let keys: Set<URLResourceKey> = [.volumeURLKey, .volumeIsRemovableKey,
                                             .volumeIsEjectableKey, .volumeIsInternalKey,
                                             .volumeIsLocalKey]
            let values = try? source.url.resourceValues(forKeys: keys)
            let volumeURL = values?.volume ?? source.volumeURL
            let isInternal = values?.volumeIsInternal == true
            let isRemovable = values?.volumeIsRemovable == true
            let isEjectable = values?.volumeIsEjectable == true

            // Diagnostic line (always logged so the user sees what macOS reports).
            log(.info, l10n.logVolumeProbe(
                name: (volumeURL ?? source.url).lastPathComponent,
                internal: isInternal,
                removable: isRemovable,
                ejectable: isEjectable
            ))

            // Criterion: removable OR ejectable OR looks-like-camera → candidate.
            // Built-in SD card readers report `volumeIsInternal == true` because
            // the reader sits on the motherboard but the card itself is
            // removable. ARRI Codex Capture Drives mount via a third-party
            // driver that doesn't always expose the ejectable flag, so we also
            // fall back to a content-based heuristic. The OS will refuse the
            // eject if it's truly impossible.
            guard let volumeURL,
                  (isEjectable || isRemovable || Self.looksLikeCameraVolume(volumeURL))
            else { continue }
            _ = isInternal // kept for the diagnostic log above
            if processedVolumes.contains(volumeURL) { continue }
            processedVolumes.insert(volumeURL)

            if !didSucceed {
                log(.warning, l10n.logEjectSkippedErrors(volumeURL.lastPathComponent))
                continue
            }
            attempts += 1
            log(.info, l10n.logEjectAttempt(volumeURL.lastPathComponent))
            // `unmountAndEjectDevice` is synchronous and can block for
            // several seconds on volumes with vendor drivers (ARRI Codex,
            // Sony XDCAM…). Run it off the main actor so the UI stays
            // responsive while the OS works through the unmount.
            let urlCopy = volumeURL
            let result: Result<Void, Error> = await Task.detached {
                do {
                    try NSWorkspace.shared.unmountAndEjectDevice(at: urlCopy)
                    return .success(())
                } catch {
                    return .failure(error)
                }
            }.value
            switch result {
            case .success:
                log(.success, l10n.logEjected(volumeURL.lastPathComponent))
            case .failure(let error):
                let ns = error as NSError
                let detail = "\(error.localizedDescription) [\(ns.domain) #\(ns.code)]"
                log(.warning, l10n.logEjectFailed(volumeURL.lastPathComponent, detail))
            }
        }
        if attempts == 0 && didSucceed {
            log(.info, l10n.logNoRemovableSource)
        }
    }

    // MARK: - Notifications

    private func requestNotificationAuthorizationIfNeeded() {
        guard notifyOnFinish else { return }
        // Always re-check: on macOS the system never re-prompts after a
        // user decision, so calling this every time is cheap and reflects
        // any change made in System Settings → Notifications.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            Task { @MainActor in self?.notificationsAuthorized = granted }
        }
    }

    private func sendWebhooks(success: Bool) async {
        let message = success
            ? l10n.notifSuccess(stats.verified, stats.found)
            : l10n.notifFailure(stats.failed)
        let summary = "MisiCopy — \(message)"
        async let slack: Void = WebhookNotifier.postSlack(url: slackWebhookURL, message: summary)
        async let generic: Void = WebhookNotifier.postGeneric(
            url: genericWebhookURL, message: summary,
            stats: stats, success: success)
        _ = await (slack, generic)
        if !slackWebhookURL.isEmpty || !genericWebhookURL.isEmpty {
            log(.info, l10n.logWebhookSent)
        }
    }

    private func sendCompletionNotification(success: Bool) {
        guard notifyOnFinish else { return }
        let content = UNMutableNotificationContent()
        content.title = "MisiCopy"
        if success {
            content.body = l10n.notifSuccess(stats.verified, stats.found)
            content.sound = .default
        } else {
            content.body = l10n.notifFailure(stats.failed)
            content.sound = .defaultCritical
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Logging

    func log(_ level: LogLevel, _ message: String) {
        logs.append(LogEntry(date: Date(), level: level, message: message))
    }

    // MARK: - Export

    func exportJournal() -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        var text = l10n.journalHeaderTitle + "\n"
        text += l10n.journalHeaderExportedAt(iso.string(from: Date())) + "\n"
        text += l10n.journalHeaderEntries(logs.count) + "\n"
        text += String(repeating: "─", count: 70) + "\n"
        for entry in logs {
            let level: String
            switch entry.level {
            case .info: level = "INFO   "
            case .success: level = "OK     "
            case .warning: level = "WARN   "
            case .error: level = "ERROR  "
            }
            text += "[\(iso.string(from: entry.date))] \(level) \(entry.message)\n"
        }
        return text
    }

    func exportMHL() -> String {
        MHLExporter.makeXML(
            source: sources.first?.url,
            destinations: destinations,
            files: files,
            algorithm: algorithm,
            startDate: startDate ?? Date(),
            endDate: endDate ?? Date()
        )
    }

    func exportASCMHL() -> String {
        ASCMHLExporter.makeXML(
            source: sources.first?.url,
            destinations: destinations,
            files: files,
            algorithm: algorithm,
            startDate: startDate ?? Date(),
            endDate: endDate ?? Date()
        )
    }

    // MARK: - Formatting

    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Free bytes on the volume backing `url`, preferring the
    /// "important usage" figure Apple recommends for "will it fit?"
    /// checks, falling back to the raw capacity for exFAT/network
    /// volumes that report 0 there. Returns -1 when unknowable (never
    /// block a copy on a missing metric).
    nonisolated static func freeSpace(at url: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.volumeAvailableCapacityForImportantUsageKey,
                                         .volumeAvailableCapacityKey]
        guard let values = try? url.resourceValues(forKeys: keys) else { return -1 }
        let preferred = values.volumeAvailableCapacityForImportantUsage ?? 0
        let raw = Int64(values.volumeAvailableCapacity ?? 0)
        let free = preferred > 0 ? preferred : raw
        return free > 0 ? free : -1
    }

    func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d h %02d min", h, m) }
        if m > 0 { return String(format: "%d min %02d s", m, s) }
        return "\(s) s"
    }

    func formatRate(_ bytesPerSecond: Double) -> String {
        guard bytesPerSecond > 0 else { return "—" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useMB, .useGB, .useKB]
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }
}
