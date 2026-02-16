//
//  EnhancedEmergencyManager.swift
//  Sanad
//
//  Enhanced emergency management system
//

import Foundation
import AVFoundation
import UIKit
import Combine
import UserNotifications

/// مدير الطوارئ المحسّن - Enhanced Emergency Manager
class EnhancedEmergencyManager: ObservableObject {
    
    static let shared = EnhancedEmergencyManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    private let locationManager = LocationManager.shared
    
    @Published var isEmergencyActive: Bool = false
    @Published var emergencyCountdown: Int = 0
    
    private var emergencyTimer: Timer?
    private var countdownTimer: Timer?
    
    private init() {
        // الاستماع لإشعارات السقوط
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFallDetection),
            name: .fallDetected,
            object: nil
        )
        
        // الاستماع لإشعارات الخروج من السياج الجغرافي
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGeofenceExit),
            name: .geofenceExited,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Emergency Activation
    
    /// بدء فحص الطوارئ - Start Emergency Check
    func startEmergencyCheck(timeout: Int = 30) {
        guard !isEmergencyActive else { return }
        
        isEmergencyActive = true
        emergencyCountdown = timeout
        
        // اهتزاز قوي
        vibrateStrong()
        
        // نطق التنبيه
        speak("هل أنت بخير؟ سيتم إرسال تنبيه للعائلة خلال \(timeout) ثانية")
        
        // بدء العد التنازلي
        startCountdown(timeout: timeout)
        
        // إرسال إشعار محلي
        sendLocalNotification(
            title: "تنبيه طوارئ",
            body: "هل أنت بخير؟ اضغط للإلغاء"
        )
    }
    
    /// إلغاء الطوارئ - Cancel Emergency
    func cancelEmergency() {
        isEmergencyActive = false
        emergencyCountdown = 0
        
        emergencyTimer?.invalidate()
        countdownTimer?.invalidate()
        emergencyTimer = nil
        countdownTimer = nil
        
        speak("تم إلغاء التنبيه")
        print("✅ تم إلغاء تنبيه الطوارئ - Emergency cancelled")
    }
    
    /// تفعيل الطوارئ فوراً - Activate Emergency Immediately
    func activateEmergencyNow() {
        cancelEmergency()
        sendEmergencyAlert()
    }
    
    // MARK: - Countdown
    
    /// بدء العد التنازلي - Start Countdown
    private func startCountdown(timeout: Int) {
        // العد التنازلي
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.emergencyCountdown -= 1
            
            // تنبيه صوتي كل 10 ثواني
            if self.emergencyCountdown % 10 == 0 && self.emergencyCountdown > 0 {
                self.speak("باقي \(self.emergencyCountdown) ثانية")
            }
            
            if self.emergencyCountdown <= 0 {
                self.countdownTimer?.invalidate()
            }
        }
        
        // المؤقت الرئيسي
        emergencyTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeout), repeats: false) { [weak self] _ in
            self?.sendEmergencyAlert()
        }
    }
    
    // MARK: - Send Alert
    
    /// إرسال تنبيه الطوارئ - Send Emergency Alert
    private func sendEmergencyAlert() {
        guard isEmergencyActive else { return }
        
        isEmergencyActive = false
        emergencyCountdown = 0
        
        vibrateStrong()
        speak("تم إرسال تنبيه الطوارئ للعائلة")
        
        // الحصول على جهات الاتصال الطارئة
        let emergencyContacts = StorageManager.shared.getEmergencyContacts()
        
        // الحصول على الموقع
        let locationText = locationManager.getLocationText() ?? "الموقع غير متوفر"
        
        // إرسال الرسائل
        for contact in emergencyContacts {
            sendEmergencyMessage(to: contact, locationText: locationText)
        }
        
        // إرسال إشعار محلي
        sendLocalNotification(
            title: "⚠️ تنبيه طوارئ",
            body: "تم إرسال تنبيه الطوارئ لجهات الاتصال"
        )
        
        print("🚨 تم إرسال تنبيه الطوارئ - Emergency alert sent")
    }
    
    /// إرسال رسالة طوارئ - Send Emergency Message
    private func sendEmergencyMessage(to contact: Contact, locationText: String) {
        let message = """
        🚨 تنبيه طوارئ من تطبيق سند
        
        يحتاج \(contact.name) للمساعدة!
        
        \(locationText)
        
        الرجاء التواصل فوراً.
        """
        
        // في التطبيق الحقيقي، سيتم استخدام MessageUI أو SMS API
        print("📱 إرسال رسالة إلى \(contact.name): \(contact.phoneNumber)")
        print(message)
        
        // محاولة فتح تطبيق الرسائل
        if let url = URL(string: "sms:\(contact.phoneNumber)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    // MARK: - Fall Detection Handler
    
    /// معالجة كشف السقوط - Handle Fall Detection
    @objc private func handleFallDetection() {
        print("⚠️ تم اكتشاف سقوط - Fall detected, starting emergency check")
        startEmergencyCheck(timeout: 30)
    }
    
    // MARK: - Geofence Exit Handler
    
    /// معالجة الخروج من السياج الجغرافي - Handle Geofence Exit
    @objc private func handleGeofenceExit() {
        print("⚠️ خرج من المنطقة المحددة - Exited geofence")
        
        // إرسال تنبيه للعائلة
        let emergencyContacts = StorageManager.shared.getEmergencyContacts()
        let locationText = locationManager.getLocationText() ?? "الموقع غير متوفر"
        
        for contact in emergencyContacts {
            let message = """
            تنبيه من تطبيق سند
            
            خرج المستخدم من المنطقة المحددة (المنزل)
            
            \(locationText)
            """
            
            print("📱 إرسال تنبيه خروج من المنطقة إلى \(contact.name)")
            print(message)
        }
        
        speak("تم إرسال تنبيه للعائلة بأنك خارج المنطقة المحددة")
        
        sendLocalNotification(
            title: "تنبيه الموقع",
            body: "خرجت من المنطقة المحددة. تم إرسال تنبيه للعائلة."
        )
    }
    
    // MARK: - Utilities
    
    /// اهتزاز قوي - Strong Vibration
    private func vibrateStrong() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // اهتزاز إضافي
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    /// نطق النص - Speak Text
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        utterance.rate = 0.5
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
    
    /// إرسال إشعار محلي - Send Local Notification
    private func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
