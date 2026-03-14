# Logger: The Diagnostic Nervous System

The `Logger` package is the diagnostic backbone of the Vibe Project. It provides high-performance, context-aware structured logging used for system governance, metrics, and autonomous self-healing.

## 🛠️ Implementation Deep-Dive

### 🏷️ 4-Character Context Labels
To ensure O(1) parsing and high diagnostic saliency, every log event MUST include a **4-character context identifier**. This allow developers and agents to immediately filter for specific domains:
- `VBPR`: Vibe Predictor (Inference).
- `STOR`: Store / Persistence.
- `STEM`: System Brainstem (Core Lifecycle).
- `CERE`: Cerebellum (Coordination).
- `A2UI`: Agentic UI transitions.

### 🏛️ Log Architecture
- **Thread-Safety**: The `LogGovernor` is a `final actor`, ensuring that logging never blocks the calling thread or contributes to data races.
- **OSLog Integration**: Leverages the native Apple `os_log` system for efficient kernel-level buffering and console integration.
- **Privacy Gating**: Automatic redaction of potentially sensitive telemetry data in production builds.

### 📊 Metric Collection
Logger isn't just for text; it tracks system **Vital Signs**:
- **Latency Snapshots**: Tracking inference and sampling times.
- **Throughput Metrics**: Monitoring sensor update frequencies.
- **Memory Pressure**: Logging events that trigger elective neural pruning in the `Store`.

---

## 📖 How to Use

### 🧬 Dependency Injection
Strictly use the `SiliconRegistry`.
```swift
let logger = try registry.resolve(LoggerProtocol.self)
logger.info("Initializing sensory array", context: "SENS")
```

### 📝 Standardized Fallbacks ("Zero-Silence")
Every `??` or `default` case MUST log a warning.
```swift
let value = try? await store.read(key)
if value == nil {
    logger.warn("Cache miss for critical key", context: "STOR")
}
```

---

## 🔮 Future Roadmap (Phase 4+)

- **[ ] Neural Log Prioritization**: Using a small model to determine which logs are "High Entropy" and should be persisted vs discarded.
- **[ ] JSON Structural Export**: Automated generation of parseable diagnostic reports for CI/CD audit trails.
- **[ ] Health-Triggered Verbosity**: Dynamically increasing log level during detected system-instability (e.g., thermal throttling).

---

*“To see the error is the first step towards rectifying the prediction.”*
