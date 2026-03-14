import Foundation

/// Handles model persistence, providing writable storage paths and bundle falling back.
public final class ModelStorage: Sendable {
    public init() {}
    
    /// Returns the best available model URL (prioritizing writable storage).
    public func bestModelURL(for modelName: String, bundle: Bundle = .main, fallbackBundle: Bundle? = nil) -> URL? {
        let name = modelName.hasSuffix(".mlmodelc") ? modelName : modelName + ".mlmodelc"
        let writable = writableURL(for: modelName)
        
        if FileManager.default.fileExists(atPath: writable.path) {
            return writable
        }
        
        if let bundleURL = bundle.url(forResource: modelName, withExtension: "mlmodelc") {
            return bundleURL
        }
        
        if let fallback = fallbackBundle?.url(forResource: modelName, withExtension: "mlmodelc") {
            return fallback
        }
        
        return nil
    }
    
    /// Returns the writable URL for a model in the Application Support directory.
    public func writableURL(for modelName: String) -> URL {
        let name = modelName.hasSuffix(".mlmodelc") ? modelName : modelName + ".mlmodelc"
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let modelsDir = appSupport.appendingPathComponent("Models", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: modelsDir.path) {
            do {
                try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
            } catch {
                // In some environments, we might not have a logger available here, 
                // but we should at least print the error in debug or use NSLog.
                NSLog("ModelStorage: Failed to create records directory: \(error)")
            }
        }
        
        return modelsDir.appendingPathComponent(name)
    }
}
