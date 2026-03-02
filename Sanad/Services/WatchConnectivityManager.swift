//
//  WatchConnectivityManager.swift
//  Sanad (iPhone side)
//
//  Manages communication between iPhone app and Apple Watch companion app
//  Uses WatchConnectivity framework to sync data and receive commands
//  Requires WatchConnectivity framework — add to Xcode project
//

import Foundation
import WatchConnectivity
import Combine

/// مدير الاتصال مع Apple Watch - Watch Connectivity Manager (iPhone side)
class WatchConnectivityManager: NSObject, ObservableObject {

    static let shared = WatchConnectivityManager()

    // MARK: - Published Properties

    @Published var isWatchReachable: Bool = false
    @Published var isWatchPaired: Bool = false
    @Published var lastMessageFromWatch: [String: Any] = [:]

    // MARK: - Session

    private var session: WCSession?

    // MARK: - Init

    private override init() {
        super.init()
        setupSession()
    }

    // MARK: - Setup

    private func setupSession() {
        guard WCSession.isSupported() else {
            print("⌚ WatchConnectivity غير مدعوم على هذا الجهاز")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
        print("⌚ تم تفعيل WatchConnectivity")
    }

    // MARK: - Send Data to Watch

    /// إرسال بيانات الأدوية للساعة - Send medication data to Watch
    func sendMedicationsToWatch() {
        guard let session = session, session.isReachable else { return }

        let medications = StorageManager.shared.getActiveMedications()
        let medicationData = medications.map { med -> [String: Any] in
            [
                "id":     med.id.uuidString,
                "name":   med.name,
                "dosage": med.dosage,
                "times":  med.times.map { "\($0.hour):\(String(format: "%02d", $0.minute))" }
            ]
        }

        let message: [String: Any] = [
            "type":        "medications",
            "medications": medicationData
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("❌ خطأ في إرسال الأدوية للساعة: \(error.localizedDescription)")
        }

        print("⌚ تم إرسال \(medications.count) دواء للساعة")
    }

    /// إرسال جهات الاتصال المفضلة للساعة - Send favorite contacts to Watch
    func sendContactsToWatch() {
        guard let session = session, session.isReachable else { return }

        let contacts = StorageManager.shared.getFavoriteContacts()
        let contactData = contacts.map { contact -> [String: Any] in
            [
                "id":           contact.id.uuidString,
                "name":         contact.name,
                "phoneNumber":  contact.phoneNumber,
                "relationship": contact.relationship
            ]
        }

        let message: [String: Any] = [
            "type":     "contacts",
            "contacts": contactData
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("❌ خطأ في إرسال جهات الاتصال للساعة: \(error.localizedDescription)")
        }

        print("⌚ تم إرسال \(contacts.count) جهة اتصال للساعة")
    }

    /// إرسال حالة الطوارئ للساعة - Send emergency status to Watch
    func sendEmergencyStatusToWatch(isActive: Bool) {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            "type":      "emergencyStatus",
            "isActive":  isActive
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("❌ خطأ في إرسال حالة الطوارئ للساعة: \(error.localizedDescription)")
        }
    }

    /// إرسال تحديث الموقع للساعة - Send location update to Watch
    func sendLocationToWatch() {
        guard let session = session, session.isReachable else { return }
        guard let locationText = LocationManager.shared.getLocationText(),
              let locationLink = LocationManager.shared.getGoogleMapsLink() else { return }

        let message: [String: Any] = [
            "type":         "location",
            "locationText": locationText,
            "locationLink": locationLink
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("❌ خطأ في إرسال الموقع للساعة: \(error.localizedDescription)")
        }
    }

    // MARK: - Update Application Context (background sync)

    /// تحديث السياق للمزامنة في الخلفية - Update context for background sync
    func updateApplicationContext() {
        guard let session = session,
              session.activationState == .activated else { return }

        let medications = StorageManager.shared.getActiveMedications()
        let contacts    = StorageManager.shared.getFavoriteContacts()
        let settings    = StorageManager.shared.loadSettings()

        let context: [String: Any] = [
            "medicationCount":  medications.count,
            "contactCount":     contacts.count,
            "fallDetection":    settings.fallDetectionEnabled,
            "lastSync":         Date().timeIntervalSince1970
        ]

        do {
            try session.updateApplicationContext(context)
            print("⌚ تم تحديث سياق التطبيق للساعة")
        } catch {
            print("❌ خطأ في تحديث سياق الساعة: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Watch Commands

    private func handleWatchCommand(_ message: [String: Any]) {
        guard let command = message["command"] as? String else { return }

        DispatchQueue.main.async {
            switch command {
            case "callFamily":
                // Trigger call family from Watch
                NotificationCenter.default.post(
                    name: .watchCommandReceived,
                    object: nil,
                    userInfo: ["command": "callFamily"]
                )
                print("⌚ أمر من الساعة: اتصل بالعائلة")

            case "sendLocation":
                // Trigger location sharing from Watch
                NotificationCenter.default.post(
                    name: .watchCommandReceived,
                    object: nil,
                    userInfo: ["command": "sendLocation"]
                )
                print("⌚ أمر من الساعة: أرسل الموقع")

            case "emergency":
                // Trigger emergency from Watch
                NotificationCenter.default.post(
                    name: .watchCommandReceived,
                    object: nil,
                    userInfo: ["command": "emergency"]
                )
                EnhancedEmergencyManager.shared.startEmergencyCheck(timeout: 30)
                print("⌚ أمر من الساعة: طوارئ")

            case "medicationTaken":
                // Mark medication as taken from Watch
                if let medicationIdString = message["medicationId"] as? String,
                   let medicationId = UUID(uuidString: medicationIdString) {
                    MedicationTrackingManager.shared.markMedicationTaken(medicationID: medicationId)
                    print("⌚ أمر من الساعة: تم أخذ الدواء")
                }

            case "fallDetected":
                // Fall detected from Watch
                NotificationCenter.default.post(name: .fallDetected, object: nil)
                print("⌚ أمر من الساعة: تم اكتشاف سقوط")

            default:
                print("⌚ أمر غير معروف من الساعة: \(command)")
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchPaired    = session.isPaired
            self.isWatchReachable = session.isReachable

            if let error = error {
                print("❌ خطأ في تفعيل WatchConnectivity: \(error.localizedDescription)")
            } else {
                print("⌚ WatchConnectivity مفعّل — مقترن: \(session.isPaired), متاح: \(session.isReachable)")
                // Send initial data to Watch
                self.updateApplicationContext()
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⌚ WatchConnectivity غير نشط")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("⌚ WatchConnectivity معطّل — إعادة التفعيل")
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
            print("⌚ حالة الاتصال بالساعة تغيرت: \(session.isReachable)")

            if session.isReachable {
                // Sync data when Watch becomes reachable
                self.sendMedicationsToWatch()
                self.sendContactsToWatch()
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.lastMessageFromWatch = message
            self.handleWatchCommand(message)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            self.handleWatchCommand(message)

            // Reply with current status
            let reply: [String: Any] = [
                "status":          "received",
                "medicationCount": StorageManager.shared.getActiveMedications().count,
                "hasTakenToday":   MedicationTrackingManager.shared.hasTakenMedicationToday
            ]
            replyHandler(reply)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            print("⌚ تم استقبال سياق من الساعة: \(applicationContext)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchCommandReceived = Notification.Name("watchCommandReceived")
}
