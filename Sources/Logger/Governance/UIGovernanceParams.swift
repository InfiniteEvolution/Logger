//  UIGovernanceParams.swift
//  Logger
//
//  Defines parameters for model-driven UI and Glance governance.

import Foundation

/// Defines the structure for model-driven aesthetic/UI governance using model-driven predictions.
///
/// This structure provides thresholds and values for basic UI properties such as corner radius
/// and animation timing, derived from neural brain outputs.
public struct AestheticGovernanceParams: NeuralGovernanceParams {
    /// The optimal corner radius predicted for the current vibe.
    public let cornerRadius: Double
    /// The recommended animation duration for transitions.
    public let animationDuration: Double
    /// The shadow radius to apply to standard containers.
    public let shadowRadius: Double

    /// Initializes governance parameters from a raw neural prediction.
    ///
    /// - Parameter prediction: An array of normalized predictions from the CoreML model.
    public init(prediction: [Double]) {
        if prediction.indices.contains(0) {
            let raw = prediction[0]
            // If already > 1, assume it's a raw pixel value; otherwise, it's a probability
            self.cornerRadius = (raw > 1.0) ? min(raw, 100.0) : min(raw * 50.0, 50.0)
        } else {
            self.cornerRadius = 16.0
        }
        self.animationDuration = prediction.indices.contains(1) ? min(prediction[1] * 2.0, 2.0) : 0.3
        self.shadowRadius = prediction.indices.contains(2) ? min(prediction[2] * 20.0, 40.0) : 10.0
    }
}

/// Defines the structure for Glance-specific diagnostic and update governance.
///
/// This structure controls the sampling and batching frequency for Glance-related
/// telemetry, ensuring performance targets (O(1)) are maintained.
public struct GlanceGovernanceParams: NeuralGovernanceParams {
    /// The nanosecond delay between incremental telemetry updates.
    public let updateDelayNanoseconds: UInt64
    /// The temporal window for batching multiple telemetry events.
    public let batchWindow: TimeInterval
    /// The maximum number of events to include in a single batch.
    public let maxBatchSize: Int

    /// Initializes Glance governance parameters from a raw neural prediction.
    ///
    /// - Parameter prediction: An array of normalized predictions from the CoreML model.
    public init(prediction: [Double]) {
        self.updateDelayNanoseconds = prediction.indices.contains(0) ? UInt64(prediction[0] * 1_000_000_000) : 100_000_000 // 100ms
        self.batchWindow = prediction.indices.contains(1) ? prediction[1] * 1.0 : 0.1 // 100ms
        self.maxBatchSize = prediction.indices.contains(2) ? Int(prediction[2] * 100.0) : 20
    }
}
