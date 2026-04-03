# AGENTS.md: Logger

Applies Root Agent Constitution: This document extends and adheres to the repository root Agent Constitution (/AGENTS.md). All constraints and rules from the root are in effect for this package.

## Platform & Architecture Constraints

* **Target Platform:** iOS 26 only
* All app targets and Swift Package Manager (SPM) modules are **platform-specific to iOS 26**
* **No cross-platform support is required or allowed**
* **Size Limit:** <1MB Total Package Size (Strict Enforcement)

## Documentation & Code Formatting

* No emoji, symbols, or icons in code, comments, or documentation files
* Use plain ASCII text only
* All public types, methods, and properties must be documented using **Apple DocC style**
* **Import Hygiene**: Remove all unwanted, unused, or duplicate imports.
* **File Headers**: Maintain a standardized format for all file headers across the project.
* **White Space**: Clean up all unwanted white space and redundant new lines.

---

## Global Architecture Standards

* **Layering**:
  * Logger is a foundational **Infrastructure** package.
  * It has no dependencies on domain or presentation code.
* **Single Responsibility**:
  * Structured logging and metrics for the entire platform.
* **Deterministic Behavior**:
  * Logger behavior is predictable and deterministic.

---

## Code Quality Standards (Phase 0-3+)

### Structural Concurrency (Phase 1+)
* **Actor Isolation**: All mutable state must reside in actors.
* **Await Rule**: Cross-isolation calls require `await`.
* **Nonisolated**: `nonisolated` members do NOT require `await`.
* **Final Actors**: All actors must be `final`.
* **No @Observable on Actors**: `@Observable` macro NOT allowed on actors.
* **Implicit Self**: After `guard let self else { return }`, remove explicit `self.` usage below this guard if possible.
* **Minimize Optionals**: Favor non-optional types and exhaustive handling.

### Dependency Injection (Phase 2+)
* **Mandatory DI**: Use Dependency Injection for all components.
* **No Singletons**: `static let shared` is strictly prohibited.

### Complexity & Performance (MANDATORY)
* **O(1) Requirement**: ALL logging operations MUST be O(1) (latency < 1ms).
* **Efficiency**: Must not block the calling thread or consume excessive CPU.

### Error Handling & Logging
* **Explicit Handling**: Functions return `Result<T, Error>` or `throws VibeError`.
* **Zero-Default-Silence**: Every `else`, `default`, `catch`, `??` fallback, or optional chaining usage MUST log.
* **Single Condition**: Use a single condition for `guard`, `if`, or `else if` statements, and log the failure in the `else` block.
* **Logging Format**: `Time | Context<Absolute 4 Char> | #ERROR OR #INFO OR #WARNING | Message` (Strictly enforced).
* **LogContext Requirements**: Label must be exactly 4 characters.

---

## Setup Commands 
- Build: `swift build` 
- Test: `swift test` 

--- 

## Modern Agentic Standards (Phase 4+) 

### 🧠 Cognitive Reasoning Rules 
*   **Zero-Guessing Policy**: Never edit a file without first reading its contents and understanding its dependencies. 
*   **Implementation Planning**: For any task involving more than 2 files, you MUST generate an `implementation_plan.md` artifact first. 
*   **Proactive Auditing**: You are authorized and required to run `swift build` and `swift test` after every major edit phase. 

--- 

## Identity
- **Role**: Foundational Diagnostic Engine
- **Responsibility**: Providing structured recording of system events and task lifecycles.
