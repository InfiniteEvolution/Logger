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
    public struct AutonomicAlert: Sendable {
        /// The logging context where the alert originated.
        public let context: Context
        /// The action determined by the analyzer (e.g. interrupt, throttle).
        public let action: LogAnalyzer.AutonomicAction
        /// The specific performance or health metric being flagged.
        public let metric: String
        /// The current value of that metric.
        public let value: String

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
        /// Severity level from 1 (debug) to 4 (fault).
        public let level: Int
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

        /// Human-readable time representation.
        public var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MM-yyyy-HH:mm:ss:SSS"
            return formatter.string(from: timestamp)
        }
    }
}
