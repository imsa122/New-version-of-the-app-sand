//
//  HealthCheckIn.swift
//  Sanad
//
//  Daily health check-in system for wellness tracking
//  Tracks mood, symptoms, pain, sleep, and energy levels
//

import Foundation

/// الفحص الصحي اليومي - Health Check-In
struct HealthCheckIn: Codable, Identifiable {
    
    let id: UUID
    let date: Date
    var mood: Mood
    var symptoms: [Symptom]
    var painLevel: Int // 0-10
    var sleepQuality: Int // 0-10
    var energyLevel: Int // 0-10
    var appetite: Appetite
    var notes: String
    var medications: [String] // Medications taken today
    var activities: [String] // Activities done today
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mood: Mood = .neutral,
        symptoms: [Symptom] = [],
        painLevel: Int = 0,
        sleepQuality: Int = 5,
        energyLevel: Int = 5,
        appetite: Appetite = .normal,
        notes: String = "",
        medications: [String] = [],
        activities: [String] = []
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.symptoms = symptoms
        self.painLevel = painLevel
        self.sleepQuality = sleepQuality
        self.energyLevel = energyLevel
        self.appetite = appetite
        self.notes = notes
        self.medications = medications
        self.activities = activities
    }
    
    // MARK: - Computed Properties
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: date)
    }
    
    var overallScore: Int {
        // Calculate overall health score (0-100)
        let moodScore = mood.score
        let painScore = 10 - painLevel
        let sleepScore = sleepQuality
        let energyScore = energyLevel
        let appetiteScore = appetite.score
        let symptomScore = max(0, 10 - symptoms.count)
        
        let total = moodScore + painScore + sleepScore + energyScore + appetiteScore + symptomScore
        return Int((Double(total) / 60.0) * 100)
    }
    
    var overallStatus: HealthStatus {
        switch overallScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .fair
        case 20..<40: return .poor
        default: return .critical
        }
    }
    
    var hasConcerns: Bool {
        return painLevel >= 7 || sleepQuality <= 3 || energyLevel <= 3 || symptoms.count >= 3
    }
}

// MARK: - Mood

enum Mood: String, Codable, CaseIterable {
    case veryHappy = "very_happy"
    case happy = "happy"
    case neutral = "neutral"
    case sad = "sad"
    case verySad = "very_sad"
    case anxious = "anxious"
    case stressed = "stressed"
    case calm = "calm"
    
    var displayName: String {
        switch self {
        case .veryHappy: return "سعيد جداً"
        case .happy: return "سعيد"
        case .neutral: return "عادي"
        case .sad: return "حزين"
        case .verySad: return "حزين جداً"
        case .anxious: return "قلق"
        case .stressed: return "متوتر"
        case .calm: return "هادئ"
        }
    }
    
    var emoji: String {
        switch self {
        case .veryHappy: return "😊"
        case .happy: return "🙂"
        case .neutral: return "😐"
        case .sad: return "😔"
        case .verySad: return "😢"
        case .anxious: return "😰"
        case .stressed: return "😫"
        case .calm: return "😌"
        }
    }
    
    var color: String {
        switch self {
        case .veryHappy, .happy, .calm: return "green"
        case .neutral: return "blue"
        case .sad, .anxious: return "orange"
        case .verySad, .stressed: return "red"
        }
    }
    
    var score: Int {
        switch self {
        case .veryHappy, .calm: return 10
        case .happy: return 8
        case .neutral: return 6
        case .sad, .anxious: return 4
        case .verySad, .stressed: return 2
        }
    }
}

// MARK: - Symptom

struct Symptom: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let severity: Int // 1-10
    let duration: SymptomDuration
    let notes: String
    
    init(
        id: UUID = UUID(),
        name: String,
        severity: Int,
        duration: SymptomDuration,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.severity = severity
        self.duration = duration
        self.notes = notes
    }
    
    var severityLevel: SeverityLevel {
        switch severity {
        case 1...3: return .mild
        case 4...6: return .moderate
        case 7...10: return .severe
        default: return .mild
        }
    }
}

enum SymptomDuration: String, Codable, CaseIterable {
    case lessThanHour = "less_than_hour"
    case fewHours = "few_hours"
    case halfDay = "half_day"
    case fullDay = "full_day"
    case multipleDays = "multiple_days"
    case chronic = "chronic"
    
