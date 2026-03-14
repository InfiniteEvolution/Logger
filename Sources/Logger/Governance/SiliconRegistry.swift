import Foundation

/// Centralized registry for Neural Governance.
/// Acts as a factory and cache for governors to prevent redundant model loads.

public final actor SiliconRegistry {
    
    private let governorBrain: GovernorNeuralBrain
    private let batcher: ResourceBatcher
    private let registry: NeuralResourceRegistry
    private let logger: any LoggerProxy
    public nonisolated let trainingStore: any Sendable
    public nonisolated let modelStorage: ModelStorage
    private var governors: [String: Any] = [:]
    
    public init(
        governorBrain: GovernorNeuralBrain,
        batcher: ResourceBatcher,
        registry: NeuralResourceRegistry,
        trainingStore: any Sendable,
        modelStorage: ModelStorage,
        logger: any LoggerProxy = LoggerProxyStub()
    ) {
        self.governorBrain = governorBrain
        self.batcher = batcher
        self.registry = registry
        self.trainingStore = trainingStore
        self.modelStorage = modelStorage
        self.logger = logger
    }
    
    public nonisolated func getLogger() -> any LoggerProxy { logger }
    
    public nonisolated func getGovernorBrain() -> GovernorNeuralBrain { governorBrain }
    public nonisolated func getBatcher() -> ResourceBatcher { batcher }
    public nonisolated func getResourceRegistry() -> NeuralResourceRegistry { registry }
    public nonisolated func getTrainingStore() -> any Sendable { trainingStore }
    
    /// Retrieves or creates a NeuralGovernor for the specified context.
    public func governor<T: GovernanceParams>(
        for context: String,
        modelName: String,
        bundle: Bundle? = nil
    ) -> NeuralGovernor<T> {
        let key = "\(context).\(modelName)"
        if let existing = governors[key] as? NeuralGovernor<T> {
            return existing
        }
        
        let newGovernor = NeuralGovernor<T>(
            label: String(context.prefix(4).uppercased()), 
            modelName: modelName, 
            bundle: bundle ?? .module,
            governorBrain: governorBrain,
            batcher: batcher,
            registry: registry
        )
        governors[key] = newGovernor
        return newGovernor
    }
}
