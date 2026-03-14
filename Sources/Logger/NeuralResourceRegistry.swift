import Foundation

/// Global registry for all neurally-governed resources.
/// Enables intelligence-driven eviction based on global system pressure.
public final actor NeuralResourceRegistry {
    private var governors: [String: ResourceGovernor] = [:]
    private let log = LogContext("RERE") // RE (Resource) + RE (Registry)
    private var isCascading = false
    
    public init() {}

    
    /// Registers a governor for a specific resource.
    public func register(_ governor: ResourceGovernor, for resourceID: String) {
        governors[resourceID] = governor
        log.info("Registered governor for resource: \(resourceID)")
    }
    
    /// Unregisters a governor.
    public func unregister(resourceID: String) {
        governors.removeValue(forKey: resourceID)
        log.info("Unregistered governor for resource: \(resourceID)")
    }
    
    /// Returns all registered resource IDs.
    public func activeResources() -> [String] {
        Array(governors.keys)
    }
    
    /// Suggests an eviction candidate based on the lowest relevance score.
    /// This is called when a new resource request detects high memory pressure.
    public func suggestEviction() async -> String? {
        var lowestScore: Double = 1.1
        var candidate: String?
        
        for (id, gov) in governors {
            let score = await gov.currentRelevanceScore()
            if score < lowestScore {
                lowestScore = score
                candidate = id
            }
        }
        
        return candidate
    }
    
    /// Triggers an intelligence-driven re-evaluation of all loaded resources.
    /// Used for "Event-Driven Cascade" after any resource interaction or system event.
    public func cascadeReevaluation(triggeredBy event: ResourceEvent) async {
        // Re-entrancy guard: prevent infinite cascade loops
        guard !isCascading else {
            log.info("Cascade already in progress. Skipping re-entrant call.")
            return
        }
        isCascading = true
        defer { isCascading = false }
        
        log.info("Starting intelligence-driven cascade for event: \(event)")
        
        // Snapshot governors to avoid mutation during iteration
        let snapshot = Array(governors.values)
        
        // Parallel re-evaluation for maximum efficiency
        await withTaskGroup(of: Void.self) { group in
            for gov in snapshot {
                group.addTask {
                    await gov.evaluateEvent(named: .init(event.description))
                }
            }
        }
    }
    
    /// Triggers an immediate release of the specified resource.
    public func forceEvict(_ resourceID: String) async {
        guard let gov = governors[resourceID] else {
            log.warning("Cannot evict unknown resource: \(resourceID)")
            return
        }
        await gov.forceRelease()
    }
}
