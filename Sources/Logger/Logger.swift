
import Foundation
import CoreML

public actor Logger: Sendable {
    private let log = LogContext("LOLN")
    public static let shared = Logger()
    
    // Autonomic Errors
    public enum AutonomicError: Error {
        case interrupted(String)
    }
    
    // Autonomic Events
    public static let autonomicAlertNotification = Notification.Name("autonomicAlertNotification")
    public struct AutonomicAlert: Sendable {
        public let context: Context
        public let action: LogAnalyzer.AutonomicAction
        public let metric: String
        public let value: String
    }
    
    private let brain = LoggerNeuralBrain()
    private var lastBrainAccess = Date.distantPast
    
    // --- Multi-Context Architecture ---
    public struct Context: Hashable, Sendable, CustomStringConvertible {
        public let label: String
        
        public init(_ label: String) {
            self.label = label.uppercased()
        }
        
        public var description: String { label }
        
        public var rawValue: String { label }
        
        // Generic ID generation for Neural Brain
        // We no longer rely on hardcoded IDs like 1.0, 2.0.
        // Instead, we use a stable hash mapped to a 0.0-10.0 range.
        var id: Double {
            let hash = abs(label.hashValue)
            return Double(hash % 100) / 10.0
        }
        
        // Standard Contexts (Optional Helpers, not Hardcoded Logic)
        public static let general = Context("GENL")
    }
    
    public struct Entry: Identifiable, Sendable {
        public let id = UUID()
        public let timestamp: Date
        public let level: Int
        public let context: Context
        public let message: String
        public let isError: Bool
        public let correlationId: String?
        
        public var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter.string(from: timestamp)
        }
    }
    
    private let maxEntries = 500
    private var contextStores: [Context: [Entry]] = [:]
    private var lastLogTimes: [Context: Date] = [:]
    private var sequenceCounts: [Context: Int] = [:]
    private var taskRecords: [UUID: LogTask.Record] = [:]
    private let analyzer = LogAnalyzer()

    public func recentEntries(for context: Context? = nil) async -> [Entry] {
        if let context = context {
            return contextStores[context] ?? []
        }
        return contextStores.values.flatMap { $0 }.sorted { $0.timestamp < $1.timestamp }
    }

    init() { }

    nonisolated public func log(_ message: String, context: Context = .general, level: Int = 1, isError: Bool = false, correlationId: String? = nil) {
        let now = Date()
        Task {
            await self.performLog(message, context: context, level: level, isError: isError, timestamp: now, correlationId: correlationId)
        }
    }
    
    private func performLog(_ message: String, context: Context, level: Int, isError: Bool, timestamp: Date, correlationId: String?) async {
        let lastTime = lastLogTimes[context] ?? timestamp
        let deltaTime = timestamp.timeIntervalSince(lastTime)
        let seqID = sequenceCounts[context, default: 0]
        sequenceCounts[context] = seqID + 1
        lastLogTimes[context] = timestamp
        
        // Neural Governance: 5D Feature Extraction
        do {
            let input = try MLMultiArray(shape: [5], dataType: .double)
            input[0] = NSNumber(value: Double(level))
            input[1] = NSNumber(value: isError ? 1.0 : 0.0)
            input[2] = NSNumber(value: deltaTime)
            input[3] = NSNumber(value: context.id)
            input[4] = NSNumber(value: Double(seqID))
            
            if await brain.shouldLog(features: input) {
                let entry = Entry(timestamp: timestamp, level: level, context: context, message: message, isError: isError, correlationId: correlationId)
                
                let corrTag = correlationId.map { " [\($0)]" } ?? ""
                print("[\(entry.formattedTime)] [\(context.label)]\(corrTag) \(message)")
                
                var store = contextStores[context, default: []]
                store.append(entry)
                if store.count > maxEntries {
                    store.removeFirst()
                }
                contextStores[context] = store
            }
        } catch let logError {
            log.error("performLog failed: \(logError)")
            print("[NEURAL FAILURE] \(message)")
        }
    }
    
    public func summarize(for context: Context) async -> String {
        let logs = contextStores[context] ?? []
        let tasks = taskRecords.values.filter { $0.context == context }
        
        guard !logs.isEmpty else {
            log.warning("summarize: !logs.isEmpty")
            return "No logs for \(context.label)"
        }
        
        let errors = logs.filter { $0.isError }.count
        let warnings = logs.filter { $0.level == 2 }.count
        
        let completedTasks = tasks.filter { $0.end != nil }
        let successCount = completedTasks.filter { 
            if case .some(.success) = $0.outcome { return true }
            return false
        }.count
        
        let avgDuration = completedTasks.isEmpty ? 0 : completedTasks.compactMap { $0.duration }.reduce(0, +) / Double(completedTasks.count)
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

    // --- Task Lifecycle (Internal) ---
    
    internal func startTask(id: UUID, name: String, context: Context, timestamp: Date) async throws {
        // Autonomic Regulation Check
        let records = taskRecords.values.filter { $0.context == context }
        let insights = await analyzer.analyze(tasks: Array(records.suffix(50)))
        
        // 2. Enforce Actions
        for insight in insights {
            switch insight.action {
            case .interrupt:
                // Circuit Breaker: Stop new tasks
                print("[AUTONOMIC] Interrupting \(name) due to \(insight.metric)")
                
                // Broadcast Alert for Immune Response
                let alert = AutonomicAlert(context: context, action: .interrupt, metric: insight.metric, value: insight.value)
                NotificationCenter.default.post(name: Self.autonomicAlertNotification, object: nil, userInfo: ["alert": alert])
                
                throw AutonomicError.interrupted("System Critical: \(insight.metric) is \(insight.value)")
                
            case .throttle(let duration):
                // Throttle: Slow down
                print("[AUTONOMIC] Throttling \(name) for \(duration)s due to \(insight.metric)")
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000)) // Asynchronous backpressure
                
            case .none:
                break
            }
        }
        
        taskRecords[id] = LogTask.Record(name: name, context: context, start: timestamp)
    }
    
    internal func endTask(id: UUID, outcome: LogTask.Outcome, duration: TimeInterval) {
        if var record = taskRecords[id] {
            record.end = Date()
            record.outcome = outcome
            record.duration = duration
            taskRecords[id] = record
        }
    }
    
    // --- Data Driven & Self Healing ---
    
    /// Triggered by events (e.g. app backgrounding) to reflect on past decisions.
    /// In a real system, 'target' would come from explicit user feedback or crash reports.
    /// Triggered by events (e.g. app backgrounding) to reflect on past decisions.
    /// In a real system, 'target' would come from explicit user feedback or crash reports.
    public func learn(from experience: [[Double]], targets: [Double]) {
        guard let modelURL = Bundle.module.url(forResource: "LoggerBrain", withExtension: "mlmodelc") else {
            log.warning("learn: modelURL is nil/unavailable")
            return
        }
        
        var trainingData: [MLFeatureProvider] = []
        for (i, features) in experience.enumerated() {
            guard i < targets.count else { break }
            do {
                // Feature Vector [5]
                let input = try MLMultiArray(shape: [5], dataType: .double)
                for (idx, val) in features.enumerated() {
                    guard idx < 5 else { break }
                    input[idx] = NSNumber(value: val)
                }
                
                let target = try MLMultiArray(shape: [1], dataType: .double)
                target[0] = NSNumber(value: targets[i])
                
                let dataPoint = try MLDictionaryFeatureProvider(dictionary: [
                    "log_features": MLFeatureValue(multiArray: input),
                    "should_log_true": MLFeatureValue(multiArray: target)
                ])
                trainingData.append(dataPoint)
            } catch {
                log.error("learn: sample skipped")
                continue
            }
        }
        
        let batchProvider = MLArrayBatchProvider(array: trainingData)
        
        // Self-Healing Task
        // "Event Driven" -> We could schedule this via BGTaskScheduler
        let task = try? MLUpdateTask(forModelAt: modelURL, trainingData: batchProvider, configuration: nil, completionHandler: { context in
             // Save the cured brain
             let updatedModel = context.model
             try? updatedModel.write(to: modelURL) // Overwrite self (Autopoiesis)
             print("[NEURAL HEALING] LoggerBrain updated weights. Loss: \(context.metrics[.lossValue] ?? 0)")
        })
        task?.resume()
    }
}

