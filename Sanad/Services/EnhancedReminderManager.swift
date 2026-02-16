//
//  EnhancedReminderManager.swift
//  Sanad
//

import Foundation
import UserNotifications
import AVFoundation
import Combine

class EnhancedReminderManager: ObservableObject {
    
    static let shared = EnhancedReminderManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    @Published var upcomingReminders: [ScheduledReminder] = []
    
    private init() {}
    
    // MARK: - Permission
    
    static func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
    }
    
    // MARK: - Schedule Medication Reminders
    
    func scheduleMedicationReminders(for medication: Medication) {
        
        cancelReminders(for: medication.id)
        
        for time in medication.times {
            scheduleReminder(
                id: "\(medication.id.uuidString)_\(time.id.uuidString)",
                title: "تذكير بالدواء",
                body: "حان وقت تناول \(medication.name) - \(medication.dosage)",
                dateComponents: time.dateComponents,
                medication: medication
            )
        }
        
        print("✅ تم جدولة \(medication.times.count) تذكير للدواء: \(medication.name)")
    }
    
    func scheduleAllMedicationReminders() {
        let medications = StorageManager.shared.getActiveMedications()
        
        for medication in medications {
            scheduleMedicationReminders(for: medication)
        }
        
        print("✅ تم جدولة تذكيرات لـ \(medications.count) دواء")
    }
    
    private func scheduleReminder(
        id: String,
        title: String,
        body: String,
        dateComponents: DateComponents,
        medication: Medication
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "medicationId": medication.id.uuidString,
            "medicationName": medication.name,
            "type": "medication"
        ]
        
        if let notes = medication.notes {
            content.subtitle = notes
        }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
        
        // 🔔 جدولة تنبيه متابعة بعد 30 دقيقة
        scheduleFollowUpReminder(
            medication: medication,
            originalTimeComponents: dateComponents
        )
    }
    
    // MARK: - Follow Up Reminder (30 minutes later)
    
    private func scheduleFollowUpReminder(
        medication: Medication,
        originalTimeComponents: DateComponents
    ) {
        guard let hour = originalTimeComponents.hour,
              let minute = originalTimeComponents.minute else { return }
        
        var followUpComponents = DateComponents()
        followUpComponents.hour = hour
        followUpComponents.minute = minute + 30
        
        let content = UNMutableNotificationContent()
        content.title = "متابعة الدواء"
        content.body = "لم يتم تأكيد أخذ \(medication.name). هل تم تناول الجرعة؟"
        content.sound = .default
        
        content.userInfo = [
            "medicationId": medication.id.uuidString,
            "type": "medication_followup"
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: followUpComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "\(medication.id.uuidString)_followup",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Cancel Reminders
    
    func cancelReminders(for medicationId: UUID) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            
            let identifiersToRemove = requests
                .filter { $0.identifier.starts(with: medicationId.uuidString) }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            
            print("🗑️ تم إلغاء \(identifiersToRemove.count) تذكير")
        }
    }
    
    func cancelFollowUpNotification(for medicationID: UUID) {
        let identifier = "\(medicationID.uuidString)_followup"
        
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ تم إلغاء جميع التذكيرات")
    }
    
    // MARK: - Upcoming Reminders
    
    func fetchUpcomingReminders() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            
            let reminders = requests
                .filter { $0.content.userInfo["type"] as? String == "medication" }
                .compactMap { request -> ScheduledReminder? in
                    
                    guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                          let nextTriggerDate = trigger.nextTriggerDate() else {
                        return nil
                    }
                    
                    return ScheduledReminder(
                        id: request.identifier,
                        title: request.content.title,
                        body: request.content.body,
                        nextTriggerDate: nextTriggerDate
                    )
                }
                .sorted { $0.nextTriggerDate < $1.nextTriggerDate }
            
            DispatchQueue.main.async {
                self?.upcomingReminders = reminders
            }
        }
    }
    
    // MARK: - Voice Reminder
    
    func speakReminder(for medication: Medication) {
        let text = "تذكير: حان وقت تناول \(medication.name). الجرعة: \(medication.dosage)"
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        utterance.rate = 0.5
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    // MARK: - Test Notification
    
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "تذكير تجريبي"
        content.body = "هذا تذكير تجريبي من تطبيق سند"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 5,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
        print("✅ تم إرسال إشعار تجريبي")
    }
}

// MARK: - Scheduled Reminder Model

struct ScheduledReminder: Identifiable {
    let id: String
    let title: String
    let body: String
    let nextTriggerDate: Date
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: nextTriggerDate)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: nextTriggerDate)
    }
}
