//
//  LogAnalyzer.swift
//  Logger
//
//  Created by Neural Governor on 12/01/26.
//

import Foundation
import CoreML

/// Analyzes execution patterns to detect anomalies.
public final class LogAnalyzer: @unchecked Sendable {
    private let brain = BaseNeuralBrain(label: "LOGA", modelName: "Governor")
    private let log = LogContext("LOAN")
    
    public init() {}
    public struct Insight: Sendable {
        public let context: Logger.Context
        public let metric: String
        public let value: String
        public let severity: Int // 0=Info, 1=Warning, 2=Error
        public let action: AutonomicAction // What should the system do?
    }
    
    public enum AutonomicAction: Sendable {
        case none
        case throttle(TimeInterval) // Delay next task
        case interrupt // Stop completely
    }
    
    // Autonomic State
    public struct HealthState: Sendable {
        public let status: Status
        public let action: AutonomicAction
        
        public enum Status: Sendable {
            case healthy
            case stressed
            case critical
        }
    }
    
    // Baselines (Learned or Hardcoded for now)
    // Baselines (Learned or Hardcoded for now)
    private let driftThresholds: [Logger.Context: TimeInterval] = [
        Logger.Context("VIBE"): 0.100, // 100ms
        Logger.Context("TRNR"): 5.0, // 5s
        Logger.Context("STR"): 0.500, // 500ms
        Logger.Context("COLL"): 0.050 // 50ms
    ]
    
    
    public func analyze(tasks: [LogTask.Record]) async -> [Insight] {
        var insights: [Insight] = []
        
        // Group by context
        let tasksByContext = Dictionary(grouping: tasks) { $0.context }
        
        for (context, contextTasks) in tasksByContext {
            // Metrics Calculation (The Senses)
            let durations = contextTasks.compactMap { $0.duration }
            let avgDuration = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
            let variance = durations.isEmpty ? 0 : (durations.map { pow($0 - avgDuration, 2) }.reduce(0, +) / Double(durations.count))
            
            let recentTasks = contextTasks.filter { abs($0.start.timeIntervalSinceNow) < 1.0 }.count
            let failures = contextTasks.filter { if case .some(.failure) = $0.outcome { return true }; return false }.count
            let failureRate = contextTasks.isEmpty ? 0 : Double(failures) / Double(contextTasks.count)
            
            // Baseline normalization (Simplified)
            let driftNorm = avgDuration / (driftThresholds[context] ?? 1.0)
            let flickerNorm = Double(recentTasks) / 10.0
            
            // Input Vector construction
            guard let input = try? MLMultiArray(shape: [4], dataType: .double) else { continue }
            input[0] = NSNumber(value: driftNorm)   // Drift
            input[1] = NSNumber(value: flickerNorm) // Flicker
            input[2] = NSNumber(value: failureRate) // Fragility
            input[3] = NSNumber(value: variance)    // Variance
            
            // Neural Inference (The Decision)
            do {
                let inputProvider = try MLDictionaryFeatureProvider(dictionary: ["telemetry": MLFeatureValue(multiArray: input)])
                let result = try await brain.prediction(from: SendableFeatureProvider(inputProvider))
                let prediction = result.provider
                
                guard let probs = prediction.featureValue(for: "action_probs")?.multiArrayValue else { continue }
                
                // Decode: 0=None, 1=Throttle, 2=Interrupt
                let pNone = probs[0].doubleValue
                let pThrottle = probs[1].doubleValue
                let pInterrupt = probs[2].doubleValue
                
                // Decision Logic (ArgMax)
                if pInterrupt > pThrottle && pInterrupt > pNone {
                    insights.append(Insight(
                        context: context,
                        metric: "NeuralFragility",
                        value: "Gov Confidence \(Int(pInterrupt * 100))%",
                        severity: 2,
                        action: .interrupt
                    ))
                } else if pThrottle > pNone {
                    insights.append(Insight(
                        context: context,
                        metric: "NeuralDrift",
                        value: "Gov Confidence \(Int(pThrottle * 100))%",
                        severity: 1,
                        action: .throttle(0.1 * pThrottle) // Dynamic throttling based on confidence
                    ))
                }
                
            } catch let inferenceError {
                log.error("Inference failed: \(inferenceError)")
            }
        }
        
        return insights
    }
}
