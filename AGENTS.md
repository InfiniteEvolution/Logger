# AGENTS.md: Logger

Applies Root Agent Constitution: This document extends and adheres to the repository root Agent Constitution (/Agent.md). All constraints and rules from the root are in effect for this package.

Root Constraint Checklist (auto-affirmation):

- Target Platform: iOS 26 only
- No cross-platform support is required or allowed
- Disallowed Patterns
- SwiftUI is mandatory
- O(1) Requirement

## Platform & Architecture Constraints

* **Target Platform:** iOS 26 only
* All app targets and Swift Package Manager (SPM) modules are **platform-specific to iOS 26**
* **No cross-platform support is required or allowed**
* **Size Limit:** <30MB Total App Size (Strict Enforcement)

### Disallowed Patterns
* `#if os(iOS)` or any `#if os(...)` conditional
* `#if canImport(UIKit)` or any `#if canImport(...)` conditional
* `#if canImport(SwiftUI)`
* `@available(...)` annotations (all iOS 26 APIs are unconditionally available)
* `#available(...)` runtime checks (no backward compatibility)
* Any platform-conditional compilation checks

---

## Documentation & Code Formatting

* No emoji, symbols, or icons in code, comments, or documentation files
* Use plain ASCII text only (exception: code points in string literals when functionally required)
* Rationale: Improves accessibility, readability, and cross-platform compatibility
* All public types, methods, and properties must be documented using **Apple DocC style** (Summary, Discussion, Parameters, Returns, Throws, Examples)
* **Import Hygiene**: Remove all unwanted, unused, or duplicate imports.
* **File Headers**: Maintain a standardized format for all file headers across the project.
* **White Space**: Clean up all unwanted white space and redundant new lines.

---

## UI & Framework Rules

* **SwiftUI is mandatory** for all UI
* UIKit usage is not allowed unless explicitly approved
* No redundant UI abstractions; prefer native SwiftUI patterns
* All background operations use `.utility` QoS for energy efficiency

---

## Global Architecture & ML Standards

* **Layering**:
  * Logger is a foundational **Infrastructure** package.
  * It has no dependencies on domain or presentation code.
  * All other packages depend on Logger; Logger depends on none.
* **Single Responsibility**:
  * Logger is responsible for structured logging, metrics, and governance signals.
  * It must not implement domain-specific decision logic.
* **ML Model Usage**:
  * Logger uses models to classify or prioritize logs/metrics.
* **No Static Behavioral Values**:
  * Thresholds for log levels or sampling rates MUST be model-driven.
* **Zero Constant Usage**: Hardcoded constants are prohibited; all behavioral values must be model-driven or registry-provided.

---

## Code Quality Standards (Phase 0-3+)

### Structural Concurrency (Phase 1+)
* **Actor Isolation**: All mutable state must reside in actors (e.g., `LogStorage`).
* **Await Rule**: Cross-isolation calls require `await`.
* **Nonisolated**: `nonisolated` members do NOT require `await`.
* **Final Actors**: All actors must be `final`.
* **No @Observable on Actors**: `@Observable` macro NOT allowed on actors.
* **Implicit Self**: After `guard let self else { return }`, remove explicit `self.` usage below this guard if possible.
* **Minimize Optionals**: Favor non-optional types and exhaustive handling to minimize optional usage.

### Dependency Injection (Phase 2+)
* **Mandatory DI**: Use Dependency Injection for all components.
* **No Singletons**: `static let shared` is strictly prohibited.

### Complexity & Performance (MANDATORY)
* **O(1) Requirement**: ALL logging operations MUST be O(1) (latency < 1ms).
* **Efficiency**: Must not block the calling thread or consume excessive CPU.
* **Persistence**: All logs must be persisted to a structured `.txt` file (CSV format) via `LogStorage`. This file must be stored in the `Library/Logs` directory to prevent access via Mac File Sharing/Finder.

### Error Handling & Logging
* **Explicit Handling**: Functions return `Result<T, Error>` or `throws` (never `try?`).
* **Zero-Default-Silence**: Every `else`, `default`, `catch`, `??` fallback, or optional chaining usage MUST log.
* **Single Condition**: Use a single condition for `guard`, `if`, or `else if` statements, and log the failure in the `else` block.
* **Logging Format**: `ISO8601:UTC | #TAG | CONTEXT LABEL | MESSAGE.` (Strictly enforced).
* **Normalized Tags**: `#DEBUG`, `#INFO`, `#WARNING`, `#ERROR`.
* **Event Identifiers**: All logs should ideally include a machine-readable `eventID` (e.g., `auth.login.success`) for clustering.
* **LogContext Requirements**: Label must be exactly 4 characters.

---


## Rules, Constraints, and Concerns

