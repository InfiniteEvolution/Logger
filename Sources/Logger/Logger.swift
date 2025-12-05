//
//  Logger.swift
//  Logger
//
//  Created by Antigravity on 30/11/25.
//

import Foundation
import os

/// A context-aware logger that prefixes logs with a label.
///
/// `LogContext` provides a convenient wrapper around `DefaultLogger` that automatically
/// prefixes all log messages with a 4-character label. This helps in filtering and
/// identifying logs from specific components.
@available(iOS 14.0, macOS 11.0, *)
public struct LogContext: Sendable {
    private let label: String
    private let logger: os.Logger

    /// Initializes a new log context with a specific label.
    /// - Parameter label: The label to prefix logs with (e.g., "AUTH", "NETW"). Must be exactly 4 characters.
    public init(_ label: String) {
        assert(label.count == 4, "LogContext label must be exactly 4 characters")
        let subsystem = Bundle.main.bundleIdentifier ?? "com.canvas.app"
        self.label = label
        self.logger = os.Logger(subsystem: subsystem, category: label)
    }

    /// Logs a standard message.
    /// - Parameter message: The message to log.
    public func info(_ message: String) {
        logger.log("#Info | \(message)")
    }

    /// Logs an initialization message.
    public func inited() {
        logger.log("#Init | \(label)")
    }

    /// Logs a deinitialization message.
    public func deinited() {
        logger.log("#Dint | \(label)")
    }

    /// Logs a warning message.
    /// - Parameter message: The warning message.
    public func warning(_ message: String) {
        logger.warning("#Warn | \(message)")
    }

    /// Logs an error message.
    /// - Parameter message: The error message.
    public func error(_ message: String) {
        logger.error("#Eror | \(message)")
    }

    /// Logs a debug message.
    /// - Parameter message: The debug message.
    public func debug(_ message: String) {
        logger.debug("#Debg | \(message)")
    }

    /// Logs an expected behavior message (useful for tests or verifying flow).
    /// - Parameter message: The message describing the expected behavior.
    public func notice(_ message: String) {
        logger.notice("#Note | \(message)")
    }
}
