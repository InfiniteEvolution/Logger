//  Logger.swift
//  Logger
//
//  Central diagnostic telemetry engine for the entire platform.
import Foundation
import CoreML

/// Primary actor for centralized diagnostic telemetry and neural governance.
///
/// Logger provides structured recording of system events, task lifecycles,
/// and autonomic regulation signals. It implements the `LoggerProxy` protocol for DI.
///
/// - Responsibility: Manages in-memory diagnostic telemetry and neural sampling.
/// - Concurrency: Thread-safe via Actor isolation; @unchecked Sendable avoided where possible.
public final actor Logger: Sendable {
    /// Context for logger's own internal operations.
    private let log = LogContext("LOLN")
    /// Posted when autonomic system status changes.
    public static let autonomicAlertNotification = Notification.Name("autonomicAlertNotification")

    private let brain: LoggerNeuralBrain
    private var lastBrainAccess = Date.distantPast
    private nonisolated let storage: LogStorage?

    /// Returns the URL to the persistent log file managed by this logger.
    public nonisolated var storageURL: URL? { storage?.fileURL }

    private let maxEntries = 500
    private var contextStores: [Context: [Entry]] = [:]
    private var lastLogTimes: [Context: Date] = [:]
    private var sequenceCounts: [Context: Int] = [:]
    private var taskRecords: [UUID: LogTask.Record] = [:]
    private let analyzer: LogAnalyzer

    /// Recent entries for a given context or all contexts.
    ///
    /// This method retrieves structured log entries from the in-memory cache.
    /// It is useful for displaying recent system activity in a UI or generating reports.
    ///
    /// - Parameter context: The specific context to filter by (optional).
    /// - Returns: An array of entries sorted by their occurrence time.
    public func recentEntries(for context: Context? = nil) async -> [Entry] {
        if let context = context {
            return contextStores[context] ?? []
        }
        return contextStores.values.flatMap { $0 }.sorted { $0.timestamp < $1.timestamp }
    }

    /// Initializes a new Logger with the provided governance dependencies.
    ///
    /// - Parameters:
    ///   - governorBrain: Optional neural brain for governance decisions.
    ///   - batcher: Optional batcher for resource management.
    ///   - registry: Optional registry for neural resources.
    public init(
        governorBrain: GovernorNeuralBrain? = nil,
        batcher: ResourceBatcher? = nil,
        registry: NeuralResourceRegistry? = nil,
        storage: LogStorage? = LogStorage()
    ) {
        self.storage = storage
        self.brain = LoggerNeuralBrain(
            governorBrain: governorBrain,
            batcher: batcher,
            registry: registry
        )
        self.analyzer = LogAnalyzer(
            governorBrain: governorBrain,
            batcher: batcher,
            registry: registry
        )
    }

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

    /// Isolated method that performs neural sampling and stores the entry.
    private func performLog(_ message: String, context: Context, level: Int, isError: Bool, timestamp: Date, correlationId: String?) async {
        let lastTime = lastLogTimes[context] ?? timestamp
        let deltaTime = timestamp.timeIntervalSince(lastTime)
        let seqID = sequenceCounts[context, default: 0]
        sequenceCounts[context] = seqID + 1
        lastLogTimes[context] = timestamp

        do {
            let input = try MLMultiArray(shape: [5], dataType: .double)
            input[0] = NSNumber(value: Double(level))
            input[1] = NSNumber(value: isError ? 1.0 : 0.0)
            input[2] = NSNumber(value: deltaTime)
            input[3] = NSNumber(value: context.id)
            input[4] = NSNumber(value: Double(seqID))

            if await brain.shouldLog(features: input) {
                let entry = Entry(timestamp: timestamp, level: level, context: context, message: message, isError: isError, correlationId: correlationId)
                print(entry.consoleLine)

                if let storage = storage {
                    await storage.store(entry)
                }

                var store = contextStores[context, default: []]
                store.append(entry)
                if store.count > maxEntries { store.removeFirst() }
                contextStores[context] = store
            }
        } catch {
            log.error("performLog failed: \(error)")
        }
    }

    /// Summarizes the current logs for a specific context.
    ///
    /// Generates a human-interpretable string containing log counts,
    /// error rates, task performance metrics, and neural insights.
    ///
    /// - Parameter context: The context to analyze.
    /// - Returns: A multi-line summary string.
    public func summarize(for context: Context) async -> String {
        let logs = contextStores[context] ?? []
        let tasks = taskRecords.values.filter { $0.context == context }
        guard !logs.isEmpty else { return "No logs for \(context.label)" }

        let errors = logs.filter { $0.isError }.count
        let warnings = logs.filter { $0.level == 2 }.count
        let completedTasks = tasks.filter { $0.end != nil }

        let successCount = completedTasks.filter { if case .some(.success) = $0.outcome { return true }; return false }.count
        let avgDuration = completedTasks.isEmpty ? 0 : (completedTasks.compactMap { $0.duration }.reduce(0, +) / Double(completedTasks.count))
        let successRate = completedTasks.isEmpty ? 0 : (Double(successCount) / Double(completedTasks.count)) * 100

        var summary = "Context: \(context.label) | Logs: \(logs.count) | Errors: \(errors) | Warnings: \(warnings)\n"
        summary += "Tasks: \(completedTasks.count) | Success Rate: \(String(format: "%.1f%%", successRate)) | Avg Duration: \(String(format: "%.3fs", avgDuration))"

        let insights = await analyzer.analyze(tasks: completedTasks)
        for insight in insights {
            let label = insight.severity == 2 ? "[CRITICAL]" : "[WARN]"
            summary += "\n\(label) \(insight.metric): \(insight.value)"
        }
        return summary
    }

    /// Records the start of a task and checks for autonomic regulation.
    ///
    /// This method registers a new logical task and evaluates past performance
    /// in the same context to determine if the task should be throttled or interrupted.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for this task execution.
    ///   - name: The human-readable name of the task.
    ///   - context: The logging context associated with the task.
    ///   - timestamp: Task start time.
    /// - Throws: `AutonomicError.interrupted` if neural governance rejects the task.
    public func startTask(id: UUID, name: String, context: Context, timestamp: Date) async throws {
        let records = taskRecords.values.filter { $0.context == context }
        let insights = await analyzer.analyze(tasks: Array(records.suffix(50)))

        for insight in insights {
            switch insight.action {
            case .interrupt:
                let alert = AutonomicAlert(context: context, action: .interrupt, metric: insight.metric, value: insight.value)
                NotificationCenter.default.post(name: Self.autonomicAlertNotification, object: nil, userInfo: ["alert": alert])
                throw AutonomicError.interrupted("System Critical: \(insight.metric) is \(insight.value)")
            case .throttle(let throttleDuration):
                try? await Task.sleep(nanoseconds: UInt64(throttleDuration * 1_000_000_000))
            case .none: break
            }
        }
        taskRecords[id] = LogTask.Record(name: name, context: context, start: timestamp)
    }

    /// Records the end of a task with outcome and duration.
    ///
    /// Updates an existing task record with its final result and timing information.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the task being completed.
    ///   - outcome: The final result (e.g. success, failure).
    ///   - duration: Total execution time in seconds.
    public func endTask(id: UUID, outcome: LogTask.Outcome, duration: TimeInterval) {
        if var record = taskRecords[id] {
            record.end = Date(); record.outcome = outcome; record.duration = duration
            taskRecords[id] = record
        }
    }

    /// Flushes all buffered diagnostics to persistent storage.
    ///
    /// Handover method to ensure all queued logs are written to disk.
    /// This should be called before system exit to ensure zero telemetry loss.
    public func flush() async {
        await storage?.flush()
    }
}
