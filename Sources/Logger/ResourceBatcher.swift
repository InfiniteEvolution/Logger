import Foundation
import CoreML

/// Collects and batches resource telemetry for on-device k-NN training.
public final actor ResourceBatcher {
    private var samples: [ResourceSample] = []
    private let maxBatchSize = 10
    private let log = LogContext("REBA") // RE (Resource) + BA (Batcher)
    private let brain: GovernorNeuralBrain
    
    public init(brain: GovernorNeuralBrain) {
        self.brain = brain
    }

    
public struct ResourceSample: Sendable {
        let resourceID: Double
        let eventID: Double
        let frequency: Double
        let interArrivalTime: Double
        let systemPressure: Double
        let label: Int64
    }
    
    /// Records a new sample for the governor's brain.
    public func record(
        resourceID: Double,
        eventID: Double,
        frequency: Double,
        interArrivalTime: Double,
        systemPressure: Double,
        outcome: Int64
    ) {
        let sample = ResourceSample(
            resourceID: resourceID,
            eventID: eventID,
            frequency: frequency,
            interArrivalTime: interArrivalTime,
            systemPressure: systemPressure,
            label: outcome
        )
        samples.append(sample)
        
        if samples.count >= maxBatchSize {
            Task { await flush() }
        }
    }
    
    private func flush() async {
        let batch = samples
        samples.removeAll()
        
        log.info("Batching \(batch.count) samples for Governor tuning.")
        
        do {
            try await brain.tune(with: batch)
        } catch let tuneError {
            log.error("Failed to tune Governor: \(tuneError)")
        }
    }

}
