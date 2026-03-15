//  CoreGovernanceParams.swift
//  Logger
//
//  [Add description here]
import Foundation

/// Defines the structure for sync-related governance.
public struct SyncGovernanceParams: NeuralGovernanceParams {
    public let syncThreshold: Double
    public let bufferMinutes: Int

    public init(prediction: [Double]) {
        self.syncThreshold = prediction.indices.contains(0) ? prediction[0] : 0.5
        self.bufferMinutes = prediction.indices.contains(1) ? Int(prediction[1] * 60.0) : 5
    }
}

/// Defines the structure for Persistence governance (batching).
public struct PersistenceGovernanceParams: NeuralGovernanceParams {
    public let batchSize: Int
    public let batchInterval: Double
    public let salienceThreshold: Double

    public init(prediction: [Double]) {
        self.batchSize = prediction.indices.contains(0) ? Int(prediction[0] * 256.0) : 64
        self.batchInterval = prediction.indices.contains(1) ? prediction[1] * 600.0 : 300.0
        self.salienceThreshold = prediction.indices.contains(2) ? prediction[2] : 0.5
    }
}

/// Defines the structure for Energy governance (throttling).
public struct EnergyGovernanceParams: NeuralGovernanceParams {
    public let multiplier: Double
    public let criticalMultiplierThreshold: Double

    public init(prediction: [Double]) {
        self.multiplier = prediction.indices.contains(0) ? prediction[0] * 5.0 : 1.0
        self.criticalMultiplierThreshold = prediction.indices.contains(1) ? prediction[1] * 10.0 : 2.0
    }
}
