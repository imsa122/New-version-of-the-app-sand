//
//  SiriShortcutsManager.swift
//  Sanad
//
//  Siri Shortcuts integration — donate shortcuts so users can trigger
//  key actions via "Hey Siri" voice commands
//  Requires Siri capability in Xcode project settings
//

import Foundation
import Intents
import UIKit

/// مدير اختصارات Siri - Siri Shortcuts Manager
class SiriShortcutsManager {

    static let shared = SiriShortcutsManager()

    private init() {}

    // MARK: - Shortcut Identifiers

    enum ShortcutIdentifier: String {
        case callFamily    = "com.sanad.callFamily"
        case sendLocation  = "com.sanad.sendLocation"
        case emergency     = "com.sanad.emergency"
        case medications   = "com.sanad.medications"
        case prayerTimes   = "com.sanad.prayerTimes"
    }

    // MARK: - Donate Shortcuts

    /// تسجيل الاختصارات مع Siri - Donate shortcuts to Siri
    func donateShortcuts() {
        donateCallFamilyShortcut()
        donateSendLocationShortcut()
        donateEmergencyShortcut()
        donateMedicationsShortcut()
        donatePrayerTimesShortcut()
        print("✅ تم تسجيل اختصارات Siri")
    }

    // MARK: - Individual Shortcut Donations

    /// اتصل بالعائلة - Call Family Shortcut
    private func donateCallFamilyShortcut() {
        let activity = NSUserActivity(activityType: ShortcutIdentifier.callFamily.rawValue)
        activity.title = "اتصل بالعائلة"
        activity.userInfo = ["action": "callFamily"]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "اتصل بالعائلة"
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(ShortcutIdentifier.callFamily.rawValue)
        activity.becomeCurrent()

        let shortcut = INShortcut(userActivity: activity)
        let interaction = INInteraction(intent: INIntent(), response: nil)
        interaction.donate { error in
            if let error = error {
                print("❌ خطأ في تسجيل اختصار الاتصال: \(error.localizedDescription)")
            }
        }

        INVoiceShortcutCenter.shared.setShortcutSuggestions([shortcut])
    }

    /// أرسل موقعي - Send Location Shortcut
    private func donateSendLocationShortcut() {
        let activity = NSUserActivity(activityType: ShortcutIdentifier.sendLocation.rawValue)
        activity.title = "أرسل موقعي"
        activity.userInfo = ["action": "sendLocation"]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "أرسل موقعي"
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(ShortcutIdentifier.sendLocation.rawValue)
        activity.becomeCurrent()
    }

    /// طوارئ - Emergency Shortcut
    private func donateEmergencyShortcut() {
        let activity = NSUserActivity(activityType: ShortcutIdentifier.emergency.rawValue)
        activity.title = "طوارئ"
        activity.userInfo = ["action": "emergency"]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "ساعدني"
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(ShortcutIdentifier.emergency.rawValue)
        activity.becomeCurrent()
    }

    /// أدويتي - Medications Shortcut
    private func donateMedicationsShortcut() {
        let activity = NSUserActivity(activityType: ShortcutIdentifier.medications.rawValue)
        activity.title = "أدويتي"
        activity.userInfo = ["action": "medications"]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "أدويتي"
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(ShortcutIdentifier.medications.rawValue)
        activity.becomeCurrent()
    }

    /// أوقات الصلاة - Prayer Times Shortcut
    private func donatePrayerTimesShortcut() {
        let activity = NSUserActivity(activityType: ShortcutIdentifier.prayerTimes.rawValue)
        activity.title = "أوقات الصلاة"
        activity.userInfo = ["action": "prayerTimes"]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "أوقات الصلاة"
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(ShortcutIdentifier.prayerTimes.rawValue)
        activity.becomeCurrent()
    }

    // MARK: - Handle Incoming Shortcut

    /// معالجة الاختصار القادم من Siri - Handle shortcut triggered by Siri
    func handleShortcut(_ userActivity: NSUserActivity) -> SiriAction? {
        guard let action = userActivity.userInfo?["action"] as? String else { return nil }

        switch action {
        case "callFamily":   return .callFamily
        case "sendLocation": return .sendLocation
        case "emergency":    return .emergency
        case "medications":  return .medications
        case "prayerTimes":  return .prayerTimes
        default:             return nil
        }
    }

    // MARK: - Delete Shortcuts

    /// حذف جميع الاختصارات - Delete all shortcuts
    func deleteAllShortcuts() {
        let identifiers = ShortcutIdentifier.allCases.map { $0.rawValue }
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
            guard let shortcuts = shortcuts else { return }
            let toDelete = shortcuts.filter { identifiers.contains($0.shortcut.userActivity?.activityType ?? "") }
            for shortcut in toDelete {
                INVoiceShortcutCenter.shared.deleteVoiceShortcut(withIdentifier: shortcut.identifier) { error in
                    if let error = error {
                        print("❌ خطأ في حذف الاختصار: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// MARK: - Siri Action Enum

enum SiriAction {
    case callFamily
    case sendLocation
    case emergency
    case medications
    case prayerTimes
}

// MARK: - ShortcutIdentifier CaseIterable

extension SiriShortcutsManager.ShortcutIdentifier: CaseIterable {}
