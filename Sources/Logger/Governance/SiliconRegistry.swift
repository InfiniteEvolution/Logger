//  SiliconRegistry.swift
//  Logger
//
//  Centralized registry for Neural Governance and resource coordination.

import Foundation

/// Centralized registry for Neural Governance.
///
/// This registry acts as a factory and cache for neural governors, ensuring that
/// model loads are performant and that the system maintains O(1) decision capabilities.
/// It is the primary dependency injection point for the platform.
public final actor SiliconRegistry {
    private let governorBrain: GovernorNeuralBrain
    private let batcher: ResourceBatcher
    private let registry: NeuralResourceRegistry
    private let logger: any LoggerProxy
    
    /// The shared training store for reinforcement learning updates.
    public nonisolated let trainingStore: any Sendable
    /// The model storage for managing on-device CoreML artifacts.
    public nonisolated let modelStorage: ModelStorage
    private var governors: [String: Any] = [:]

    /// Initializes the silicon registry with essential platform dependencies.
    ///
    /// - Parameters:
    ///   - governorBrain: The central decision brain.
    ///   - batcher: The system-wide resource batcher.
    ///   - registry: The neural resource registry.
    ///   - trainingStore: Store for recording model training samples.
    ///   - modelStorage: Manager for ML model persistence.
    ///   - logger: Diagnostic recording proxy.
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

    /// Returns the diagnostic recording proxy associated with this registry.
    public nonisolated func getLogger() -> any LoggerProxy { logger }

    /// Returns the central governor brain.
    public nonisolated func getGovernorBrain() -> GovernorNeuralBrain { governorBrain }
    
    /// Returns the system-wide resource batcher.
    public nonisolated func getBatcher() -> ResourceBatcher { batcher }
    
    /// Returns the internal neural resource registry.
    public nonisolated func getResourceRegistry() -> NeuralResourceRegistry { registry }
    
    /// Returns the shared training store.
    public nonisolated func getTrainingStore() -> any Sendable { trainingStore }

    /// Returns the URL for a compiled ML model in the Logger bundle.
    ///
    /// - Parameters:
    ///   - name: The name of the model.
    ///   - ext: The file extension (e.g., "mlmodelc").
    /// - Returns: The file URL if found, nil otherwise.
    public nonisolated func modelURL(for name: String, withExtension ext: String = "mlmodelc") -> URL? {
        Bundle.module.url(forResource: name, withExtension: ext)
    }

    /// Retrieves or creates a NeuralGovernor for the specified context and model.
    ///
    /// This method performs an O(1) lookup in the local cache or initializes a new
    /// governor if one does not exist for the given context.
    ///
    /// - Parameters:
    ///   - context: The functional context (e.g., "Aesthetic").
    ///   - modelName: The name of the CoreML model to load.
    ///   - bundle: Optional bundle for resource lookup, defaults to .module.
    ///   - inputName: Name of the input feature in the ML model, defaults to "features".
    ///   - inputShape: Required input shape of the ML model, defaults to [4].
    /// - Returns: A typed governor instance for the specified parameters.
    public func governor<T: GovernanceParams>(
        for context: String,
        modelName: String,
        bundle: Bundle? = nil,
        inputName: String = "features",
        inputShape: [Int] = [4]
    ) -> NeuralGovernor<T> {
        let key = "\(context).\(modelName)"
        if let existing = governors[key] as? NeuralGovernor<T> {
            return existing
        }

        let newGovernor = NeuralGovernor<T>(
            label: String(context.prefix(4).uppercased()),
            modelName: modelName,
            bundle: bundle ?? .module,
            inputName: inputName,
            inputShape: inputShape,
            governorBrain: governorBrain,
            batcher: batcher,
            registry: registry
        )
        governors[key] = newGovernor
        return newGovernor
    }
}
