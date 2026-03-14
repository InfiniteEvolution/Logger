import Foundation

/// Protocol for logger abstraction to allow dependency injection
public protocol LoggerProxy: Sendable {
    func log(_ message: String, level: LogLevel)
    func debug(_ message: String)
    func info(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
}

public enum LogLevel: Sendable {
    case debug
    case info
    case warning
    case error
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

/// Stub implementation for testing
public struct LoggerProxyStub: LoggerProxy {
    public init() {}
    public func log(_ message: String, level: LogLevel) {}
    public func debug(_ message: String) {}
    public func info(_ message: String) {}
    public func warning(_ message: String) {}
    public func error(_ message: String) {}
}
