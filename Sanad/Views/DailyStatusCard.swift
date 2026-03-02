import SwiftUI

struct DailyStatusCard: View {
    
    @ObservedObject private var tracker = MedicationTrackingManager.shared
    
    var isInsideHomeArea: Bool
    var hasActiveAlert: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            
            Text("حالة اليوم")
                .font(.system(size: 26, weight: .bold))
            
            // 💊 حالة الأدوية
            statusRow(
                icon: "pills.fill",
                text: tracker.hasTakenMedicationToday
                ? "تم أخذ الأدوية اليوم"
                : "لم يتم أخذ الأدوية بعد",
                color: tracker.hasTakenMedicationToday ? .green : .orange
            )
            
            // 🏠 حالة الموقع
            statusRow(
                icon: "house.fill",
                text: isInsideHomeArea
                ? "داخل منطقة المنزل"
                : "خارج منطقة المنزل",
                color: isInsideHomeArea ? .green : .red
            )
            
            // 🛡 حالة التنبيهات
            statusRow(
                icon: "shield.fill",
                text: hasActiveAlert
                ? "يوجد تنبيه نشط"
                : "لا توجد تنبيهات",
                color: hasActiveAlert ? .red : .green
            )
            
            Divider()
            
            // 🕒 وقت آخر جرعة
            if let lastTime = tracker.lastTakenTimeToday {
                Text("آخر جرعة: \(formatTime(lastTime))")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            // 🕒 آخر تحديث فعلي (الآن)
            Text("آخر تحديث: \(formatTime(Date()))")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    // MARK: - Background
    
    private var backgroundColor: Color {
        tracker.hasTakenMedicationToday
        ? Color.white
        : Color.orange.opacity(0.08)
    }
    
    // MARK: - Status Row
    
    private func statusRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(text)
                .font(.system(size: 20))
            
            Spacer()
        }
    }
    
    // MARK: - Format Time
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
