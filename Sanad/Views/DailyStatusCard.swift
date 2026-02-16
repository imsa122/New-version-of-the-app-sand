import SwiftUI

struct DailyStatusCard: View {
    
    var hasTakenMedicationToday: Bool
    var isInsideHomeArea: Bool
    var hasActiveAlert: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            Text("حالة اليوم")
                .font(.system(size: 22, weight: .bold))
            
            statusRow(
                icon: "pills.fill",
                text: hasTakenMedicationToday ? "تم أخذ الأدوية اليوم" : "لم يتم أخذ الأدوية بعد",
                color: hasTakenMedicationToday ? .green : .orange
            )
            
            statusRow(
                icon: "house.fill",
                text: isInsideHomeArea ? "داخل منطقة المنزل" : "خارج منطقة المنزل",
                color: isInsideHomeArea ? .green : .red
            )
            
            statusRow(
                icon: "shield.fill",
                text: hasActiveAlert ? "يوجد تنبيه نشط" : "لا توجد تنبيهات",
                color: hasActiveAlert ? .red : .green
            )
            
            Text("آخر تحديث: الآن")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    private func statusRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(text)
                .font(.system(size: 18))
            
            Spacer()
        }
    }
}
