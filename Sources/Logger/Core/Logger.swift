//  Logger.swift
//  Logger
//
//  Central diagnostic telemetry engine for the entire platform.
import Foundation

/// Primary actor for centralized diagnostic telemetry.
///
/// Logger provides structured recording of system events and task lifecycles. 
/// It implements the `LoggerProxy` protocol for DI.
///
/// - Responsibility: Manages in-memory diagnostic telemetry and log persistence.
/// - Concurrency: Thread-safe via Actor isolation.
public final actor Logger: Sendable {
    /// Context for logger's own internal operations.
    private let log = LogContext("LOLN")
    /// Posted when autonomic system status changes.
    public static let autonomicAlertNotification = Notification.Name("autonomicAlertNotification")
    
    internal nonisolated let storage: LogStorage?

    /// Returns the URL to the persistent log file managed by this logger.
    public nonisolated var storageURL: URL? { storage?.fileURL }

    internal let maxEntries = 500
    internal var contextStores: [Context: [Entry]] = [:]
    internal var lastLogTimes: [Context: Date] = [:]
    internal var sequenceCounts: [Context: Int] = [:]
    internal var taskRecords: [UUID: LogTask.Record] = [:]

    /// Initializes a new Logger with the provided storage dependency.
    ///
    /// - Parameters:
    ///   - storage: Optional persistent storage engine. Defaults to a standard shared URL.
    public init(
        storage: LogStorage? = LogStorage()
    ) {
        self.storage = storage
    }

    /// Flushes all buffered diagnostics to persistent storage.
    ///
    /// Handover method to ensure all queued logs are written to disk.
    /// This should be called before system exit to ensure zero telemetry loss.
    public func flush() async {
        await storage?.flush()
    }
}
