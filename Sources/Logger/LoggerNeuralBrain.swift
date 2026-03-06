@preconcurrency import CoreML
import Foundation

/// The validated ML brain for the Logger.
public actor LoggerNeuralBrain {
    private let log = LogContext("LONB")
    private let base: BaseNeuralBrain
    
    public init() {
        self.base = BaseNeuralBrain(label: "LOLN", modelName: "LoggerBrain")
    }
    
    public func shouldLog(features: MLMultiArray) async -> Bool {
        do {
            let input = try MLDictionaryFeatureProvider(dictionary: ["log_features": MLFeatureValue(multiArray: features)])
            let result = try await base.prediction(from: SendableFeatureProvider(input))
            let output = result.provider
            return (output.featureValue(for: "should_log")?.multiArrayValue?[0].doubleValue ?? 1.0) > 0.5
        } catch let predError {
            log.error("shouldLog failed: \(predError)")
            return true
        }
    }
    
    public func unload() async {
        await base.unload()
    }
}
