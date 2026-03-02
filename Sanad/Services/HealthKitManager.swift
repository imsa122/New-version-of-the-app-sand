//
//  HealthKitManager.swift
//  Sanad
//
//  HealthKit integration — reads steps, heart rate, and sleep data
//  Requires HealthKit capability in Xcode project settings
//

import Foundation
import HealthKit
import Combine

/// مدير بيانات الصحة - HealthKit Manager
class HealthKitManager: ObservableObject {

    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    // MARK: - Published Health Data

    @Published var dailySteps: Int = 0
    @Published var heartRate: Double = 0.0
    @Published var sleepHours: Double = 0.0
    @Published var isAuthorized: Bool = false
    @Published var isAvailable: Bool = false
    @Published var lastUpdated: Date?

    // MARK: - HealthKit Types

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }()

    // ✅ Fix: UserDefaults key to persist authorization state across launches
    private let authRequestedKey = "healthKitAuthRequested"

    // MARK: - Init

    private init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()

        // ✅ Fix: If we've previously requested authorization, restore isAuthorized = true
        // HealthKit doesn't expose read authorization status directly (privacy),
        // so we track whether the user went through the permission dialog.
        if isAvailable && UserDefaults.standard.bool(forKey: authRequestedKey) {
            isAuthorized = true
            fetchAllHealthData()
        }
    }

    // MARK: - Authorization

    /// طلب إذن الوصول لبيانات الصحة - Request HealthKit Authorization
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit غير متوفر على هذا الجهاز")
            completion(false)
            return
        }

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ خطأ في طلب إذن HealthKit: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                // ✅ Fix: Persist that we've requested authorization
                // Show health data even if some types were denied (HealthKit privacy model)
                UserDefaults.standard.set(true, forKey: self?.authRequestedKey ?? "healthKitAuthRequested")
                self?.isAuthorized = true

                print(granted ? "✅ تم منح إذن HealthKit" : "⚠️ بعض أذونات HealthKit مرفوضة — سيتم عرض البيانات المتاحة")
                self?.fetchAllHealthData()
                completion(true)
            }
        }
    }

    // MARK: - Fetch All Data

    /// جلب جميع بيانات الصحة - Fetch All Health Data
    func fetchAllHealthData() {
        fetchDailySteps()
        fetchHeartRate()
        fetchSleepHours()
        lastUpdated = Date()
    }

    // MARK: - Steps

    /// جلب عدد الخطوات اليومية - Fetch Daily Steps
    func fetchDailySteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )

        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ خطأ في جلب الخطوات: \(error.localizedDescription)")
                    return
                }
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                self?.dailySteps = Int(steps)
                print("👟 الخطوات اليومية: \(Int(steps))")
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Heart Rate

    /// جلب معدل ضربات القلب - Fetch Heart Rate
    func fetchHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ خطأ في جلب معدل القلب: \(error.localizedDescription)")
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else { return }
                let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                self?.heartRate = bpm
                print("❤️ معدل ضربات القلب: \(Int(bpm)) نبضة/دقيقة")
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Sleep

    /// جلب ساعات النوم - Fetch Sleep Hours
    func fetchSleepHours() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let startOfYesterday = Calendar.current.startOfDay(for: yesterday)
        let endOfToday = Date()

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfYesterday,
            end: endOfToday,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ خطأ في جلب بيانات النوم: \(error.localizedDescription)")
                    return
                }

                guard let samples = samples as? [HKCategorySample] else { return }

                // حساب إجمالي ساعات النوم (asleepUnspecified + asleepCore + asleepDeep + asleepREM)
                let totalSleepSeconds = samples
                    .filter { sample in
                        sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                let hours = totalSleepSeconds / 3600.0
                self?.sleepHours = min(hours, 24.0) // cap at 24 hours
                print("😴 ساعات النوم: \(String(format: "%.1f", hours)) ساعة")
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Helpers

    /// تقييم عدد الخطوات - Steps Assessment
    var stepsAssessment: StepsAssessment {
        switch dailySteps {
        case 0..<2000:   return .low
        case 2000..<5000: return .moderate
        case 5000..<10000: return .good
        default:          return .excellent
        }
    }

    /// تقييم معدل القلب - Heart Rate Assessment
    var heartRateAssessment: HeartRateAssessment {
        switch heartRate {
        case 0:          return .unknown
        case ..<60:      return .low
        case 60...100:   return .normal
        default:         return .high
        }
    }

    /// تقييم النوم - Sleep Assessment
    var sleepAssessment: SleepAssessment {
        switch sleepHours {
        case 0..<4:   return .poor
        case 4..<6:   return .fair
        case 6...9:   return .good
        default:      return .tooMuch
        }
    }
}

// MARK: - Assessment Enums

enum StepsAssessment {
    case low, moderate, good, excellent

    var arabicLabel: String {
        switch self {
        case .low:       return "منخفض"
        case .moderate:  return "متوسط"
        case .good:      return "جيد"
        case .excellent: return "ممتاز"
        }
    }

    var color: String {
        switch self {
        case .low:       return "red"
        case .moderate:  return "orange"
        case .good:      return "green"
        case .excellent: return "blue"
        }
    }
}

enum HeartRateAssessment {
    case unknown, low, normal, high

    var arabicLabel: String {
        switch self {
        case .unknown: return "غير متوفر"
        case .low:     return "منخفض"
        case .normal:  return "طبيعي"
        case .high:    return "مرتفع"
        }
    }
}

enum SleepAssessment {
    case poor, fair, good, tooMuch

    var arabicLabel: String {
        switch self {
        case .poor:    return "غير كافٍ"
        case .fair:    return "مقبول"
        case .good:    return "جيد"
        case .tooMuch: return "كثير"
        }
    }
}
