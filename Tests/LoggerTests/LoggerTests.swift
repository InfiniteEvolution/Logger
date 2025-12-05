//
//  LoggerTests.swift
//  LoggerTests
//
//  Created by Sijo on 05/12/25.
//

import Testing

@testable import Logger

@Suite("Logger Tests") struct LoggerTests {

    @Test func initialization() {
        let log = LogContext("TEST")
        // LogContext is a struct, init returns a value
        _ = log
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

    @Test func defaultLoggerInit() {
        let logger1 = DefaultLogger(category: "TEST")
        let logger2 = DefaultLogger(category: "DIFF")

        // Just verify initialization works
        logger1.info("Test message")
        logger2.info("Different logger")
    }

    @Test @MainActor func defaultLoggerMethods() {
        let logger = DefaultLogger(category: "SYST")
        logger.log("Log message")
        logger.info("Info message")
        logger.debug("Debug message")
        logger.notice("Notice message")
        logger.warning("Warning message")
        logger.error("Error message")
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
