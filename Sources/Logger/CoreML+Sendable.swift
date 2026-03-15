//  CoreML+Sendable.swift
//  Logger
//
//  Sendable conformance and helper extensions for CoreML types.
import CoreML

extension MLDictionaryFeatureProvider: @unchecked @retroactive Sendable {}
extension MLModel: @unchecked @retroactive Sendable {}
extension MLMultiArray: @unchecked @retroactive Sendable {}
extension MLFeatureValue: @unchecked @retroactive Sendable {}

/// A Sendable wrapper for CoreML feature providers to allow passing across actor boundaries.
public struct SendableFeatureProvider: @unchecked Sendable {
    public let provider: MLFeatureProvider

    public init(_ provider: MLFeatureProvider) {
        self.provider = provider
    }
}
