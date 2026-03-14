import Foundation

/// A lightweight diagnostic wrapper that maintains a specific context label for all entries.
///
/// LogContext is the primary consumer-side interface for developers to record system telemetry.
/// It wraps a more complex logging infrastructure with a context label and optional correlation ID.
public struct LogContext: Sendable {
    /// The specific 4-character context (e.g. VBPR, IBSV).
    public let context: Logger.Context
    
    /// Optional identifier for tracing long-running asynchronous logic chains.
    public let correlationId: String?
    
    /// The injected proxy for recording logs (e.g. real Logger or Stub).
    private let proxy: any LoggerProxy
    
    /// Create a context with an explicit Logger.Context.
    public init(_ context: Logger.Context, correlationId: String? = nil, proxy: any LoggerProxy) {
        self.context = context
        self.correlationId = correlationId
        self.proxy = proxy
    }
    
    /// Create a context with a raw label string (will be verified as 4 characters).
    public init(_ label: String, correlationId: String? = nil, proxy: any LoggerProxy) {
        self.context = Logger.Context(label)
        self.correlationId = correlationId
        self.proxy = proxy
    }
    
    /// Default initializer with a LoggerProxyStub, to be used only during migration.
    public init(_ label: String, correlationId: String? = nil) {
        self.context = Logger.Context(label)
        self.correlationId = correlationId
        self.proxy = LoggerProxyStub()
    }

    /// Derived context that maintains the same label but carries a new correlation ID.
    public func with(correlationId: String) -> LogContext {
        LogContext(self.context, correlationId: correlationId, proxy: proxy)
    }
    
    /// Record a system debug event (low significance).
    public func debug(_ message: String) {
        proxy.log("[DEBUG] \(message)", level: .debug)
    }
    
    /// Record an informational event (regular significance).
    public func info(_ message: String) {
        proxy.log("#Info \(message)", level: .info)
    }
    
    /// Record a warning event (potential problem or unusual behavior).
    public func warning(_ message: String) {
        proxy.log("#Warning \(message)", level: .warning)
    }
    
    /// Record a system error (failure in an operation).
    public func error(_ message: String) {
        proxy.log("#Error \(message)", level: .error)
    }
    
    /// Record a specialized "critical" error needing immediate attention.
    public func critical(_ message: String) {
        proxy.log("#Error (CRITICAL) \(message)", level: .error)
    }
    
    /// Record a system fault (potentially fatal or severe regression).
    public func fault(_ message: String) {
        proxy.log("#Fault \(message)", level: .error)
    }
    
    /// Record an expected but notable event (e.g. handled fallback).
    public func expected(_ message: String) {
        proxy.log("#Expected \(message)", level: .info)
    }
    
    /// Logs that the associated type or instance has been initialized.
    public func inited() {
        debug("Initialized")
    }
    
    /// Logs that the associated type or instance has been deallocated.
    public func deinited() {
        debug("Deinitialized")
    }
    
    /// Summarize the logs for the current context (latency-heavy operation).
    public func summarize() async -> String {
        return "Summary via proxy not implemented in LogContext"
    }
}
