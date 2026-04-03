//  Logger+Metrics.swift
//  Logger
//
//  Summarization and retrieval logic for diagnostics.
import Foundation

extension Logger {
    /// Recent entries for a given context or all contexts.
    ///
    /// This method retrieves structured log entries from the in-memory cache.
    /// It is useful for displaying recent system activity in a UI or generating reports.
    ///
    /// - Parameter context: The specific context to filter by (optional).
    /// - Returns: An array of entries sorted by their occurrence time.
    public func recentEntries(for context: Context? = nil) async -> [Entry] {
        if let context = context {
            return contextStores[context] ?? []
        }
        return contextStores.values.flatMap { $0 }.sorted { $0.timestamp < $1.timestamp }
    }

    /// Summarizes the current logs for a specific context.
    ///
    /// Generates a human-interpretable string containing log counts,
    /// error rates, and task performance metrics.
    ///
    /// - Parameter context: The context to analyze.
    /// - Returns: A multi-line summary string.
    public func summarize(for context: Context) async -> String {
        let logs = contextStores[context] ?? []
        let tasks = taskRecords.values.filter { $0.context == context }
        guard !logs.isEmpty else { return "No logs for \(context.label)" }

        let errors = logs.filter { $0.isError }.count
        let warnings = logs.filter { $0.level == 2 }.count
        let completedTasks = tasks.filter { $0.end != nil }

        let successCount = completedTasks.filter { if case .some(.success) = $0.outcome { return true }; return false }.count
        let avgDuration = completedTasks.isEmpty ? 0 : (completedTasks.compactMap { $0.duration }.reduce(0, +) / Double(completedTasks.count))
        let successRate = completedTasks.isEmpty ? 0 : (Double(successCount) / Double(completedTasks.count)) * 100

        var summary = "Context: \(context.label) | Logs: \(logs.count) | Errors: \(errors) | Warnings: \(warnings)\n"
        summary += "Tasks: \(completedTasks.count) | Success Rate: \(String(format: "%.1f%%", successRate)) | Avg Duration: \(String(format: "%.3fs", avgDuration))"

        return summary
    }
}
