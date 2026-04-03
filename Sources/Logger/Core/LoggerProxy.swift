//  LoggerProxy.swift
//  Logger
//
//  [Add description here]
import Foundation

/// Protocol for logger abstraction to allow dependency injection
public protocol LoggerProxy: Sendable {
    func log(_ message: String, context: Logger.Context, level: LogLevel)
    func debug(_ message: String, context: Logger.Context)
    func info(_ message: String, context: Logger.Context)
    func warning(_ message: String, context: Logger.Context)
    func error(_ message: String, context: Logger.Context)
    func critical(_ message: String, context: Logger.Context)
    
    /// Returns the URL to the persistent log file, if available.
    var storageURL: URL? { get }
}

/// Convenience static logger for quick access
public enum Log {
    public static func warning(label: String, _ message: String) {
        LogContext(label).warning(message)
    }
    public static func error(label: String, _ message: String) {
        LogContext(label).error(message)
    }
    public static func info(label: String, _ message: String) {
        LogContext(label).info(message)
    }
}

/// Stub implementation for testing.
///
/// Uses the caller's context label in console output to maintain
/// format compliance: `Time | Context<4 Char> | #LEVEL | Message`.
public struct LoggerProxyStub: LoggerProxy {
    public init() {}

    public var storageURL: URL? { nil }

    private func stubLog(_ message: String, context: Logger.Context, tag: String = "#WARNING") {
        print(Logger.Entry.formatConsoleLine(timestamp: Date(), tag: tag, label: context.label, message: message))
    }
    public func log(_ message: String, context: Logger.Context, level: LogLevel) {
        stubLog(message, context: context, tag: level.tag)
    }
    public func debug(_ message: String, context: Logger.Context) {
        stubLog(message, context: context, tag: "#DEBUG")
    }
    public func info(_ message: String, context: Logger.Context) {
        stubLog(message, context: context, tag: "#INFO")
    }
    public func warning(_ message: String, context: Logger.Context) {
        stubLog(message, context: context, tag: "#WARNING")
    }
    public func error(_ message: String, context: Logger.Context) {
        stubLog(message, context: context, tag: "#ERROR")
    }
    public func critical(_ message: String, context: Logger.Context) {
        stubLog(message, context: context, tag: "#CRITICAL")
    }
}
