//  Logger+Tasks.swift
//  Logger
//
//  Task lifecycle management.
import Foundation

extension Logger {
    /// Records the start of a task.
    ///
    /// This method registers a new logical task for telemetry purposes.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for this task execution.
    ///   - name: The human-readable name of the task.
    ///   - context: The logging context associated with the task.
    ///   - timestamp: Task start time.
    public func startTask(id: UUID, name: String, context: Context, timestamp: Date) async {
        taskRecords[id] = LogTask.Record(name: name, context: context, start: timestamp)
    }

    /// Records the end of a task with outcome and duration.
    ///
    /// Updates an existing task record with its final result and timing information.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the task being completed.
    ///   - outcome: The final result (e.g. success, failure).
    ///   - duration: Total execution time in seconds.
    public func endTask(id: UUID, outcome: LogTask.Outcome, duration: TimeInterval) {
        if var record = taskRecords[id] {
            record.end = Date()
            record.outcome = outcome
            record.duration = duration
            taskRecords[id] = record
        }
    }
}
