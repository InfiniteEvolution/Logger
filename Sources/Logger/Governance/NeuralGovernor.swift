//  NeuralGovernor.swift
//  Logger
//
//  [Add description here]
import Foundation
import CoreML

/// Protocol for governance parameters parsed from a string-encoded label.
public protocol GovernanceParams: Sendable {
    static func parse(_ label: String) -> Self
    static var defaultParams: Self { get }
}

/// Protocol for the new Zero-Constants governance model using multi-array predictions.
public protocol NeuralGovernanceParams: GovernanceParams {
    /// Initialize from a raw array of double predictions.
    init(prediction: [Double])
}

extension NeuralGovernanceParams {
    public static func parse(_ label: String) -> Self {
        // Fallback implementation for label-based parsing
        let components = label.split(separator: ":").compactMap { Double($0) }
        return Self(prediction: components)
    }
    public static var defaultParams: Self { Self(prediction: []) }
}

/// A generic actor for Neural Governance.
/// Provides a type-safe wrapper around a CoreML model for predicting and updating logic thresholds.
public final actor NeuralGovernor<T: GovernanceParams> {
    private let base: BaseNeuralBrain
    private let log: LogContext
    private let inputName: String
    private let inputShape: [NSNumber]

    public init(
        label: String,
        modelName: String,
        bundle: Bundle? = nil,
        inputName: String = "features",
        inputShape: [Int] = [4],
        governorBrain: GovernorNeuralBrain,
        batcher: ResourceBatcher,
        registry: NeuralResourceRegistry
    ) {
        self.log = LogContext(label)
        self.inputName = inputName
        self.inputShape = inputShape.map { NSNumber(value: $0) }
        self.base = BaseNeuralBrain(
            label: label,
            modelName: modelName,
            bundle: bundle ?? .module,
            governorBrain: governorBrain,
            batcher: batcher,
            registry: registry
        )
    }

    /// Predicts the optimal governance parameters based on input features.
    /// - Parameter features: An array of doubles representing the current context.
    /// - Returns: High-level parameters derived from the Silicon prediction.
    public func decide(features: [Double]) async -> T {
        do {
            let multiArray = try MLMultiArray(shape: inputShape, dataType: .double)
            for i in 0..<inputShape.reduce(1, { $0 * $1.intValue }) {
                multiArray[i] = NSNumber(value: i < features.count ? features[i] : 0.0)
            }

            let provider = try MLDictionaryFeatureProvider(dictionary: [inputName: MLFeatureValue(multiArray: multiArray)])
            let result = try await base.prediction(from: SendableFeatureProvider(provider))

            // Priority 1: New multi-array prediction interface
            if let probs = result.provider.featureValue(for: "governance_probs")?.multiArrayValue {
                var doubleArray = Array(repeating: 0.0, count: probs.count)
                for i in 0..<probs.count { doubleArray[i] = probs[i].doubleValue }
                if let type = T.self as? any NeuralGovernanceParams.Type {
                    return type.init(prediction: doubleArray) as! T
                }
            }

            // Priority 2: Old string-encoded label interface
            if let label = result.provider.featureValue(for: "governance_params")?.stringValue {
                return T.parse(label)
            }

            return T.defaultParams
        } catch {
            log.warning("decide failed, using default params: \(error)")
            return T.defaultParams
        }
    }
}
