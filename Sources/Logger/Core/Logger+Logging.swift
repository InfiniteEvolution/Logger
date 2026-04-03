//  Logger+Logging.swift
//  Logger
//
//  Telemetry execution and persistent recording logic.
import Foundation

extension Logger {
    /// Primary nonisolated method for recording a message.
    ///
    /// Regular diagnostic messages should be recorded through this method.
    /// It spawns a background task to avoid blocking the calling thread,
    /// ensuring O(1) performance for the caller.
    ///
    /// - Parameters:
    ///   - message: The human-readable text to log.
    ///   - context: The system context (defaults to `.general`).
    ///   - level: Verbosity level (1=Info, 2=Warning, 3=Error).
    ///   - isError: Explicit error flag (defaults to `false`).
    ///   - correlationId: Optional UUID string to group related log chains.
    nonisolated public func log(_ message: String, context: Context = .general, level: Int = 1, isError: Bool = false, correlationId: String? = nil) {
        let now = Date()
        Task(priority: .utility) {
            await self.performLog(message, context: context, level: level, isError: isError, timestamp: now, correlationId: correlationId)
        }
    }

    /// Isolated method that records the diagnostic entry.
    ///
    /// - Parameters:
    ///   - message: The human-readable text to log.
    ///   - context: The system context.
    ///   - level: Verbosity level.
    ///   - isError: Error flag.
    ///   - timestamp: Exact time of occurrence.
    ///   - correlationId: Optional tracing identifier.
    private func performLog(_ message: String, context: Context, level: Int, isError: Bool, timestamp: Date, correlationId: String?) async {
        sequenceCounts[context, default: 0] += 1
        lastLogTimes[context] = timestamp

        let entry = Entry(timestamp: timestamp, level: level, context: context, message: message, isError: isError, correlationId: correlationId)
        
        // Output to console for developer visibility
        print(entry.consoleLine)

        if let storage = storage {
            await storage.store(entry)
        }

        var store = contextStores[context, default: []]
        store.append(entry)
        if store.count > maxEntries { store.removeFirst() }
        contextStores[context] = store
    }
}
