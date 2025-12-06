//
//  Logger.swift
//  Logger
//
//  Created by Sijo on 30/11/25.
//

import Foundation
import os

/// A context-aware logger that prefixes logs with a label.
///
/// `LogContext` provides a convenient wrapper around `DefaultLogger` that automatically
/// prefixes all log messages with a 4-character label. This helps in filtering and
/// identifying logs from specific components.
public struct LogContext: Sendable {
    private let label: String
    private let logger: os.Logger

    /// Date formatter used for the timestamp prefix.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        formatter.dateFormat = "dd.MM.yyyy.HH.mm.ss.SSS"
        return formatter
    }()

    /// Returns the current timestamp string.
    private var timestamp: String {
        Self.dateFormatter.string(from: Date())
    }

    /// Initializes a new log context with a specific label.
    /// - Parameter label: The label to prefix logs with (e.g., "AUTH", "NETW"). Must be exactly 4 characters.
    public init(_ label: String) {
        assert(label.count == 4, "LogContext label must be exactly 4 characters")
        let subsystem = Bundle.main.bundleIdentifier ?? "com.canvas.app"
        self.label = label
        self.logger = os.Logger(subsystem: subsystem, category: label)
    }

    /// Logs an initialization message.
    public func inited() {
        logger.log("\(timestamp) | \(label) | #Init | Initialized")
    }

    /// Logs a deinitialization message.
    public func deinited() {
        logger.log("\(timestamp) | \(label) | #Deinit | Deinitialized")
    }

    /// Logs a standard message.
    /// - Parameter message: The message to log.
    public func info(_ message: String) {
        logger.log("\(timestamp) | \(label) | #Info | \(message)")
    }

    /// Logs a warning message.
    /// - Parameter message: The warning message.
    public func warning(_ message: String) {
        logger.warning("\(timestamp) | \(label) | #Warning | \(message)")
    }

    /// Logs an error message.
    /// - Parameter message: The error message.
    public func error(_ message: String) {
        logger.error("\(timestamp) | \(label) | #Error | \(message)")
    }

    #if DEBUG
        /// Logs a debug message.
        /// - Parameter message: The debug message.
        public func debug(_ message: String) {
            logger.debug("\(timestamp) | \(label) | #Debug | \(message)")
        }
    #endif

    #if DEBUG
        /// Logs an expected behavior message (useful for tests or verifying flow).
        /// - Parameter message: The message describing the expected behavior.
        public func notice(_ message: String) {
            logger.notice("\(timestamp) | \(label) | #Notice | \(message)")
        }
    #endif

    /// Logs an expected behavior message (useful for tests or verifying flow).
    /// - Parameter message: The message describing the expected behavior.
    public func critical(_ message: String) {
        logger.critical("\(timestamp) | \(label) | #Critical | \(message)")
    }

    /// Logs an expected behavior message (useful for tests or verifying flow).
    /// - Parameter message: The message describing the expected behavior.
    public func fault(_ message: String) {
        logger.fault("\(timestamp) | \(label) | #Fault | \(message)")
    }
}
