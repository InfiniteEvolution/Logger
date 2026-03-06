import Foundation

/// Unified Resource Governance for the "Zero-Waste Lifecycle".
/// Tracks usage via system events and automatically releases resources using ML-based intelligence.
public actor ResourceGovernor {
    private var lastUsed: Date = .distantPast
    private var activityCount: Int = 0
    private var lastEvent: ResourceEvent = .unknown
    
    private let label: String
    private let log: LogContext
    private let resourceID: Double
    private let onRelease: @Sendable () async -> Void
    private let brain = GovernorNeuralBrain.shared
    private let batcher = ResourceBatcher.shared
    private let registry = NeuralResourceRegistry.shared
    
    private var observers: [NSObjectProtocol] = []
    
    /// Initializes a new intelligent governor.
    /// - Parameters:
    ///   - label: A descriptive label for logging.
    ///   - onRelease: The closure to execute when the resource should be released.
    public init(
        label: String,
        onRelease: @Sendable @escaping () async -> Void
    ) {
        self.label = label
        self.log = LogContext("REGO")
        // Deterministic ID from label for k-NN consistency
        self.resourceID = Double(abs(label.hashValue) % 1000)
        self.onRelease = onRelease
        
        Task { [weak self] in
            guard let self = self else { return }
            await registry.register(self, for: label)
            await setupEventObservers()
        }
    }
    
    private func setupEventObservers() {
        let events: [Notification.Name] = [
            .init("vibeDidChange"),
            .init("motionDidChange"),
            .init("locationDidChange"),
            .init("biometricDidChange"),
            ProcessInfo.thermalStateDidChangeNotification
        ]
        
        for name in events {
            let observer = NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] note in
                let noteName = note.name // Extract Sendable data
                Task { [weak self] in
                    await self?.evaluateEvent(named: noteName)
                }
            }
            observers.append(observer)
        }
    }
    
    /// Records an interaction with the resource.
    public func touch() {
        lastUsed = Date()
        activityCount += 1
    }
    
    /// Evaluation Score for the global registry (0.0 to 1.0)
    public func currentRelevanceScore() async -> Double {
        let interArrival = Date().timeIntervalSince(lastUsed)
        let frequency = Double(activityCount) / 300.0 // Normalize to 5 min window
        
        return await brain.evaluate(
            resourceID: resourceID,
            eventID: lastEvent.rawValue,
            frequency: min(1.0, frequency),
            interArrivalTime: min(1.0, interArrival / 600.0),
            systemPressure: getSystemPressure()
        )
    }
    
    /// Forces an immediate release of the governed resource.
    public func forceRelease() async {
        await onRelease()
        await logRecord(outcome: 0) // Record eviction as result of decision
    }
    
    /// Starts the background monitoring task (Legacy compatibility, now a no-op).
    public func start() {}
    
    /// Stops the background monitoring task (Legacy compatibility, now a no-op).
    public func stop() {}
    
    /// Triggered by global registry or local events
    internal func evaluateEvent(named notificationName: Notification.Name) async {
        let event = ResourceEvent.from(notificationName: notificationName)
        self.lastEvent = event
        
        let score = await currentRelevanceScore()
        
        if score < 0.5 {
            log.info("Intelligence Suggests Eviction for \(label). Score: \(score)")
            await onRelease()
            await logRecord(outcome: 0)
        } else {
            await logRecord(outcome: 1) // Recorded as a "Keep" decision
        }
        
        // Reset frequency bucket periodically
        if Date().timeIntervalSince(lastUsed) > 300 {
            activityCount = 0
        }
    }
    
    private func logRecord(outcome: Int64) async {
        let interArrival = Date().timeIntervalSince(lastUsed)
        let frequency = Double(activityCount) / 300.0
        
        await batcher.record(
            resourceID: resourceID,
            eventID: lastEvent.rawValue,
            frequency: min(1.0, frequency),
            interArrivalTime: min(1.0, interArrival / 600.0),
            systemPressure: getSystemPressure(),
            outcome: outcome
        )
    }
    
    private func getSystemPressure() -> Double {
        let thermal = ProcessInfo.processInfo.thermalState
        switch thermal {
        case .nominal: return 0.1
        case .fair: return 0.3
        case .serious: return 0.7
        case .critical: return 1.0
        @unknown default:
            log.warning("Unknown thermal state encountered")
            return 0.5
        }
    }
    
    deinit {
        let labelCopy = self.label
        Task {
            await NeuralResourceRegistry.shared.unregister(resourceID: labelCopy)
        }
    }
}
