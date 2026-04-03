//  LogContext.swift
//  Logger
//
//  Lightweight diagnostic wrapper that maintains a specific context label for all telemetry.
import Foundation

/// Primary consumer-side interface for recording system telemetry.
public struct LogContext: Sendable {
    /// The specific 4-character diagnostic context.
    public let context: Logger.Context

    /// An optional identifier for tracing logic chains.
    public let correlationId: String?

    /// The diagnostic proxy used for recording logs.
    private let proxy: any LoggerProxy

    // MARK: - Initialization
    
    /// Initializes a new diagnostic context with a protocol-based proxy.
    ///
    /// - Parameters:
    ///   - context: The specific diagnostic context.
    ///   - correlationId: An optional identifier for tracing (optional).
    ///   - proxy: The diagnostic proxy implementation.
    public init(
        _ context: Logger.Context, 
        correlationId: String? = nil, 
        proxy: any LoggerProxy
    ) {
        self.context = context
        self.correlationId = correlationId
        self.proxy = proxy
    }

    /// Initializes a new diagnostic context from a raw label.
    ///
    /// - Parameters:
    ///   - label: The raw context label (e.g. "GENL").
    ///   - correlationId: An optional identifier for tracing (optional).
    ///   - proxy: The diagnostic proxy implementation.
    public init(
        _ label: String, 
        correlationId: String? = nil, 
        proxy: any LoggerProxy
    ) {
        self.context = Logger.Context(label)
        self.correlationId = correlationId
        self.proxy = proxy
    }

    /// Default initializer that uses a stub diagnostic proxy.
    ///
    /// - Parameters:
    ///   - label: The raw label name value.
    ///   - correlationId: The optional correlation identifier.
    public init(
        _ label: String, 
        correlationId: String? = nil
    ) {
        self.context = Logger.Context(label)
        self.correlationId = correlationId
        self.proxy = LoggerProxyStub()
    }

    /// Derived context that maintains the same label but carries a new correlation ID.
    ///
    /// This is useful when entering a new logical sub-operation that belongs
    /// to the same system context but needs a unique trace identifier.
    ///
    /// - Parameter correlationId: The new identifier for this context chain.
    /// - Returns: A new `LogContext` instance with the updated identifier.
    public func with(correlationId: String) -> LogContext {
        LogContext(self.context, correlationId: correlationId, proxy: proxy)
    }
    
    /// Returns the URL to the persistent log file, if available.
    public var storageURL: URL? {
        proxy.storageURL
    }

    /// Record a system debug event (low significance).
    ///
    /// - Parameter message: The human-readable text to log.
    public func debug(_ message: String) {
        proxy.debug(message, context: context)
    }

    /// Records an info level diagnostic message.
    ///
    /// - Parameter message: The human-readable text to log.
    public func info(_ message: String) {
        proxy.info(message, context: context)
    }

    /// Records a warning level diagnostic message.
    ///
    /// - Parameter message: The human-readable text to log.
    public func warning(_ message: String) {
        proxy.warning(message, context: context)
    }

    /// Records an error level diagnostic message.
    ///
    /// - Parameter message: The human-readable text to log.
    public func error(_ message: String) {
        proxy.error(message, context: context)
    }

    /// Records a critical level diagnostic message.
    ///
    /// - Parameter message: The human-readable text to log.
    public func critical(_ message: String) {
        proxy.critical(message, context: context)
    }

    /// Records an informational diagnostic message for expected conditions.
    public func expected(_ message: String) {
        info(message)
    }

    /// Records that the associated instance has been initialized.
    public func inited() {
        debug("Initialized.")
    }

    /// Records that the associated instance has been deallocated.
    public func deinited() {
        debug("Deinitialized.")
    }

    /// Summarizes the diagnostic telemetry entries for the current context.
    ///
    /// - Returns: A summary string of recent logs in this context.
    public func summarize() async -> String {
        return "Summary via proxy not implemented in LogContext."
    }
}

