//
//  WatchSessionManager.swift
//  SanadWatch
//
//  Watch side of WatchConnectivity — receives data from iPhone
//  and sends commands back
//

import Foundation
import WatchConnectivity
import Combine

/// مدير جلسة الساعة - Watch Session Manager (Watch side)
class WatchSessionManager: NSObject, ObservableObject {

    static let shared = WatchSessionManager()

    // MARK: - Published Properties

    @Published var medications: [WatchMedication] = []
    @Published var contacts: [WatchContact] = []
    @Published var isPhoneReachable: Bool = false
    @Published var hasTakenMedicationToday: Bool = false
    @Published var isEmergencyActive: Bool = false

    // MARK: - Init

    private override init() {
        super.init()
        setupSession()
    }

    // MARK: - Setup

    private func setupSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send Commands to iPhone

    /// إرسال أمر الاتصال بالعائلة - Send call family command
    func sendCallFamilyCommand() {
        sendCommand("callFamily")
    }

    /// إرسال أمر إرسال الموقع - Send location command
    func sendLocationCommand() {
        sendCommand("sendLocation")
    }

    /// إرسال أمر الطوارئ - Send emergency command
    func sendEmergencyCommand() {
        sendCommand("emergency")
    }

    /// إرسال تأكيد أخذ الدواء - Send medication taken confirmation
    func sendMedicationTaken(medicationId: String) {
        let message: [String: Any] = [
            "command":      "medicationTaken",
            "medicationId": medicationId
        ]
        sendMessage(message)
    }

    /// إرسال تنبيه سقوط من الساعة - Send fall detection from Watch
    func sendFallDetected() {
        sendCommand("fallDetected")
    }

    // MARK: - Private Helpers

    private func sendCommand(_ command: String) {
        sendMessage(["command": command])
    }

    private func sendMessage(_ message: [String: Any]) {
        guard WCSession.default.isReachable else {
            print("⌚ الهاتف غير متاح")
            return
        }

        WCSession.default.sendMessage(message, replyHandler: { reply in
            print("⌚ رد من الهاتف: \(reply)")
        }) { error in
            print("❌ خطأ في إرسال الأمر للهاتف: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle iPhone Data

    private func handleMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "medications":
            if let medicationsData = message["medications"] as? [[String: Any]] {
                medications = medicationsData.compactMap { WatchMedication(from: $0) }
                print("⌚ استقبلت \(medications.count) دواء من الهاتف")
            }

        case "contacts":
            if let contactsData = message["contacts"] as? [[String: Any]] {
                contacts = contactsData.compactMap { WatchContact(from: $0) }
                print("⌚ استقبلت \(contacts.count) جهة اتصال من الهاتف")
            }

        case "emergencyStatus":
            isEmergencyActive = message["isActive"] as? Bool ?? false

        case "location":
            // Location received — could display on Watch
            print("⌚ استقبلت الموقع من الهاتف")

        default:
            print("⌚ نوع رسالة غير معروف: \(type)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
            print("⌚ WatchConnectivity مفعّل على الساعة")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.handleMessage(message)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            self.handleMessage(message)
            replyHandler(["status": "received"])
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            if let medicationCount = applicationContext["medicationCount"] as? Int {
                print("⌚ عدد الأدوية من السياق: \(medicationCount)")
            }
            if let hasTaken = applicationContext["hasTakenToday"] as? Bool {
                self.hasTakenMedicationToday = hasTaken
            }
        }
    }
}

// MARK: - Watch Data Models

struct WatchMedication: Identifiable {
    let id: String
    let name: String
    let dosage: String
    let times: [String]

    init?(from dict: [String: Any]) {
        guard
            let id    = dict["id"] as? String,
            let name  = dict["name"] as? String,
            let dosage = dict["dosage"] as? String
        else { return nil }

        self.id     = id
        self.name   = name
        self.dosage = dosage
        self.times  = dict["times"] as? [String] ?? []
    }
}

struct WatchContact: Identifiable {
    let id: String
    let name: String
    let phoneNumber: String
    let relationship: String

    init?(from dict: [String: Any]) {
        guard
            let id           = dict["id"] as? String,
            let name         = dict["name"] as? String,
            let phoneNumber  = dict["phoneNumber"] as? String,
            let relationship = dict["relationship"] as? String
        else { return nil }

        self.id           = id
        self.name         = name
        self.phoneNumber  = phoneNumber
        self.relationship = relationship
    }
}