/// Context-aware wrapper for Neural Logger
public struct LogContext: Sendable {
    public let context: Logger.Context
    public let correlationId: String?
    
    public init(_ context: Logger.Context, correlationId: String? = nil) {
        self.context = context
        self.correlationId = correlationId
    }
    
    public init(_ label: String, correlationId: String? = nil) {
        // Blind Logger: Heuristics Removed.
        // We simply create a context from the label provided.
        // The Logger does not know what this label implies.
        self.context = Logger.Context(label)
        self.correlationId = correlationId
    }
    
    public func with(correlationId: String) -> LogContext {
        return LogContext(self.context, correlationId: correlationId)
    }
    
    public func debug(_ message: String) {
        Logger.shared.log("[DEBUG] \(message)", context: context, level: 0, correlationId: correlationId)
    }
    
    public func info(_ message: String) {
        Logger.shared.log("#Info \(message)", context: context, level: 1, correlationId: correlationId)
    }
    
    public func warning(_ message: String) {
        Logger.shared.log("#Warning \(message)", context: context, level: 2, correlationId: correlationId)
    }
    
    public func error(_ message: String) {
        Logger.shared.log("#Error \(message)", context: context, level: 3, isError: true, correlationId: correlationId)
    }
    
    public func fault(_ message: String) {
        Logger.shared.log("#Error \(message)", context: context, level: 4, isError: true, correlationId: correlationId)
    }
    
