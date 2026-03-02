//
//  HealthDashboardView.swift
//  Sanad
//
//  Health dashboard showing steps, heart rate, and sleep data
//  Designed for elderly users — large cards, Arabic RTL
//

import SwiftUI

struct HealthDashboardView: View {

    @StateObject private var healthKit = HealthKitManager.shared
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: - Header Banner
                headerBanner

                if !healthKit.isAvailable {
                    // HealthKit not available (simulator or iPad without Health)
                    unavailableView
                } else if !healthKit.isAuthorized {
                    // Not yet authorized
                    authorizationView
                } else {
                    // MARK: - Health Cards
                    stepsCard
                    heartRateCard
                    sleepCard
                    lastUpdatedView
                }
            }
            .padding()
        }
        .navigationTitle("لوحة الصحة")
        .navigationBarTitleDisplayMode(.large)
        .environment(\.layoutDirection, .rightToLeft)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    refreshData()
                } label: {
                    Image(systemName: isRefreshing ? "arrow.clockwise.circle.fill" : "arrow.clockwise")
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
            }
        }
        .onAppear {
            if healthKit.isAvailable {
                if healthKit.isAuthorized {
                    // Already authorized — just refresh data
                    healthKit.fetchAllHealthData()
                } else {
                    // ✅ Fix: Auto-request authorization when Health Dashboard opens
                    // iOS will only show the permission dialog once; subsequent calls are no-ops
                    healthKit.requestAuthorization { _ in }
                }
            }
        }
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        HStack(spacing: 15) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 44))
                .foregroundColor(.pink)

            VStack(alignment: .leading, spacing: 4) {
                Text("لوحة الصحة")
                    .font(.system(size: 24, weight: .bold))
                Text("تابع صحتك اليومية")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.pink.opacity(0.15), Color.red.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
    }

    // MARK: - Steps Card

    private var stepsCard: some View {
        HealthMetricCard(
            icon: "figure.walk",
            title: "الخطوات اليومية",
            value: "\(healthKit.dailySteps.formatted())",
            unit: "خطوة",
            assessment: healthKit.stepsAssessment.arabicLabel,
            color: stepsColor,
            target: "الهدف: 5,000 خطوة",
            progress: min(Double(healthKit.dailySteps) / 5000.0, 1.0)
        )
    }

    private var stepsColor: Color {
        switch healthKit.stepsAssessment {
        case .low:       return .red
        case .moderate:  return .orange
        case .good:      return .green
        case .excellent: return .blue
        }
    }

    // MARK: - Heart Rate Card

    private var heartRateCard: some View {
        HealthMetricCard(
            icon: "heart.fill",
            title: "معدل ضربات القلب",
            value: healthKit.heartRate > 0 ? "\(Int(healthKit.heartRate))" : "--",
            unit: "نبضة/دقيقة",
            assessment: healthKit.heartRateAssessment.arabicLabel,
            color: heartRateColor,
            target: "الطبيعي: 60-100 نبضة/دقيقة",
            progress: nil
        )
    }

    private var heartRateColor: Color {
        switch healthKit.heartRateAssessment {
        case .unknown: return .gray
        case .low:     return .blue
        case .normal:  return .green
        case .high:    return .red
        }
    }

    // MARK: - Sleep Card

    private var sleepCard: some View {
        HealthMetricCard(
            icon: "moon.zzz.fill",
            title: "ساعات النوم",
            value: String(format: "%.1f", healthKit.sleepHours),
            unit: "ساعة",
            assessment: healthKit.sleepAssessment.arabicLabel,
            color: sleepColor,
            target: "الموصى به: 7-8 ساعات",
            progress: min(healthKit.sleepHours / 8.0, 1.0)
        )
    }

    private var sleepColor: Color {
        switch healthKit.sleepAssessment {
        case .poor:    return .red
        case .fair:    return .orange
        case .good:    return .green
        case .tooMuch: return .purple
        }
    }

    // MARK: - Last Updated

    private var lastUpdatedView: some View {
        Group {
            if let lastUpdated = healthKit.lastUpdated {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("آخر تحديث: \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Authorization View

    private var authorizationView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.pink)

            Text("اتصل بتطبيق الصحة")
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)

            Text("للاستفادة من لوحة الصحة، نحتاج إذنك للوصول لبيانات الصحة من تطبيق Apple Health")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                healthKit.requestAuthorization { _ in }
            } label: {
                HStack {
                    Image(systemName: "heart.fill")
                    Text("منح الإذن")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.pink)
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Unavailable View

    private var unavailableView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 70))
                .foregroundColor(.gray)

            Text("HealthKit غير متوفر")
                .font(.title2.bold())

            Text("تطبيق الصحة غير متوفر على هذا الجهاز")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    // MARK: - Refresh

    private func refreshData() {
        isRefreshing = true
        healthKit.fetchAllHealthData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isRefreshing = false
        }
    }
}

// MARK: - Health Metric Card

struct HealthMetricCard: View {

    let icon: String
    let title: String
    let value: String
    let unit: String
    let assessment: String
    let color: Color
    let target: String
    let progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header row
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(assessment)
                        .font(.subheadline)
                        .foregroundColor(color)
                        .fontWeight(.medium)
                }

                Spacer()

                // Value badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(color)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar (if applicable)
            if let progress = progress {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(color.opacity(0.15))
                                .frame(height: 10)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(color)
                                .frame(width: geo.size.width * progress, height: 10)
                                .animation(.easeInOut(duration: 0.8), value: progress)
                        }
                    }
                    .frame(height: 10)

                    Text(target)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(target)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HealthDashboardView()
    }
}
