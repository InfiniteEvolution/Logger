# Agent Documentation: Logger

### Platform & Architecture Constraints

* **Target Platform:** iOS 26 only
* All app targets and Swift Package Manager (SPM) modules are **platform-specific to iOS 26**
* **No cross-platform support is required or allowed**

#### Disallowed Patterns

The following must **never** appear in the codebase:

* `#if os(iOS)`
* `#if canImport(UIKit)`
* `#if canImport(SwiftUI)`
* Any platform-conditional compilation checks

All source code is assumed to run exclusively on **iOS 26**.

---

### Documentation & Code Formatting

* No emoji, symbols, or icons in code, comments, or documentation files
* Use plain ASCII text only (exception: code points in string literals when functionally required)
* Rationale: Improves accessibility, readability, and cross-platform compatibility
* Examples:
  * WRONG: "✅ Success", "❌ Error", "→ Next"
  * CORRECT: "Success", "Error", "Next" or "CORRECT:", "WRONG:", "->"

---

### UI & Framework Rules

* **SwiftUI is mandatory** for all UI
* UIKit usage is not allowed unless explicitly approved
* No redundant UI abstractions
* Prefer native SwiftUI patterns over wrapper layers

---

### Code Quality & Design Principles

* **Single Responsibility Principle (SRP)** is mandatory
* No duplicated logic across modules
* Shared behavior must live in clearly defined, reusable components
* Clear separation between:

  * UI
  * Domain logic
  * Infrastructure
* **Algorithmic Complexity**: Maximize O(1) operations. Prefer array lookups/hashing over iteration. Documentation must justify any O(n) or worse operation.
* **Event-Driven Architecture** (MANDATORY):
  * No timers, no runloops, no polling for background tasks
  * All lifecycle operations must be triggered by data events (writes, reads, user actions)
  * Rationale: App runs primarily in background where timers are unreliable and waste battery
  * Pattern: DataEvent -> TriggerCheck -> ConditionalAction
  * Examples:
    * CORRECT: Batcher.flush() -> StorageLifecycle.checkOnDataEvent()
    * WRONG: Timer.scheduledTimer() -> checkStorage()
* **Zero Tolerance for Dead Code**:
  * Delete unused implementations immediately when replaced
  * When replacing a component (e.g., CSVStore -> BinaryStore), remove the old one in the same commit
  * No "legacy" code without explicit production usage and documented retention reason
  * Mark deprecations with clear removal timeline and tracking issue
* **Resource Management**:
  * Use Swift Package Manager's Resources/ folder, never RawResources/
  * Generated files (ML models, assets) go directly to their final location
  * No build artifacts or intermediate files in root directory
  * All macOS system files (.DS_Store) must be gitignored
* **Minimum Footprint & Efficiency** (CRITICAL):
  * Data Storage: Use binary formats (24 bytes/record) over text (120+ bytes/record)
  * Battery: Event-driven > timers, batching > frequent I/O, O(1) > O(n)
  * Memory: Swift-level object pooling, high-level collection optimizations, no unnecessary allocations in hot paths
  * Compression: LZFSE for cold storage (10x reduction), Float16 for sensor values
  * Rationale: App runs continuously in background processing millions of sensor readings
* **Single Source of Truth** (MANDATORY):
  * Configuration values must be defined ONCE in a dedicated struct (e.g., StoragePolicy)
  * No magic numbers scattered in code - extract to named constants
  * Data types (enums, models) defined in ONE canonical location only
  * Cross-module constants go in shared config files
  * Examples: Vibe enum in SensorData.swift, storage limits in StoragePolicy.swift
* **iOS/Swift API Compliance** (MANDATORY):
  * No deprecated APIs - use modern Swift concurrency (async/await, actors)
  * Avoid DispatchQueue.main.async - use @MainActor instead
  * Avoid force unwrap (!) except with documented justification
  * Use guard/if-let for optionals, try? or try-catch for errors
  * @unchecked Sendable: ONLY for system framework types (CoreML, ActivityKit)
  * nonisolated(unsafe): ONLY for truly static/immutable global state
  * @preconcurrency: ONLY for system imports that lack Sendable conformance
  * All new code must be Swift 6 strict concurrency compliant
