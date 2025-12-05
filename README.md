# 📝 L O G G E R

### The Console of Canvas.

![Platform](https://img.shields.io/badge/Platform-iOS_18-black)
![Performance](https://img.shields.io/badge/Overhead-Zero-green)
![Thread Safety](https://img.shields.io/badge/Concurrency-Actor_Isolated-orange)

---

## � Contents
- [Overview](#-overview)
- [Features](#️-features)
- [Usage](#-usage)
- [Navigation](#-navigation)

---

## �📖 Overview
**Logger** is a lightweight, thread-safe diagnostics utility wrapping Apple's `OSLog`. It provides structured logging without the performance penalty of `print()`.

---

## ⚡️ Features
-   **Subsystem Partitioning**: Automatically categorizes logs by Package (`com.canvas.store`, `com.canvas.trainer`).
-   **Privacy Redaction**: Respects OS-level privacy settings for sensitive data.
-   **Zero Overhead**: Compiled out in Release builds where appropriate.

---

## 🚀 Usage

```swift
import Logger

let logger = Logger(subsystem: "com.canvas.ui", category: "View")
logger.debug("View loaded", metadata: ["time": 0.5])
```

---

## 🧭 Navigation

| Package | Role |
| :--- | :--- |
| [**Canvas**](../Canvas/README.md) | The App |
| [**DataCollector**](../DataCollector/README.md) | The Senses |
| [**Trainer**](../Trainer/README.md) | The Brain |
| [**Store**](../Store/README.md) | The Memory |
| **Logger** *(You Are Here)* | The Console |

---
*Silence is golden. Logs are silver.*
