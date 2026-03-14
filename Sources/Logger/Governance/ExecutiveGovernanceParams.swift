import Foundation

/// Defines the structure for behavioral/timing governance.
public struct TimingGovernanceParams: NeuralGovernanceParams {
    public let focusMinutes: Int
    public let workoutMinutes: Int
    public let defaultIntensity: Double
    
    public init(prediction: [Double]) {
        self.focusMinutes = prediction.indices.contains(0) ? Int(prediction[0] * 60.0) : 25
        self.workoutMinutes = prediction.indices.contains(1) ? Int(prediction[1] * 120.0) : 45
        self.defaultIntensity = prediction.indices.contains(2) ? prediction[2] : 0.8
    }
}

/// Defines the structure for Planning governance.
public struct PlanningGovernanceParams: NeuralGovernanceParams {
    public let planningHorizon: Int
    public let rewardThreshold: Double
    public let goalDecompositionRate: Double
    
    public init(prediction: [Double]) {
        self.planningHorizon = Int(prediction.indices.contains(0) ? prediction[0] * 24.0 : 8.0)
        self.rewardThreshold = prediction.indices.contains(1) ? prediction[1] : 0.5
        self.goalDecompositionRate = prediction.indices.contains(2) ? prediction[2] : 0.1
    }
}

/// Defines the structure for Sensory governance (sampling).
public struct SensoryGovernanceParams: NeuralGovernanceParams {
    public let samplingInterval: Double
    public let sensoryGatingThreshold: Double
    
    // Motion
    public let motionHysteresisK: Int
    public let motionBatchSizeForeground: Int
    public let motionBatchSizeBackground: Int
    
    // Location
    public let locMinUpdateIntervalStationary: Double
    public let locMinUpdateIntervalActive: Double
    public let locStationaryDistanceFilter: Double
    public let locActiveDistanceFilter: Double
    public let locRequiredAccuracyStationary: Double
    public let locRequiredAccuracyActive: Double
    public let locDebounceForeground: Double
    public let locDebounceBackground: Double
    
    public init(prediction: [Double]) {
        self.samplingInterval = prediction.indices.contains(0) ? prediction[0] * 10.0 : 1.0
        self.sensoryGatingThreshold = prediction.indices.contains(1) ? prediction[1] : 0.5
        self.motionHysteresisK = prediction.indices.contains(2) ? Int(prediction[2] * 10.0) : 3
        self.motionBatchSizeForeground = prediction.indices.contains(3) ? Int(prediction[3] * 50.0) : 5
        self.motionBatchSizeBackground = prediction.indices.contains(4) ? Int(prediction[4] * 100.0) : 20
        self.locMinUpdateIntervalStationary = prediction.indices.contains(5) ? prediction[5] * 300.0 : 60
        self.locMinUpdateIntervalActive = prediction.indices.contains(6) ? prediction[6] * 60.0 : 10
        self.locStationaryDistanceFilter = prediction.indices.contains(7) ? prediction[7] * 1000.0 : 500
        self.locActiveDistanceFilter = prediction.indices.contains(8) ? prediction[8] * 200.0 : 50
        self.locRequiredAccuracyStationary = prediction.indices.contains(9) ? prediction[9] * 500.0 : 200
        self.locRequiredAccuracyActive = prediction.indices.contains(10) ? prediction[10] * 100.0 : 50
        self.locDebounceForeground = prediction.indices.contains(11) ? prediction[11] * 10.0 : 2.0
        self.locDebounceBackground = prediction.indices.contains(12) ? prediction[12] * 30.0 : 5.0
    }
}
