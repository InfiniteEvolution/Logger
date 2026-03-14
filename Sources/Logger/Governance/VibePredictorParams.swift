import Foundation

/// Defines the structure for Vibe prediction governance.
public struct VibeGovernanceParams: NeuralGovernanceParams {
    public let smoothingWindow: Int
    public let boostThreshold: Double
    
    public init(prediction: [Double]) {
        self.smoothingWindow = prediction.indices.contains(0) ? Int(prediction[0] * 20.0) : 5
        self.boostThreshold = prediction.indices.contains(1) ? prediction[1] : 0.8
    }
}

/// Defines the structure for the Vibe Predictor governance.
public struct VibePredictorGovernanceParams: NeuralGovernanceParams {
    public let confidenceThreshold: Double
    public let minimumProbability: Double
    public let cacheValidity: Double
    public let boostThreshold: Double
    public let maxSmoothingWindow: Int
    public let baseWindow: Int
    
    public init(prediction: [Double]) {
        self.confidenceThreshold = prediction.indices.contains(0) ? prediction[0] : 0.7
        self.minimumProbability = prediction.indices.contains(1) ? prediction[1] : 0.5
        self.cacheValidity = prediction.indices.contains(2) ? prediction[2] * 300.0 : 60.0
        self.boostThreshold = prediction.indices.contains(3) ? prediction[3] : 0.8
        self.maxSmoothingWindow = prediction.indices.contains(4) ? Int(prediction[4] * 20.0) : 5
        self.baseWindow = prediction.indices.contains(5) ? Int(prediction[5] * 10.0) : 3
    }
}

/// Defines the structure for Anomaly detection governance.
public struct AnomalyGovernanceParams: NeuralGovernanceParams {
    public let zScoreThreshold: Double
    public let rarityThreshold: Double
    
    public init(prediction: [Double]) {
        self.zScoreThreshold = prediction.indices.contains(0) ? prediction[0] * 5.0 : 2.5
        self.rarityThreshold = prediction.indices.contains(1) ? prediction[1] * 0.1 : 0.05
    }
}

/// Defines the structure for Pipeline optimization governance.
public struct OptimizationGovernanceParams: NeuralGovernanceParams {
    public let isActive: Bool
    public let priority: Int
    public let stressThreshold: Double
    
    public init(prediction: [Double]) {
        self.isActive = prediction.indices.contains(0) ? prediction[0] > 0.5 : true
        self.priority = prediction.indices.contains(1) ? Int(prediction[1] * 10.0) : 1
        self.stressThreshold = prediction.indices.contains(2) ? prediction[2] : 0.8
    }
}
