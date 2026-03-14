import Foundation

// MARK: - LoggerProxy Conformance
extension Logger: LoggerProxy {
    /// Records a message with a specific LogLevel.
    /// - Parameters:
    ///   - message: The diagnostic message.
    ///   - level: The severity level (debug, info, warning, error).
    nonisolated public func log(_ message: String, level: LogLevel) {
        Task { await self._log(message, level: level) }
    }
    
    /// Records a debug message via the proxy.
    nonisolated public func debug(_ message: String) {
        self.log(message, level: .debug)
    }
    
    /// Records an informational message via the proxy.
    nonisolated public func info(_ message: String) {
        self.log(message, level: .info)
    }
    
    /// Records a warning message via the proxy.
    nonisolated public func warning(_ message: String) {
        self.log(message, level: .warning)
    }
    
    /// Records an error message via the proxy.
    nonisolated public func error(_ message: String) {
        self.log(message, level: .error)
    }
    
    /// Internal isolated method for proxy-initiated logs.
    private func _log(_ message: String, level: LogLevel) async {
        print("[\(level)] \(message)")
    }
}
