import Foundation
@preconcurrency import CoreML

/// Intelligence wrapper for the Resource Governor.
/// Uses a k-NN model to decide on resource lifecycle.
public actor GovernorNeuralBrain {
    private let log = LogContext("GNBR")
    public static let shared = GovernorNeuralBrain()
    
    private let base: BaseNeuralBrain
    
    private init() {
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
    
    /// Tunes the k-NN model on-device with batched samples.
    public func tune(with samples: [ResourceBatcher.ResourceSample]) async throws {
        guard let modelURL = Bundle.module.url(forResource: "Governor", withExtension: "mlmodelc") else {
            log.warning("tune: modelURL is nil/unavailable")
            return
        }
        let trainingData = try prepareTrainingData(from: samples)
        
        let brainBase = self.base
        let updateTask = try MLUpdateTask(
            forModelAt: modelURL,
            trainingData: trainingData,
            configuration: nil) { context in
                try? context.model.write(to: modelURL)
                // For singleton, we ideally want to reload the model in base after update
                Task { await brainBase.unload() }
            }
        updateTask.resume()
    }
    
    private func prepareTrainingData(from samples: [ResourceBatcher.ResourceSample]) throws -> MLBatchProvider {
        var featureProviders: [MLFeatureProvider] = []
        for sample in samples {
            let multi = try MLMultiArray(shape: [5], dataType: .double)
            multi[0] = NSNumber(value: sample.resourceID)
            multi[1] = NSNumber(value: sample.eventID)
            multi[2] = NSNumber(value: sample.frequency)
            multi[3] = NSNumber(value: sample.interArrivalTime)
            multi[4] = NSNumber(value: sample.systemPressure)
            
            let provider = try MLDictionaryFeatureProvider(dictionary: [
                "features": MLFeatureValue(multiArray: multi),
                "keepAlive": MLFeatureValue(int64: sample.label)
            ])
            featureProviders.append(provider)
        }
        return MLArrayBatchProvider(array: featureProviders)
    }
}
