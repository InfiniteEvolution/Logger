//  LogStorage.swift
//  Logger
//
//  Persistent storage engine for diagnostic telemetry.
import Foundation

/// Final actor responsible for persistent telemetry storage.
///
/// LogStorage maintains a structured ASCII text file containing all system logs.
/// It uses a CSV-style format for easy parsing and analysis.
public final actor LogStorage: Sendable {
    /// The URL on disk where logs are stored.
    public nonisolated let fileURL: URL
    
    // Buffering state for O(1) performance and I/O efficiency
    private var buffer: String = ""
    private var entryCount: Int = 0
    private let batchThreshold: Int = 50
    private var flushTask: Task<Void, Never>?
    private let flushInterval: TimeInterval = 10.0
    
    // No file handle kept open between batches to ensure data integrity and Finder visibility
    
    // Rotation config
    private let maxFileSize: Int64 = 10 * 1024 * 1024 // 10MB limit

    /// Returns the standard hidden URL for diagnostic logs.
    /// This location is not accessible via Mac File Sharing (iTunes/Finder).
    public static var defaultHiddenURL: URL {
        let fileManager = FileManager.default
        let libraryDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let logsDir = libraryDir.appendingPathComponent("Logs", isDirectory: true)
        return logsDir.appendingPathComponent("system_diagnostics.txt")
    }

    /// Returns the standard shared URL for diagnostic logs.
    ///
    /// This location is accessible via Finder when iPhone is connected to Mac.
    /// It is stored in the app's Documents/Logs directory.
    ///
    /// - Returns: A URL pointing to the shared system diagnostics file.
    public static var defaultSharedURL: URL {
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDir.appendingPathComponent("system_diagnostics.txt")
    }

    /// Initializes a new LogStorage with the target file URL.
    ///
    /// Initializing LogStorage ensures the diagnostic folder exists and the
    /// CSV header is written if the file is new.
    ///
    /// - Parameter fileURL: The URL on disk where logs will be appended. Defaults to `defaultSharedURL`.
    public init(fileURL: URL = LogStorage.defaultSharedURL) {
        self.fileURL = fileURL
        setupStorage()
    }

    private nonisolated func setupStorage() {
        let directory = fileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                let header = "Timestamp,Level,Context,Message\n"
                try header.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            // Using absolute manual format for bootstrap failures
            print(Logger.Entry.formatConsoleLine(timestamp: Date(), tag: "#ERROR", label: "LOST", message: "Failed to setup storage: \(error.localizedDescription)"))
        }
    }

    /// Persists a telemetry entry to the in-memory buffer.
    ///
    /// The entry is appended in CSV format using Entry.csvLine. A flush is
    /// triggered once the batch threshold is reached, or deferred via a
    /// periodic background task.
    ///
    /// - Parameter entry: The structured log entry to persist.
    public func store(_ entry: Logger.Entry) {
        buffer += entry.csvLine
        entryCount += 1

        if entryCount >= batchThreshold {
            flush()
        } else {
            scheduleFlush()
        }
    }

    private func scheduleFlush() {
        guard flushTask == nil else { return }
        flushTask = Task(priority: .utility) { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(10 * 1_000_000_000))
            await self?.flush()
        }
    }

    /// Forces a flush of the in-memory buffer to disk.
    ///
    /// This method cancels any pending scheduled flush tasks and triggers
    /// an atomic write of the current message buffer to the target file.
    /// It also performs a rotation check after the write is confirmed.
    public func flush() {
        flushTask?.cancel()
        flushTask = nil
        
        guard !buffer.isEmpty else { return }
        
        let dataToAppend = buffer
        buffer = ""
        entryCount = 0
        
        write(dataToAppend)
        checkRotation()
    }

    private func write(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let handle = try FileHandle(forWritingTo: fileURL)
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.close()
        } catch {
            print(Logger.Entry.formatConsoleLine(timestamp: Date(), tag: "#ERROR", label: "LOST", message: "Batch write failed: \(error.localizedDescription)"))
        }
    }

    private func checkRotation() {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attributes[.size] as? Int64,
              size > maxFileSize else { return }
        
        rotate()
    }

    private func rotate() {
        let tempURL = fileURL.deletingLastPathComponent().appendingPathComponent("log_rotation.tmp")
        do {
            let logs = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = logs.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            let header = lines.first ?? "Timestamp,Level,Context,Message"
            let tail = lines.suffix(lines.count / 2)
            
            let newContent = ([header] + Array(tail)).joined(separator: "\n") + "\n"
            try newContent.write(to: tempURL, atomically: true, encoding: .utf8)
            
            try FileManager.default.removeItem(at: fileURL)
            try FileManager.default.moveItem(at: tempURL, to: fileURL)
        } catch {
            print(Logger.Entry.formatConsoleLine(timestamp: Date(), tag: "#ERROR", label: "LOST", message: "Rotation failed: \(error.localizedDescription)"))
            try? FileManager.default.removeItem(at: tempURL)
        }
    }
}
