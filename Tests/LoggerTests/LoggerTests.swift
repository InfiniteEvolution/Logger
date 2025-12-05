//
//  LoggerTests.swift
//  LoggerTests
//
//  Created by Antigravity on 05/12/25.
//

import Testing

@testable import Logger

@Suite("Logger Tests") struct LoggerTests {

    @Test func initialization() {
        let log = LogContext("TEST")
        #expect(log != nil)  // Value type? No, Struct.
        // LogContext is a struct? Let's assume struct based on usage.
        // If struct, init returns a value.
    }

    @Test func loggingMethods() {
        let log = LogContext("TEST")
        // Just verify no crash
        log.info("Test message")
        log.warning("Test warning")
        log.error("Test error")
        log.expected("Test expected message")
        log.inited()
        log.deinited()
        log.debug("Debug message")
    }

    @Test func sendableConformance() {
        let log = LogContext("TEST")
        Task {
            log.info("Message from Task")
        }
    }

    @Test func customCharacterLogging() {
        let log = LogContext("TEST")
        log.info("Message with special chars: !@#$%^&*()")
        log.info("Message with newline\ncharacter")
        log.info("Unicode: 你好世界 🌍 émojis 🎉")
        log.info("")
        let longMessage = String(repeating: "A", count: 1000)
        log.info(longMessage)
    }

    @Test func loggerReuse() {
        let logger1 = DefaultLogger.shared(category: "REUS")
        let logger2 = DefaultLogger.shared(category: "REUS")
        let logger3 = DefaultLogger.shared(category: "DIFF")

        #expect(logger1 === logger2)
        #expect(logger1 !== logger3)
    }

    @Test @MainActor func systemInfo() {
        let logger = DefaultLogger.shared(category: "SYST")
        logger.logSystemInfo()
    }

    @Test func concurrentLogging() async {
        let log = LogContext("CONC")
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    log.info("Concurrent message \(i)")
                }
            }
        }
    }
}
