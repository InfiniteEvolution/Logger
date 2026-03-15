//  ResourceGovernor+Evaluation.swift
//  Logger
//
//  [Add description here]
import Foundation

extension ResourceGovernor {
    internal func setupEventObservers() {
        let events: [Notification.Name] = [
            .init("vibeDidChange"),
            .init("motionDidChange"),
            .init("locationDidChange"),
            .init("biometricDidChange"),
            ProcessInfo.thermalStateDidChangeNotification
        ]

        for name in events {
            let observer = NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] note in
                let noteName = note.name
                Task { [weak self] in
                    await self?.evaluateEvent(named: noteName)
                }
            }
            observers_append(observer)
        }
    }

    /// Triggered by global registry or local events
    internal func evaluateEvent(named notificationName: Notification.Name) async {
        let event = ResourceEvent.from(notificationName: notificationName)
        lastEvent_set(event)

        let score = await currentRelevanceScore()

        if score < 0.5 {
            log_info("Intelligence Suggests Eviction for \(label_get()). Score: \(score)")
            await onRelease_call()
            await logRecord(outcome: 0)
        } else {
            await logRecord(outcome: 1) // Recorded as a "Keep" decision
        }

        // Reset frequency bucket periodically
        if Date().timeIntervalSince(lastUsed_get()) > 300 {
            activityCount_reset()
        }
    }

    internal func logRecord(outcome: Int64) async {
        let interArrival = Date().timeIntervalSince(lastUsed_get())
        let frequency = Double(activityCount_get()) / 300.0

        await batcher_get().record(
            resourceID: resourceID_get(),
            eventID: lastEvent_get().rawValue,
            frequency: min(1.0, frequency),
            interArrivalTime: min(1.0, interArrival / 600.0),
            systemPressure: getSystemPressure(),
            outcome: outcome
        )
    }
}
