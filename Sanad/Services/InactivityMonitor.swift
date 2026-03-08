//
//  InactivityMonitor.swift
//  Sanad
//
//  Detects prolonged inactivity and logs/alerts it.
//  Phase 2 feature.
//

import Foundation
import Combine

final class InactivityMonitor: ObservableObject {
    static let shared = InactivityMonitor()

    @Published var isMonitoring: Bool = false
    @Published var inactivityThresholdHours: Int = 2
    @Published private(set) var lastActivityDate: Date = Date()

    private var timer: Timer?
    private var hasTriggeredForCurrentWindow = false

    private init() {}

    func startMonitoring(thresholdHours: Int = 2) {
        inactivityThresholdHours = max(1, thresholdHours)
        isMonitoring = true
        lastActivityDate = Date()
        hasTriggeredForCurrentWindow = false

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.evaluateInactivity()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }

    func registerActivity() {
        lastActivityDate = Date()
        hasTriggeredForCurrentWindow = false
    }

    private func evaluateInactivity() {
        guard isMonitoring else { return }

        let elapsed = Date().timeIntervalSince(lastActivityDate)
        let thresholdSeconds = TimeInterval(inactivityThresholdHours * 3600)

        guard elapsed >= thresholdSeconds, !hasTriggeredForCurrentWindow else { return }
        hasTriggeredForCurrentWindow = true

        ActivityLogger.shared.log(
            type: .inactivityDetected,
            title: "انخفاض النشاط",
            description: "لم يتم رصد نشاط لمدة \(inactivityThresholdHours) ساعة",
            severity: .high,
            metadata: [
                "threshold_hours": "\(inactivityThresholdHours)",
                "last_activity": ISO8601DateFormatter().string(from: lastActivityDate)
            ]
        )
    }
}