    public func expected(_ message: String) {
        Logger.shared.log("#Expected \(message)", context: context, level: 1, correlationId: correlationId)
    }
    
    public func summarize() async -> String {
        await Logger.shared.summarize(for: context)
    }
    
    public func deinited() {
        debug("Deinitialized")
    }
    
    public func inited() {
        debug("Initialized")
    }
    
    public func critical(_ message: String) {
        Logger.shared.log("#Error (CRITICAL) \(message)", context: context, level: 5, isError: true, correlationId: correlationId)
    }
}

/// Task-level log aggregator with semantic outcomes
public struct LogTask: Sendable {
    public enum Outcome: Sendable {
        case success
        case failure(String)
        case partial(String)
        case interrupted
    }
    
    private let context: Logger.Context
    private let name: String
    private let start = Date()
    private let id = UUID()
    
    public struct Record: Sendable {
        public let name: String
        public let context: Logger.Context
        public let start: Date
        public var end: Date?
        public var outcome: Outcome?
        public var duration: TimeInterval?
    }

    public init(_ name: String, in context: Logger.Context) {
        self.name = name
        self.context = context
        let taskId = self.id
        let startTime = self.start
        Task {
            do {
                try await Logger.shared.startTask(id: taskId, name: name, context: context, timestamp: startTime)
                Logger.shared.log(">> Task [\(name)] started", context: context, level: 1)
            } catch let startError {
                // If interrupted, log immediately and mark failed
                Logger.shared.log(">> [BLOCKED] Task [\(name)]: \(startError)", context: context, level: 3, isError: true)
            }
        }
    }
    
    public func complete(_ outcome: Outcome = .success) {
        let duration = Date().timeIntervalSince(start)
        Task {
            await Logger.shared.endTask(id: id, outcome: outcome, duration: duration)
            
            let status: String
            switch outcome {
            case .success: status = "SUCCESS"
            case .failure(let r): status = "FAILURE (\(r))"
            case .partial(let r): status = "PARTIAL (\(r))"
            case .interrupted: status = "INTERRUPTED"
            }
            
            Logger.shared.log("<< Task [\(name)] finished: \(status) | took \(String(format: "%.3fs", duration))", context: context, level: 1)
        }
    }
}

/// Compatibility wrapper for legacy Log API
public final class Log: @unchecked Sendable {
    public static func debug(label: String, _ message: String) {
        let ctx = Logger.Context(label)
        Logger.shared.log("#Info \(message)", context: ctx, level: 0)
    }
    public static func info(label: String, _ message: String) {
        let ctx = Logger.Context(label)
        Logger.shared.log("#Info \(message)", context: ctx, level: 1)
    }
    public static func warning(label: String, _ message: String) {
        let ctx = Logger.Context(label)
        Logger.shared.log("#Warning \(message)", context: ctx, level: 2)
    }
    public static func error(label: String, _ message: String) {
        let ctx = Logger.Context(label)
        Logger.shared.log("#Error \(message)", context: ctx, level: 3, isError: true)
    }
}
