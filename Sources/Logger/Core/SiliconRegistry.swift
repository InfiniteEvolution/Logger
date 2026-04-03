//  SiliconRegistry.swift
//  Logger
//
//  The source of truth for unified service management across all packages.
import Foundation

/// Unified registry for cross-package dependency injection.
///
/// SiliconRegistry provides a consistent access pattern for shared services like logging.
public final class SiliconRegistry: Sendable {
    private let logger: any LoggerProxy

    /// Initializes the registry with a mandatory logger.
    /// - Parameter logger: The primary logging interface to be registered.
    public init(logger: any LoggerProxy) {
        self.logger = logger
    }

    /// Retrieves the unified logger instance.
    /// - Returns: The registered LoggerProxy.
    public func getLogger() -> any LoggerProxy {
        logger
    }
}