* **iOS 26 Exclusivity** (MANDATORY):
  * Target iOS 26.0 minimum - NO backward compatibility code
  * NO #available checks - assume iOS 26 APIs always available
  * NO @available annotations for deprecation handling
  * Use latest Swift 6 features without version guards
  * All Package.swift must specify: platforms: [.iOS(.v26)]
* **SwiftLint Standards** (MANDATORY):
  * NO print() in production code - use Logger module exclusively
  * Use log.info/warning/error for all diagnostic output
  * Commented-out print() statements must be removed, not left dormant
  * Line length: 120 characters maximum
  * Trailing whitespace: prohibited
  * Force cast/unwrap: prohibited except with inline documentation
  * Cyclomatic complexity: maximum 10 per function
  * File length: maximum 500 lines (prefer smaller, focused files)
* **HIG & AppStore Compliance** (MANDATORY):
  * **Privacy**: Explicitly request permissions (Location, Motion) with clear purpose strings (`NSUsageDescription`). Data collection must be transparent and minimized.
  * **User Experience**: Support Dark Mode, Dynamic Type, and VoiceOver (Accessibility) by default.
  * **Widgets/Live Activities**: Must provide timely, relevant value. No static/stale data.
  * **Performance**: App must not drain battery. Strict background processing limits compliance.
  * **Business**: No hidden features or undocumented functionality.

---

### Documentation Requirements

* All public types, methods, and properties must be documented using **Apple DocC style**
* Documentation must be kept in sync with code changes
* After **every functional change**, update:

  * `README.md`
  * Project Whitepaper (architecture / design document)

---

### Build & Test Enforcement

For **every change**, agents must follow this sequence:

1. **Build the project**

   * Confirm the build succeeds
2. **Update or add tests** relevant to the change
3. **Run all tests**

   * Unit tests
   * UI tests (if applicable)
4. **Confirm all tests pass**

   * No partial test runs
   * No skipped failures

Changes are considered **invalid** if:

* The project does not build
* Tests are not updated
* Any test fails

---

### Testing Rules

* Tests must be updated **after a successful build**
* Every behavior change requires corresponding test coverage
* No test-only logic duplication
* Test names must clearly describe behavior

---

### Agent Enforcement

AI agents must:

* Assume iOS 26 APIs are always available
* Never introduce platform checks
* Never weaken constraints “for safety”
* Refuse to proceed if a change would violate these rules

---

## Identity
**Name**: The Voice
**Role**: Diagnostics & Telemetry
**Key Responsibility**: Providing structured, reliable logging without impacting performance.

## What is Implemented
-   **LogContext**: A unified wrapper around `os.Logger` with automatic subsystem tagging.
-   **Privacy Redaction**: Compliance with Apple's `OSLog` privacy spec.
-   **Release Stripping**: Debug logs are removed in Release builds.

## What Will Be
-   **Telemetry Hooks**: Structured events for "Training Duration", "Inference Latency" to track performance over time.
-   **Remote Echo**: (Optional) Capability to stream logs to a connected Mac for real-time debugging during field tests.

## Constraints
-   **Zero Overhead**: Logging must have negligible impact on CPU (< 0.1%).
-   **Usage**: Do not log PII (Personally Identifiable Information) in cleartext.
-   **Volume**: Avoid logging inside tight loops (e.g., accelerometer updates) to prevent console spam and CPU thrashing.

## How Should Be The Code
-   **Implicit Returns**: Omit `return` keyword for single-line function bodies and computed properties.
-   **Ring Buffer**: Keep the last 100 debug logs in a circular memory buffer. Only flush to disk/console if an **Error** occurs ("Black Box Recorder" mode).
-   **Lazy Interpolation**: Use `log.debug("Val: \(val)")` patterns that the compiler can optimize out if logging is disabled.
-   **Structured**: Prefer fixed messages + key/value pairs over long prose.
-   **Levels**:
    -   `log.info`: Expected flow (e.g., "Started recording", "Model loaded").
    -   `log.warning`: Unexpected cases, `else` branches, or unhandled states (e.g., "GPS signal weak", "Duplicate file ignored").
    -   `log.error`: Errors from `throw` or `catch` blocks (e.g., "Failed to save file").
-   **Minimalist**: Do not use Logger for high-frequency streams (like raw Accelerometer data) unless explicitly debugging.
