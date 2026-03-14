@preconcurrency import CoreML
import Foundation

/// A reusable base for Neural Brains to reduce binary bloat.
///
/// As an actor, all member access from outside requires `await` (actor hop).
/// `MLModel.prediction(from:)` is itself async and requires `await` independently.
public final actor BaseNeuralBrain {
    private let log: LogContext
    private nonisolated(unsafe) var model: MLModel?
    private var isLoaded = false
    private let modelName: String
    private let modelBundle: Bundle
    private var governor: ResourceGovernor?
    
    private let governorBrain: GovernorNeuralBrain?
    private let batcher: ResourceBatcher?
    private let registry: NeuralResourceRegistry?
    
    public init(
        label: String, 
        modelName: String, 
        bundle: Bundle? = nil,
        governorBrain: GovernorNeuralBrain? = nil,
        batcher: ResourceBatcher? = nil,
        registry: NeuralResourceRegistry? = nil
    ) {
        self.log = LogContext(label)
        self.modelName = modelName
        self.modelBundle = bundle ?? .module
        self.governorBrain = governorBrain
        self.batcher = batcher
        self.registry = registry
    }
    
    public func ensureModelLoaded() async throws {
        if governor == nil, let gBrain = governorBrain, let gBatcher = batcher, let gRegistry = registry {
            let labelCopy = "Brain.\(self.modelName)"
            self.governor = ResourceGovernor(
                label: labelCopy,
                brain: gBrain,
                batcher: gBatcher,
                registry: gRegistry,
                onRelease: { [weak self] in
                    await self?.unload()
                }
            )
            await governor?.start()
        }
        await governor?.touch()
        if isLoaded { return }
        
        // Resolve model URL
        let compiledExtension = "mlmodelc"
        var modelURL = modelBundle.url(forResource: modelName, withExtension: compiledExtension)
        
        // Fallback to Bundle.module if requested bundle doesn't have it (common in SPM tests)
        if modelURL == nil && modelBundle != .module {
            modelURL = Bundle.module.url(forResource: modelName, withExtension: compiledExtension)
        }
        
        guard let finalURL = modelURL else {
            log.error("Model \(modelName) missing from both provided bundle and Logger.module")
            throw NSError(domain: "BaseNeuralBrain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model \(modelName) missing"])
        }
        
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        // Use synchronous init for better compatibility in SwiftPM environments
        model = try MLModel(contentsOf: finalURL, configuration: config)
        isLoaded = true
        log.info("Loaded \(modelName)")
    }
    
    /// Run a prediction using the loaded ML model.
    ///
    /// `model.prediction(from:)` is async (MLModel API) and requires `await`.
    public func prediction(from input: SendableFeatureProvider) async throws -> SendableFeatureProvider {
        try await ensureModelLoaded()
        guard let model = model else {
            log.error("Model not loaded after ensureModelLoaded")
            throw NSError(domain: "BaseNeuralBrain", code: 2, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        let result = try await model.prediction(from: input.provider)
        await governor?.touch()
        return SendableFeatureProvider(result)
    }
    
    public func unload() {
        model = nil
        isLoaded = false
        log.info("Unloaded \(modelName)")
    }
}