    var displayName: String {
        switch self {
        case .lessThanHour: return "أقل من ساعة"
        case .fewHours: return "بضع ساعات"
        case .halfDay: return "نصف يوم"
        case .fullDay: return "يوم كامل"
        case .multipleDays: return "عدة أيام"
        case .chronic: return "مزمن"
        }
    }
}

enum SeverityLevel: String, Codable {
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"
    
    var displayName: String {
        switch self {
        case .mild: return "خفيف"
        case .moderate: return "متوسط"
        case .severe: return "شديد"
        }
    }
    
    var color: String {
        switch self {
        case .mild: return "yellow"
        case .moderate: return "orange"
        case .severe: return "red"
        }
    }
}

// MARK: - Common Symptoms

enum CommonSymptom: String, CaseIterable {
    case headache = "صداع"
    case dizziness = "دوخة"
    case nausea = "غثيان"
    case fatigue = "إرهاق"
    case chestPain = "ألم في الصدر"
    case backPain = "ألم في الظهر"
    case jointPain = "ألم في المفاصل"
    case shortnessOfBreath = "ضيق في التنفس"
    case cough = "سعال"
    case fever = "حمى"
    case chills = "قشعريرة"
    case sweating = "تعرق"
    case weakness = "ضعف"
    case confusion = "ارتباك"
    case visionProblems = "مشاكل في الرؤية"
    case hearingProblems = "مشاكل في السمع"
    case stomachPain = "ألم في المعدة"
    case constipation = "إمساك"
    case diarrhea = "إسهال"
    case urinaryProblems = "مشاكل في التبول"
    
    var icon: String {
        switch self {
        case .headache: return "brain"
        case .dizziness: return "arrow.triangle.2.circlepath"
        case .nausea: return "stomach"
        case .fatigue: return "bed.double"
        case .chestPain: return "heart.fill"
        case .backPain: return "figure.stand"
        case .jointPain: return "figure.walk"
        case .shortnessOfBreath: return "lungs.fill"
        case .cough: return "wind"
        case .fever: return "thermometer"
        case .chills: return "snowflake"
        case .sweating: return "drop.fill"
        case .weakness: return "figure.fall"
        case .confusion: return "brain.head.profile"
        case .visionProblems: return "eye.fill"
        case .hearingProblems: return "ear.fill"
        case .stomachPain: return "stomach.fill"
        case .constipation, .diarrhea: return "toilet.fill"
        case .urinaryProblems: return "drop.triangle.fill"
        }
    }
}

// MARK: - Appetite

enum Appetite: String, Codable, CaseIterable {
    case veryGood = "very_good"
    case good = "good"
    case normal = "normal"
    case poor = "poor"
    case veryPoor = "very_poor"
    
    var displayName: String {
        switch self {
        case .veryGood: return "ممتازة"
        case .good: return "جيدة"
        case .normal: return "عادية"
        case .poor: return "ضعيفة"
        case .veryPoor: return "ضعيفة جداً"
        }
    }
    
    var emoji: String {
        switch self {
        case .veryGood: return "🍽️"
        case .good: return "🍴"
        case .normal: return "🥄"
        case .poor: return "🥤"
        case .veryPoor: return "💧"
        }
    }
    
    var score: Int {
        switch self {
        case .veryGood: return 10
        case .good: return 8
        case .normal: return 6
        case .poor: return 4
        case .veryPoor: return 2
        }
    }
}

// MARK: - Health Status

enum HealthStatus: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .excellent: return "ممتاز"
        case .good: return "جيد"
        case .fair: return "مقبول"
        case .poor: return "ضعيف"
        case .critical: return "حرج"
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent: return "💚"
        case .good: return "💙"
        case .fair: return "💛"
        case .poor: return "🧡"
        case .critical: return "❤️"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - Health Trends

struct HealthTrends: Codable {
    let checkIns: [HealthCheckIn]
    
    var averageMoodScore: Double {
        guard !checkIns.isEmpty else { return 0 }
        let total = checkIns.reduce(0) { $0 + $1.mood.score }
        return Double(total) / Double(checkIns.count)
    }
    
    var averagePainLevel: Double {
        guard !checkIns.isEmpty else { return 0 }
        let total = checkIns.reduce(0) { $0 + $1.painLevel }
        return Double(total) / Double(checkIns.count)
    }
    
    var averageSleepQuality: Double {
        guard !checkIns.isEmpty else { return 0 }
        let total = checkIns.reduce(0) { $0 + $1.sleepQuality }
        return Double(total) / Double(checkIns.count)
    }
    
