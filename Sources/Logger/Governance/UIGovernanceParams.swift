//  UIGovernanceParams.swift
//  Logger
//
//  [Add description here]
import Foundation

/// Defines the structure for aesthetic/UI governance.
public struct AestheticGovernanceParams: NeuralGovernanceParams {
    public let cornerRadius: Double
    public let animationDuration: Double
    public let shadowRadius: Double

    public init(prediction: [Double]) {
        self.cornerRadius = prediction.indices.contains(0) ? prediction[0] * 50.0 : 16.0
        self.animationDuration = prediction.indices.contains(1) ? prediction[1] * 2.0 : 0.3
        self.shadowRadius = prediction.indices.contains(2) ? prediction[2] * 20.0 : 10.0
    }
}

/// Defines the structure for Glance-specific governance.
public struct GlanceGovernanceParams: NeuralGovernanceParams {
    public let updateDelayNanoseconds: UInt64
    public let batchWindow: TimeInterval
    public let maxBatchSize: Int

    public init(prediction: [Double]) {
        self.updateDelayNanoseconds = prediction.indices.contains(0) ? UInt64(prediction[0] * 1_000_000_000) : 100_000_000 // 100ms
        self.batchWindow = prediction.indices.contains(1) ? prediction[1] * 1.0 : 0.1 // 100ms
        self.maxBatchSize = prediction.indices.contains(2) ? Int(prediction[2] * 100.0) : 20
    }
}
