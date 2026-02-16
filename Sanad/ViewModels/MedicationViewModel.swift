//
//  MedicationViewModel.swift
//  Sanad
//
//  ViewModel for medication management
//

import Foundation
import Combine
import AVFoundation

/// نموذج عرض الأدوية - Medication View Model
class MedicationViewModel: ObservableObject {
    
    @Published var medications: [Medication] = []
    @Published var activeMedications: [Medication] = []
    @Published var upcomingReminders: [ScheduledReminder] = []
    
    private let storageManager = StorageManager.shared
    private let reminderManager = EnhancedReminderManager.shared
    
    init() {
        loadMedications()
        fetchUpcomingReminders()
    }
    
    // MARK: - Load Data
    
    /// تحميل الأدوية - Load Medications
    func loadMedications() {
        medications = storageManager.loadMedications()
        activeMedications = medications.filter { $0.isActive }
    }
    
    /// تحديث التذكيرات القادمة - Fetch Upcoming Reminders
    func fetchUpcomingReminders() {
        reminderManager.fetchUpcomingReminders()
        
        // الاشتراك في التحديثات
        reminderManager.$upcomingReminders
            .assign(to: &$upcomingReminders)
    }
    
    // MARK: - Add Medication
    
    /// إضافة دواء - Add Medication
    func addMedication(_ medication: Medication) {
        storageManager.addMedication(medication)
        
        // جدولة التذكيرات
        if medication.isActive {
            reminderManager.scheduleMedicationReminders(for: medication)
        }
        
        loadMedications()
        fetchUpcomingReminders()
    }
    
    // MARK: - Update Medication
    
    /// تحديث دواء - Update Medication
    func updateMedication(_ medication: Medication) {
        storageManager.updateMedication(medication)
        
        // إعادة جدولة التذكيرات
        reminderManager.cancelReminders(for: medication.id)
        if medication.isActive {
            reminderManager.scheduleMedicationReminders(for: medication)
        }
        
        loadMedications()
        fetchUpcomingReminders()
    }
    
    // MARK: - Delete Medication
    
    /// حذف دواء - Delete Medication
    func deleteMedication(_ medication: Medication) {
        // إلغاء التذكيرات
        reminderManager.cancelReminders(for: medication.id)
        
        // حذف من التخزين
        storageManager.deleteMedication(medication)
        
        loadMedications()
        fetchUpcomingReminders()
    }
    
    // MARK: - Toggle Active Status
    
    /// تبديل حالة النشاط - Toggle Active Status
    func toggleMedicationActive(_ medication: Medication) {
        var updatedMedication = medication
        updatedMedication.isActive.toggle()
        
        updateMedication(updatedMedication)
    }
    
    // MARK: - Mark as Taken
    
    /// تسجيل تناول الدواء - Mark Medication as Taken
    func markAsTaken(_ medication: Medication) {
        // في نسخة أكثر تقدماً، يمكن تسجيل سجل التناول
        print("✅ تم تسجيل تناول: \(medication.name)")
        
        // نطق تأكيد
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: "تم تسجيل تناول \(medication.name)")
        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        synthesizer.speak(utterance)
    }
    
    // MARK: - Voice Reminder
    
    /// تذكير صوتي - Voice Reminder
    func speakReminder(for medication: Medication) {
        reminderManager.speakReminder(for: medication)
    }
    
    // MARK: - Test Notification
    
    /// إرسال إشعار تجريبي - Send Test Notification
    func sendTestNotification() {
        reminderManager.sendTestNotification()
    }
    
    // MARK: - Get Medications by Time
    
    /// الحصول على الأدوية حسب الوقت - Get Medications by Time
    func getMedicationsForTime(hour: Int) -> [Medication] {
        return activeMedications.filter { medication in
            medication.times.contains { time in
                time.hour == hour
            }
        }
    }
    
    /// الحصول على الأدوية الصباحية - Get Morning Medications
    func getMorningMedications() -> [Medication] {
        return activeMedications.filter { medication in
            medication.times.contains { time in
                time.hour >= 6 && time.hour < 12
            }
        }
    }
    
    /// الحصول على الأدوية المسائية - Get Evening Medications
    func getEveningMedications() -> [Medication] {
        return activeMedications.filter { medication in
            medication.times.contains { time in
                time.hour >= 18 && time.hour < 24
            }
        }
    }
    
    // MARK: - Statistics
    
    /// عدد الأدوية النشطة - Active Medications Count
    var activeMedicationsCount: Int {
        activeMedications.count
    }
    
    /// عدد التذكيرات اليومية - Daily Reminders Count
    var dailyRemindersCount: Int {
        activeMedications.reduce(0) { $0 + $1.times.count }
    }
}
