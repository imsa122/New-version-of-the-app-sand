//
//  FallDetectionManager.swift
//  Sanad
//
//  Detects potential falls using CoreMotion
//

import Foundation
import CoreMotion
import Combine

/// مدير كشف السقوط - Fall Detection Manager
class FallDetectionManager: ObservableObject {
    
    static let shared = FallDetectionManager()
    
    private let motionManager = CMMotionManager()
    private let activityManager = CMMotionActivityManager()
    
    @Published var isFallDetected: Bool = false
    @Published var isMonitoring: Bool = false
    
    // عتبات الكشف - Detection Thresholds
    private let fallThreshold: Double = 2.5 // قوة التسارع للكشف عن السقوط
    private let impactDuration: TimeInterval = 0.5 // مدة التأثير
    
    private var fallDetectionTimer: Timer?
    
    private init() {}
    
    // MARK: - Start/Stop Monitoring
    
    /// بدء مراقبة السقوط - Start Fall Detection
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        // التحقق من توفر المستشعرات
        guard motionManager.isAccelerometerAvailable else {
            print("مستشعر التسارع غير متوفر - Accelerometer not available")
            return
        }
        
        isMonitoring = true
        
        // إعداد معدل التحديث
        motionManager.accelerometerUpdateInterval = 0.1 // 10 مرات في الثانية
        
        // بدء تلقي بيانات التسارع
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            self.processAccelerometerData(data)
        }
        
        print("بدأ مراقبة السقوط - Fall detection started")
    }
    
    /// إيقاف مراقبة السقوط - Stop Fall Detection
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        motionManager.stopAccelerometerUpdates()
        isMonitoring = false
        
        print("توقفت مراقبة السقوط - Fall detection stopped")
    }
    
    // MARK: - Process Data
    
    /// معالجة بيانات التسارع - Process Accelerometer Data
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        let acceleration = data.acceleration
        
        // حساب قوة التسارع الكلية
        let totalAcceleration = sqrt(
            pow(acceleration.x, 2) +
            pow(acceleration.y, 2) +
            pow(acceleration.z, 2)
        )
        
        // الكشف عن السقوط المحتمل
        if totalAcceleration > fallThreshold {
            detectPotentialFall()
        }
    }
    
    /// كشف السقوط المحتمل - Detect Potential Fall
    private func detectPotentialFall() {
        // تجنب الكشف المتكرر
        guard !isFallDetected else { return }
        
        isFallDetected = true
        
        print("⚠️ تم اكتشاف سقوط محتمل - Potential fall detected")
        
        // إرسال إشعار للنظام
        NotificationCenter.default.post(name: .fallDetected, object: nil)
        
        // إعادة تعيين الحالة بعد فترة
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.isFallDetected = false
        }
    }
    
    // MARK: - Manual Fall Report
    
    /// الإبلاغ اليدوي عن السقوط - Manual Fall Report
    func reportFall() {
        isFallDetected = true
        NotificationCenter.default.post(name: .fallDetected, object: nil)
    }
    
    // MARK: - Check Motion Activity
    
    /// التحقق من نشاط الحركة - Check Motion Activity
    func checkMotionActivity(completion: @escaping (Bool) -> Void) {
        guard CMMotionActivityManager.isActivityAvailable() else {
            completion(false)
            return
        }
        
        activityManager.queryActivityStarting(from: Date().addingTimeInterval(-60), to: Date(), to: .main) { activities, error in
            if let activities = activities, !activities.isEmpty {
                // التحقق من وجود نشاط حركي
                let hasMovement = activities.contains { activity in
                    activity.walking || activity.running || activity.cycling
                }
                completion(hasMovement)
            } else {
                completion(false)
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let fallDetected = Notification.Name("fallDetected")
}
