//  ResourceGovernor.swift
//  Logger
//
//  Unified Resource Governance for the "Zero-Waste Lifecycle".

import Foundation

/// Unified Resource Governance for the "Zero-Waste Lifecycle".
///
/// Tracks usage via system events and automatically releases resources using ML-based intelligence.
/// This actor ensures optimal memory and energy usage by predicting when a resource is no
/// longer needed by the user.
public final actor ResourceGovernor {
    // MARK: - 1. Dependencies
    internal let label: String
    private let log: LogContext
    private let resourceID: Double
    private let onRelease: @Sendable () async -> Void
    private let brain: GovernorNeuralBrain
    private let batcher: ResourceBatcher
    private let registry: NeuralResourceRegistry

    // MARK: - 2. Internal State
    private var lastUsed: Date = .distantPast
    private var activityCount: Int = 0
    private var lastEvent: ResourceEvent = .unknown
    internal var observers: [NSObjectProtocol] = []

    // MARK: - 3. Initialization
    
    /// Initializes a new resource governor with the specified identifier and dependencies.
    ///
    /// - Parameters:
    ///   - label: A unique identifier for the resource being governed (e.g. "Brain").
    ///   - brain: The neural brain used for relevance evaluation.
    ///   - batcher: A coordinating batcher for system-wide resource management.
    ///   - registry: The registry used for lifecycle event coordination.
    ///   - onRelease: A closure that is executed when the resource is released.
    public init(
        label: String,
        brain: GovernorNeuralBrain,
        batcher: ResourceBatcher,
        registry: NeuralResourceRegistry,
        onRelease: @Sendable @escaping () async -> Void
    ) {
        self.label = label
        self.log = LogContext("REGO")
        self.brain = brain
        self.batcher = batcher
        self.registry = registry
        self.resourceID = Double(abs(label.hashValue) % 1000)
        self.onRelease = onRelease

        Task { [weak self] in
            guard let self else {
                return
            }
            await registry.register(self, for: label)
            await setupEventObservers()
        }
    }

    // MARK: - 4. Protocol Implementation
    // (Implementations in extensions)

    // MARK: - 5. Internal Helpers
    
    /// Updates the internal temporal marker for the resource.
    ///
    /// Calling this method indicates that the resource is currently active and
    /// resets the idle timer used for prediction.
    public func touch() {
        lastUsed = Date()
        activityCount += 1
    }

    /// Evaluates the current predicted relevance of the resource.
    ///
    /// - Returns: A normalized score (0.0 - 1.0) indicating the predicted resource value.
    public func currentRelevanceScore() async -> Double {
        let interArrival = Date().timeIntervalSince(lastUsed)
        let frequency = Double(activityCount) / 300.0

        return await brain.evaluate(
            resourceID: resourceID,
            eventID: lastEvent.rawValue,
            frequency: min(1.0, frequency),
            interArrivalTime: min(1.0, interArrival / 600.0),
            systemPressure: getSystemPressure()
        )
    }

    /// Explicitly releases the governed resource.
    ///
    /// This bypasses neural prediction and immediately executes the release closure.
    public func forceRelease() async {
        await onRelease()
        await logRecord(outcome: 0)
    }

    /// Starts the resource governance sampling.
    public func start() {
        log.info("Resource governance started for \(label)")
    }
    
    /// Stops the resource governance sampling.
    public func stop() {
        log.info("Resource governance stopped for \(label)")
    }

    internal func getSystemPressure() -> Double {
        let thermal = ProcessInfo.processInfo.thermalState
        switch thermal {
        case .nominal: return 0.1
        case .fair: return 0.3
        case .serious: return 0.7
        case .critical: return 1.0
        @unknown default:
            log.warning("REGO: Unknown thermal state encountered (\(thermal)). Defaulting to 0.5 pressure.")
            return 0.5
        }
    }

    internal func log_info(_ m: String) { log.info(m) }
    internal func label_get() -> String { label }
    internal func resourceID_get() -> Double { resourceID }
    internal func lastEvent_get() -> ResourceEvent { lastEvent }
    internal func lastEvent_set(_ e: ResourceEvent) { lastEvent = e }
    internal func lastUsed_get() -> Date { lastUsed }
    internal func activityCount_get() -> Int { activityCount }
    internal func activityCount_reset() { activityCount = 0 }
    internal func observers_append(_ o: NSObjectProtocol) { observers.append(o) }
    internal func onRelease_call() async { await onRelease() }
    internal func batcher_get() -> ResourceBatcher { batcher }

    // MARK: - 6. nonisolated Accessors
    // (None currently defined)
}
