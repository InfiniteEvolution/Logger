//  Logger+Proxy.swift
//  Logger
//
//  [Add description here]
import Foundation

// MARK: - LoggerProxy Conformance
extension Logger: LoggerProxy {
    /// Records a message with a specific LogLevel.
    nonisolated public func log(_ message: String, context: Logger.Context, level: LogLevel) {
        let isError = (level == .error)
        let intLevel: Int
        switch level {
        case .debug: intLevel = 1
        case .info: intLevel = 1
        case .warning: intLevel = 2
        case .error: intLevel = 3
        }
        self.log(message, context: context, level: intLevel, isError: isError)
    }

    nonisolated public func debug(_ message: String, context: Logger.Context) {
        self.log(message, context: context, level: .debug)
    }

    nonisolated public func info(_ message: String, context: Logger.Context) {
        self.log(message, context: context, level: .info)
    }

    nonisolated public func warning(_ message: String, context: Logger.Context) {
        self.log(message, context: context, level: .warning)
    }

    nonisolated public func error(_ message: String, context: Logger.Context) {
        self.log(message, context: context, level: .error)
    }
}
