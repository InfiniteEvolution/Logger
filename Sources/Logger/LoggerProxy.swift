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
    private func stubLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy-HH:mm:ss:SSS"
        print("\(formatter.string(from: Date())) | LPRX | #Warning | \(message)")
    }
    public func log(_ message: String, context: Logger.Context, level: LogLevel) {
        stubLog("log() called on stub implementation. Message: \(message)")
    }
    public func debug(_ message: String, context: Logger.Context) {
        // Stubs usually silent for debug
    }
    public func info(_ message: String, context: Logger.Context) {
        stubLog("\(#function) should be implemented before using.")
    }
    public func warning(_ message: String, context: Logger.Context) {
        stubLog("\(#function) should be implemented before using.")
    }
    public func error(_ message: String, context: Logger.Context) {
        stubLog("\(#function) should be implemented before using.")
    }
}
