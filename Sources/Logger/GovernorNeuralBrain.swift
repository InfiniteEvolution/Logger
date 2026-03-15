//  GovernorNeuralBrain.swift
//  Logger
//
//  High-level neural engine for system regulation and resource oversight.
import Foundation
@preconcurrency import CoreML

/// Intelligence wrapper for the Resource Governor.
/// Uses a k-NN model to decide on resource lifecycle.
public final actor GovernorNeuralBrain {
    private let log = LogContext("GNBR")

    private let base: BaseNeuralBrain

    public init() {
        self.base = BaseNeuralBrain(label: "GOBR", modelName: "Governor")
    }

    public func evaluate(
        resourceID: Double,
        eventID: Double,
        frequency: Double,
        interArrivalTime: Double,
        systemPressure: Double
    ) async -> Double {
        do {
            let features = try MLMultiArray(shape: [5], dataType: .double)
            features[0] = NSNumber(value: resourceID)
            features[1] = NSNumber(value: eventID)
            features[2] = NSNumber(value: frequency)
            features[3] = NSNumber(value: interArrivalTime)
            features[4] = NSNumber(value: systemPressure)

            let provider = try MLDictionaryFeatureProvider(dictionary: ["features": MLFeatureValue(multiArray: features)])
            let result = try await base.prediction(from: SendableFeatureProvider(provider))
            let output = result.provider
            return output.featureValue(for: "keepAlive")?.doubleValue ?? 1.0
        } catch let evalError {
            log.error("evaluate failed: \(evalError)")
            return 1.0
        }
    }

    /// Model training not available on iOS. This is a no-op for iOS 26 target.
    public func tune(with samples: [ResourceBatcher.ResourceSample]) async throws {
        log.info("tune: model training not available on iOS")
    }
}
