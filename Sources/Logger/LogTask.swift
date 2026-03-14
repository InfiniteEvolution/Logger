import Foundation

/// A high-level representation of an asynchronous task lifecycle with telemetry.
/// 
/// Tasks are used to track long-running operations in the system, providing
/// semantic outcomes (success, failure, interrupted) and duration tracking.
public struct LogTask: Sendable {
    /// The potential completion state of an asynchronous operation.
    public enum Outcome: Sendable {
        /// Task completed successfully without issues.
        case success
        /// Task failed with a description of the error.
        case failure(String)
        /// Task completed with partial success or data.
        case partial(String)
        /// Task was explicitly interrupted by autonomous governance.
        case interrupted
    }
    
    /// Internal record for persistent task monitoring.
    public struct Record: Sendable {
        /// Human-readable name for the task (e.g. Inference).
        public let name: String
        /// The originating diagnostic context.
        public let context: Logger.Context
        /// When the task was started.
        public let start: Date
        /// When the task was completed.
        public var end: Date?
        /// The semantic completion state.
        public var outcome: Outcome?
        /// The duration of the task in seconds.
        public var duration: TimeInterval?
        
        public init(name: String, context: Logger.Context, start: Date) {
            self.name = name
            self.context = context
            self.start = start
        }
    }
    
    private let logger: Logger
    private let context: Logger.Context
    private let name: String
    private let start = Date()
    private let id = UUID()
    
    /// Initializes a task and records its starting event.
    ///
    /// - Parameters:
    ///   - name: A human-readable identifier for the task.
    ///   - context: The diagnostic context.
    ///   - logger: The core logger managed as a dependency.
    public init(_ name: String, in context: Logger.Context, logger: Logger) {
        self.name = name
        self.context = context
        self.logger = logger
        let taskId = self.id
        let startTime = self.start
        Task {
            do {
                try await logger.startTask(id: taskId, name: name, context: context, timestamp: startTime)
                logger.log("Task [\(name)] started", context: context, level: 1)
            } catch let startError {
                logger.log("[BLOCKED] Task [\(name)]: \(startError)", context: context, level: 3, isError: true)
            }
        }
    }
    
    /// Completes the task and records its outcome and duration in telemetry.
    /// - Parameter outcome: The state of completion (defaults to .success).
    public func complete(_ outcome: Outcome = .success) {
        let duration = Date().timeIntervalSince(start)
        let taskId = self.id
        let lgr = self.logger
        let ctx = self.context
        let n = self.name
        
        Task {
            await lgr.endTask(id: taskId, outcome: outcome, duration: duration)
            
            let status: String
            switch outcome {
            case .success: status = "SUCCESS"
            case .failure(let r): status = "FAILURE (\(r))"
            case .partial(let r): status = "PARTIAL (\(r))"
            case .interrupted: status = "INTERRUPTED"
            }
            
            lgr.log("Task [\(n)] finished: \(status) | took \(String(format: "%.3fs", duration))", context: ctx, level: 1)
        }
    }
}
