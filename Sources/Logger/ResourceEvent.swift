//  ResourceEvent.swift
//  Logger
//
//  [Add description here]
import Foundation

/// Standardized system events for Neural Resource Governance.
public enum ResourceEvent: Double, Sendable, CustomStringConvertible {
    case unknown = 0.0
    case vibeUpdate = 1.0
    case motionUpdate = 2.0
    case locationUpdate = 3.0
    case biometricUpdate = 4.0
    case uiRender = 5.0
    case chargingStateChange = 6.0
    case lowPowerModeChange = 7.0
    case thermalPressureChange = 8.0

    /// Maps a Notification Name to a ResourceEvent
    public static func from(notificationName: Notification.Name) -> ResourceEvent {
        switch notificationName.rawValue {
        case "vibeDidChange": return .vibeUpdate
        case "motionDidChange": return .motionUpdate
        case "locationDidChange": return .locationUpdate
        case "biometricDidChange": return .biometricUpdate
        case "UIDidRender": return .uiRender
        case ProcessInfo.thermalStateDidChangeNotification.rawValue: return .thermalPressureChange
        default: return .unknown
        }
    }

    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .vibeUpdate: return "vibeDidChange"
        case .motionUpdate: return "motionDidChange"
        case .locationUpdate: return "locationDidChange"
        case .biometricUpdate: return "biometricDidChange"
        case .uiRender: return "UIDidRender"
        case .chargingStateChange: return "chargingStateDidChange"
        case .lowPowerModeChange: return "lowPowerModeDidChange"
        case .thermalPressureChange: return "thermalPressureDidChange"
        }
    }
}