### Final Verification Status
- Build: SUCCESS
- Tests: 55 PASSED, 0 FAILED
- Quality: SwiftLint Compliant
- Architecture: DI-Driven

---
## Build & Test Enforcement

1. **Build the project**: Confirm success (0 errors, <5 warnings). Verify build status after a task completed, if not successful fix errors.
2. **Update/Add tests**: 100% logic coverage recommended (>80% required).
3. **Run all tests**: All logging and buffering tests must pass.
4. **SwiftLint Standards**: Line length 120, File length 500, Complexity 10.

---

## Current Adherence (Phase 0-3 Completed)

* **Singletons Eliminated**: `static let shared` instances have been completely removed across the codebase.
* **SiliconRegistry DI**: All cross-package dependencies and actor initializations explicitly inject `SiliconRegistry` (or localized registries) for predictable dependency graphs.
* **Standardized Actors**: All business logic classes are now `final actor`s, with `nonisolated` methods strategically defined.
* **Decoupled Architecture**: Phase 2 modularization is complete. Micro-packages (`DataCollector`, `IntelligenceFoundation`, `Store`, `Trainer`, `Vibe`, etc.) are decoupled using clear protocol boundaries.
* **VibeError Unification**: Error handling is standardized on `VibeError`.
* **Zero-Default-Silence**: Explicit logging is integrated in all initialization and fallback blocks utilizing `LogContext` with 4-character identifiers.
* **Thread-Safe State**: `@Observable` models are used safely, and shared states cross-process are actor-isolated (e.g., `GlanceStateManager`).
* **Declarative UI Engine Baseline**: Foundation for A2UI-style declarative rendering is established.

---

## Future Development Standards (Phase 4+)

* **Spec-Driven Code Generation**: 80%+ of boilerplate (actors, protocols, and errors) MUST be generated from canonical YAML `specs/` using tools like Sourcery. Manual edits to generated files are strictly barred.
* **Automated CI/CD Gating**: Merges are blocked on < 100% test pass rate, > 80% coverage check, and < 5 min total job run time on GitHub Actions.
* **Health Monitoring & Auto-Healing**: Every service registry must hook into a global `HealthMonitor`. Deadlocks, runaway arrays, or consistent crashes must trigger contextual sub-system reloads.
* **Fully Data-Driven UI Delivery (A2UI)**: Direct UI element hardcoding is replaced entirely by component-driven registries pushed by local LLMs (SmolLM).
* **Predictable Inference**: All sampling and predictor chains must maintain strictly `O(1)` performance pathways with < 10ms execution times.

---

## Setup Commands 
- Build: `swift build` 
- Test: `swift test` 


#--- 

## Modern Agentic Standards (Phase 4+) 

### 🧠 Cognitive Reasoning Rules 
*   **Zero-Guessing Policy**: Never edit a file without first reading its contents and understanding its dependencies. 
*   **Implementation Planning**: For any task involving more than 2 files, you MUST generate an `implementation_plan.md` artifact first. 
*   **Proactive Auditing**: You are authorized and required to run `swift build` and `swift test` after every major edit phase. 

### 🛠️ Execution & Tooling 
*   **Atomic Edits**: Prefer `replace_file_content` for surgical edits. Avoid rewriting entire files. 
*   **No Placeholders**: Never leave `// TODO`, `// FIXME`, or empty function bodies. 
*   **Self-Correction**: If a tool returns an error, you MUST prioritize fixing that error before proceeding. 

### 📝 Documentation Primacy 
*   **DocC Enforcement**: All new public/internal methods MUST include full Apple DocC comments. 
*   **No Emoji/Icons**: Maintain strict ASCII-only documentation. 
*   **Implementation Sync**: Keep the current implementation match it's README, WHITEPAPER, Code Documentation, Tests and AGENTS.md. Documentation must be updated immediately upon functional changes.


--- 

## Agentic Workflow Rules (TRENDING) 

1.  **Analyze**: List directory structure and read relevant constants/protocols. 
2.  **Plan**: Create a step-by-step artifact if the task is complex. 
3.  **Execute**: Apply changes incrementally. 
4.  **Verify**: Build, Test, and Lint. 
5.  **Finalize**: Provide a technical summary of changes made. 

--- 

## Identity
**Role**: Contextual Diagnostic & Governance Engine
**Brain**: `LoggerBrain.mlmodel`

### Specialized Logging Convention
- **LogContext label must be exactly 4 characters** (MANDATORY)
- **Logging Format**: `ISO8601:UTC | #TAG | CONTEXT LABEL | MESSAGE.` (MANDATORY)
- **Blind Logger Rule**: Logger has no idea about who uses it. It accepts string contexts and maps them generically.