    var averageEnergyLevel: Double {
        guard !checkIns.isEmpty else { return 0 }
        let total = checkIns.reduce(0) { $0 + $1.energyLevel }
        return Double(total) / Double(checkIns.count)
    }
    
    var averageOverallScore: Double {
        guard !checkIns.isEmpty else { return 0 }
        let total = checkIns.reduce(0) { $0 + $1.overallScore }
        return Double(total) / Double(checkIns.count)
    }
    
    var mostCommonSymptoms: [String] {
        var symptomCounts: [String: Int] = [:]
        
        for checkIn in checkIns {
            for symptom in checkIn.symptoms {
                symptomCounts[symptom.name, default: 0] += 1
            }
        }
        
        return symptomCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    var moodTrend: Trend {
        guard checkIns.count >= 2 else { return .stable }
        
        let recent = checkIns.prefix(3).map { $0.mood.score }
        let older = checkIns.dropFirst(3).prefix(3).map { $0.mood.score }
        
        guard !recent.isEmpty && !older.isEmpty else { return .stable }
        
        let recentAvg = Double(recent.reduce(0, +)) / Double(recent.count)
        let olderAvg = Double(older.reduce(0, +)) / Double(older.count)
        
        let difference = recentAvg - olderAvg
        
        if difference > 1 { return .improving }
        if difference < -1 { return .declining }
        return .stable
    }
    
    var painTrend: Trend {
        guard checkIns.count >= 2 else { return .stable }
        
        let recent = checkIns.prefix(3).map { $0.painLevel }
        let older = checkIns.dropFirst(3).prefix(3).map { $0.painLevel }
        
        guard !recent.isEmpty && !older.isEmpty else { return .stable }
        
        let recentAvg = Double(recent.reduce(0, +)) / Double(recent.count)
        let olderAvg = Double(older.reduce(0, +)) / Double(older.count)
        
        let difference = recentAvg - olderAvg
        
        if difference < -1 { return .improving }
        if difference > 1 { return .declining }
        return .stable
    }
}

enum Trend: String, Codable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    
    var displayName: String {
        switch self {
        case .improving: return "يتحسن"
        case .stable: return "مستقر"
        case .declining: return "يتراجع"
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "arrow.right.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .improving: return "green"
        case .stable: return "blue"
        case .declining: return "red"
        }
    }
}

// MARK: - Health Recommendations

struct HealthRecommendation {
    let title: String
    let description: String
    let priority: Priority
    let icon: String
    
    enum Priority {
        case high
        case medium
        case low
        
        var color: String {
            switch self {
            case .high: return "red"
            case .medium: return "orange"
            case .low: return "blue"
            }
        }
    }
    
    static func generateRecommendations(for checkIn: HealthCheckIn) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // Pain recommendations
        if checkIn.painLevel >= 7 {
            recommendations.append(HealthRecommendation(
                title: "ألم شديد",
                description: "يُنصح بالتواصل مع الطبيب بخصوص الألم الشديد",
                priority: .high,
                icon: "exclamationmark.triangle.fill"
            ))
        }
        
        // Sleep recommendations
        if checkIn.sleepQuality <= 3 {
            recommendations.append(HealthRecommendation(
                title: "نوم سيء",
                description: "حاول تحسين جودة النوم بالنوم في وقت منتظم",
                priority: .medium,
                icon: "bed.double.fill"
            ))
        }
        
        // Energy recommendations
        if checkIn.energyLevel <= 3 {
            recommendations.append(HealthRecommendation(
                title: "طاقة منخفضة",
                description: "تأكد من الحصول على راحة كافية وتناول طعام صحي",
                priority: .medium,
                icon: "bolt.fill"
            ))
        }
        
        // Mood recommendations
        if checkIn.mood == .verySad || checkIn.mood == .stressed {
            recommendations.append(HealthRecommendation(
                title: "مزاج منخفض",
                description: "تحدث مع أحبائك أو متخصص إذا استمر الشعور",
                priority: .high,
                icon: "heart.fill"
            ))
        }
        
        // Symptoms recommendations
        if checkIn.symptoms.count >= 3 {
            recommendations.append(HealthRecommendation(
                title: "أعراض متعددة",
                description: "يُنصح بمراجعة الطبيب لتقييم الأعراض",
                priority: .high,
                icon: "stethoscope"
            ))
        }
        
        return recommendations
    }
}
