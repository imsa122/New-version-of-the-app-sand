import SwiftUI
import PDFKit

struct ActivityLogView: View {
    
    @State private var logs: [ActivityLog] = ActivityLogger.shared.getAllLogs()
    @State private var selectedFilter: FilterType = .all
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    
    enum FilterType: String, CaseIterable {
        case all = "الكل"
        case today = "اليوم"
    }
    
    var body: some View {
        VStack {
            
            // 📊 بطاقات الإحصائيات
            statisticsCards
            
            // 🔹 الفلترة
            Picker("فلترة", selection: $selectedFilter) {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            List(filteredLogs) { log in
                ActivityLogRow(log: log)
            }
            .listStyle(.plain)
        }
        .navigationTitle("سجل النشاط")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    exportPDF()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .activityLogged)) { _ in
            logs = ActivityLogger.shared.getAllLogs()
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL {
                ShareSheet(activityItems: [pdfURL])
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    // MARK: - Statistics
    
    private var statisticsCards: some View {
        let stats = ActivityLogger.shared.getStatistics()
        
        return HStack(spacing: 15) {
            
            StatCard(
                title: "حرج",
                count: stats.criticalCount,
                color: .red
            )
            
            StatCard(
                title: "تفويت",
                count: stats.medicationMissedCount,
                color: .orange
            )
            
            StatCard(
                title: "تم تناول",
                count: stats.medicationTakenCount,
                color: .green
            )
        }
        .padding()
    }
    
    private var filteredLogs: [ActivityLog] {
        switch selectedFilter {
        case .all:
            return logs
        case .today:
            return ActivityLogger.shared.getLogsForToday()
        }
    }
}
struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color)
        .cornerRadius(16)
    }
}
extension ActivityLogView {
    
private func exportPDF() {
    
    let logs = filteredLogs
    let stats = ActivityLogger.shared.getStatistics(for: logs)
    
    let format = UIGraphicsPDFRendererFormat()
    let pageWidth: CGFloat = 595
    let pageHeight: CGFloat = 842
    
    let renderer = UIGraphicsPDFRenderer(
        bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
        format: format
    )
    
    let data = renderer.pdfData { context in
        
        context.beginPage()
        
        var yPosition: CGFloat = 30
        
        // 🔹 الشعار
        if let logo = UIImage(named: "sanadlogo") {
            logo.draw(in: CGRect(x: pageWidth - 100, y: yPosition, width: 60, height: 60))
        }
        
        // 🔹 العنوان
        let title = "تقرير سجل النشاط"
        title.draw(
            at: CGPoint(x: 40, y: yPosition + 20),
            withAttributes: [.font: UIFont.boldSystemFont(ofSize: 24)]
        )
        
        yPosition += 90
        
        // 🔹 معلومات التقرير
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let infoText = """
تاريخ الإنشاء: \(formatter.string(from: Date()))
الفترة: \(selectedFilter.rawValue)
عدد السجلات: \(logs.count)
"""
        
        infoText.draw(
            in: CGRect(x: 40, y: yPosition, width: pageWidth - 80, height: 60),
            withAttributes: [.font: UIFont.systemFont(ofSize: 14)]
        )
        
        yPosition += 80
        
        // 🔹 ملخص إحصائي
        let statsText = """
ملخص:
حالات حرجة: \(stats.criticalCount)
تفويت أدوية: \(stats.medicationMissedCount)
أدوية تم تناولها: \(stats.medicationTakenCount)
"""
        
        statsText.draw(
            in: CGRect(x: 40, y: yPosition, width: pageWidth - 80, height: 80),
            withAttributes: [.font: UIFont.systemFont(ofSize: 15)]
        )
        
        yPosition += 100
        
        // 🔹 خط فاصل
        UIBezierPath(rect: CGRect(x: 40, y: yPosition, width: pageWidth - 80, height: 1))
            .fill()
        
        yPosition += 20
        
        // 🔹 السجلات
        for log in logs {
            
            let logText = """
\(log.formattedDateTime)
\(log.title)
\(log.description)
------------------------------------
"""
            
            logText.draw(
                in: CGRect(x: 40, y: yPosition, width: pageWidth - 80, height: 100),
                withAttributes: [.font: UIFont.systemFont(ofSize: 13)]
            )
            
            yPosition += 80
            
            if yPosition > pageHeight - 100 {
                context.beginPage()
                yPosition = 40
            }
        }
        
        // 🔹 تذييل
        let footer = "تم إنشاء التقرير بواسطة تطبيق سند"
        footer.draw(
            at: CGPoint(x: 40, y: pageHeight - 40),
            withAttributes: [.font: UIFont.italicSystemFont(ofSize: 12)]
        )
    }
    
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("Sanad_Report.pdf")
    
    try? data.write(to: url)
    
    pdfURL = url
    showShareSheet = true
}

struct ShareSheet: UIViewControllerRepresentable {
    
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
