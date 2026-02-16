import Foundation
import UserNotifications
import UIKit

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationDelegate()
    
    private override init() {}
    
    // أثناء فتح التطبيق
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handleNotification(notification)
        completionHandler([.banner, .sound])
    }
    
    // عند الضغط على الإشعار
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotification(response.notification)
        completionHandler()
    }
    
    // MARK: - معالجة الإشعار
    
    private func handleNotification(_ notification: UNNotification) {
        
        let userInfo = notification.request.content.userInfo
        
        guard let type = userInfo["type"] as? String else { return }
        
        if type == "medication_followup" {
            
            guard let medicationIdString = userInfo["medicationId"] as? String,
                  let medicationId = UUID(uuidString: medicationIdString) else { return }
            
            let tracker = MedicationTrackingManager.shared
            
            if !tracker.hasTakenMedicationToday {
                
                // 🔥 تسجيل تفويت الجرعة
                if let medication = StorageManager.shared
                    .getActiveMedications()
                    .first(where: { $0.id == medicationId }) {
                    
                    ActivityLogger.shared.logMedicationMissed(
                        medicationId: medicationId,
                        medicationName: medication.name
                    )
                }
                
                notifyFamilyAboutMissedDose(medicationID: medicationId)
            }
        }
    }
    
    // MARK: - تنبيه العائلة
    
    private func notifyFamilyAboutMissedDose(medicationID: UUID) {
        
        let contacts = StorageManager.shared.getEmergencyContacts()
        guard let firstContact = contacts.first else {
            print("❌ لا توجد جهات اتصال للطوارئ")
            return
        }
        
        let medications = StorageManager.shared.getActiveMedications()
        let medication = medications.first { $0.id == medicationID }
        
        let medicationName = medication?.name ?? "الدواء"
        let currentTime = formatTime(Date())
        let locationLink = LocationManager.shared.getGoogleMapsLink() ?? "الموقع غير متاح"
        
        let message = """
🚨 تنبيه من تطبيق سند

لم يتم تأكيد أخذ \(medicationName)
الوقت: \(currentTime)

الموقع الحالي:
\(locationLink)

يرجى التواصل للاطمئنان.
"""
        
        sendWhatsAppMessage(to: firstContact.phoneNumber, message: message)
    }
    
    // MARK: - إرسال واتساب
    
    private func sendWhatsAppMessage(to phoneNumber: String, message: String) {
        
        let cleanedNumber = phoneNumber
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        guard let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://wa.me/\(cleanedNumber)?text=\(encodedMessage)") else {
            return
        }
        
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                
                // 🔥 تسجيل فتح واتساب
                ActivityLogger.shared.log(
                    type: .info,
                    title: "تنبيه واتساب",
                    description: "تم فتح واتساب لإرسال تنبيه للعائلة",
                    severity: .medium
                )
                
            } else {
                print("❌ واتساب غير مثبت")
            }
        }
    }
    
    // MARK: - تنسيق الوقت
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
