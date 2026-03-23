//  Logger+Types.swift
//  Logger
//
//  Strategic types and structures for the diagnostic telemetry system.
import Foundation

extension Logger {
    /// Autonomic regulation error thrown when logic indicates system failure.
    public enum AutonomicError: Error {
        /// Execution was interrupted with a reason.
        case interrupted(String)
    }

    /// Payload for autonomic system alerts posted via notification.
    ///
    /// AutonomicAlert is used to broadcast critical system status changes
    /// that require immediate attention or autonomic intervention.
    public struct AutonomicAlert: Sendable {
        /// The logging context where the alert originated.
        public let context: Context
        /// The action determined by the analyzer (e.g. interrupt, throttle).
        public let action: LogAnalyzer.AutonomicAction
        /// The specific performance or health metric being flagged.
        public let metric: String
        /// The current value of that metric.
        public let value: String

        /// Initializes a new alert payload.
        public init(context: Context, action: LogAnalyzer.AutonomicAction, metric: String, value: String) {
            self.context = context
            self.action = action
            self.metric = metric
            self.value = value
        }
    }

    /// A structured label to categorize and route diagnostic information.
    public struct Context: Hashable, Sendable, CustomStringConvertible {
        /// The 4-character uppercase label for this context (e.g. GENL).
        public let label: String

        /// Initializes a new context from a label string.
        /// - Parameter label: The label (will be uppercased).
        public init(_ label: String) {
            self.label = label.uppercased()
        }

        public var description: String { label }
        public var rawValue: String { label }

        /// A stable numerical identifier derived from the label hash (0.0 to 10.0).
        /// Used as feature input for neural governance models.
        var id: Double {
            let hash = abs(label.hashValue)
            return Double(hash % 100) / 10.0
        }

        /// Generic context for non-specific platform logs.
        public static let general = Context("GENL")
    }

    /// A single immutable entry in the diagnostic telemetry stream.
    public struct Entry: Identifiable, Sendable {
        /// Unique identifier for this entry.
        public let id: UUID
        /// Time when the event occurred.
        public let timestamp: Date
        /// Numerical severity level (0=Debug, 1=Info, 2=Warning, 3=Error).
        public let level: Int
        /// Logic-level severity category.
        public var severity: LogLevel {
            switch level {
            case 0: return .debug
            case 2: return .warning
            case 3: return .error
            case 4: return .critical
            default: return .info
            }
        }
        /// The originating context for this message.
        public let context: Context
        /// The human-readable diagnostic message.
        public let message: String
        /// Boolean flag explicitly marking this as an error event.
        public let isError: Bool
        /// Optional identifier for tracing requested logic chains.
        public let correlationId: String?

        public init(id: UUID = UUID(), timestamp: Date, level: Int, context: Context, message: String, isError: Bool, correlationId: String?) {
            self.id = id
            self.timestamp = timestamp
            self.level = level
            self.context = context
            self.message = message
            self.isError = isError
            self.correlationId = correlationId
        }

        /// Standardized machine-readable ISO 8601 UTC timestamp.
        public var formattedTime: String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.string(from: timestamp)
        }

        /// The standardized string for console output.
        public var consoleLine: String {
            return Entry.formatConsoleLine(timestamp: timestamp, tag: severity.tag, label: context.label, message: message)
        }

        /// The standardized string for CSV storage.
        public var csvLine: String {
            let escapedMessage = message.replacingOccurrences(of: "\"", with: "\"\"")
            return "\(formattedTime),\(severity.tag),\(context.label),\"\(escapedMessage)\"\n"
        }

        /// Static helper to format a single console line consistently.
        ///
        /// This method enforces the global logging format standard:
        /// `Time | Context<Absolute 4 Char> | #LEVEL | Message`
        ///
        /// - Parameters:
        ///   - timestamp: Exact time of the event.
        ///   - tag: Standardized level tag (e.g. #INFO).
        ///   - label: 4-character context identifier.
        ///   - message: Human-readable diagnostic message.
        /// - Returns: A formatted string ready for console output.
        public static func formatConsoleLine(timestamp: Date, tag: String, label: String, message: String) -> String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let timeString = formatter.string(from: timestamp)
            return "\(timeString) | \(label) | \(tag) | \(message)"
        }
    }
}

/// Logical severity categories for diagnostic events.
public enum LogLevel: Int, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4

    /// Returns the standardized #TAG for this level.
    public var tag: String {
        switch self {
        case .debug: return "#DEBUG"
        case .info: return "#INFO"
        case .warning: return "#WARNING"
        case .error: return "#ERROR"
        case .critical: return "#CRITICAL"
        }
    }
}
