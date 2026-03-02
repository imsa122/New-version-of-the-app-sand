//
//  PrayerTimesView.swift
//  Sanad
//
//  Prayer times display with Qibla compass
//  Arabic RTL UI — designed for elderly users
//

import SwiftUI

struct PrayerTimesView: View {

    @StateObject private var manager = PrayerTimesManager.shared
    @State private var showQibla = false
    @State private var notificationsEnabled = false
    @AppStorage("prayerNotificationsEnabled") private var prayerNotificationsEnabled = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: - Header
                headerBanner

                // MARK: - Next Prayer Countdown
                if let next = manager.nextPrayer {
                    nextPrayerCard(next)
                }

                // MARK: - Prayer Times List
                prayerTimesList

                // MARK: - Qibla Section
                qiblaSection

                // MARK: - Notifications Toggle
                notificationsSection
            }
            .padding()
        }
        .navigationTitle("أوقات الصلاة")
        .navigationBarTitleDisplayMode(.large)
        .environment(\.layoutDirection, .rightToLeft)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    manager.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            manager.refresh()
        }
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        HStack(spacing: 15) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 44))
                .foregroundColor(.indigo)

            VStack(alignment: .leading, spacing: 4) {
                Text("أوقات الصلاة")
                    .font(.system(size: 24, weight: .bold))
                Text(todayDateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.indigo.opacity(0.15), Color.purple.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
    }

    // MARK: - Next Prayer Card

    private func nextPrayerCard(_ prayer: Prayer) -> some View {
        VStack(spacing: 12) {
            Text("الصلاة القادمة")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Image(systemName: prayer.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.indigo)

                VStack(alignment: .leading, spacing: 4) {
                    Text(prayer.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Text(prayer.timeString)
                        .font(.title3)
                        .foregroundColor(.indigo)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(manager.timeUntilNextPrayer)
                        .font(.headline)
                        .foregroundColor(.indigo)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.indigo.opacity(0.12), Color.purple.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.indigo.opacity(0.3), lineWidth: 1.5)
        )
    }

    // MARK: - Prayer Times List

    private var prayerTimesList: some View {
        VStack(spacing: 0) {
            ForEach(manager.prayerTimes) { prayer in
                PrayerTimeRow(
                    prayer: prayer,
                    isNext: manager.nextPrayer?.key == prayer.key
                )

                if prayer.key != manager.prayerTimes.last?.key {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }

    // MARK: - Qibla Section

    private var qiblaSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("اتجاه القبلة")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                if manager.currentLocation != nil {
                    Text("\(Int(manager.qiblaDirection))°")
                        .font(.headline)
                        .foregroundColor(.indigo)
                } else {
                    Text("الموقع غير متوفر")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if manager.currentLocation != nil {
                // ✅ Fix: Pass both qiblaDirection and deviceHeading for live compass
                QiblaCompassView(
                    direction: manager.qiblaDirection,
                    deviceHeading: manager.deviceHeading
                )
                .frame(height: 220)
            } else {
                // Show placeholder when location is not available
                VStack(spacing: 12) {
                    Image(systemName: "location.slash.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("يرجى تفعيل خدمة الموقع لعرض اتجاه القبلة")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 120)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $prayerNotificationsEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.indigo)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("تنبيهات أوقات الصلاة")
                            .font(.headline)
                        Text("استقبل إشعاراً عند كل وقت صلاة")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onChange(of: prayerNotificationsEnabled) { _, enabled in
                if enabled {
                    manager.schedulePrayerNotifications()
                } else {
                    manager.cancelPrayerNotifications()
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }

    // MARK: - Helpers

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
}

// MARK: - Prayer Time Row

struct PrayerTimeRow: View {

    let prayer: Prayer
    let isNext: Bool

    var body: some View {
        HStack(spacing: 16) {

            // Icon
            ZStack {
                Circle()
                    .fill(isNext ? Color.indigo.opacity(0.15) : Color.gray.opacity(0.08))
                    .frame(width: 48, height: 48)
                Image(systemName: prayer.icon)
                    .font(.title3)
                    .foregroundColor(isNext ? .indigo : (prayer.isPassed ? .gray : .primary))
            }

            // Name
            Text(prayer.name)
                .font(.system(size: 20, weight: isNext ? .bold : .regular))
                .foregroundColor(prayer.isPassed ? .secondary : .primary)

            Spacer()

            // Time
            Text(prayer.timeString)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isNext ? .indigo : (prayer.isPassed ? .secondary : .primary))

            // Next indicator
            if isNext {
                Image(systemName: "chevron.left.circle.fill")
                    .foregroundColor(.indigo)
                    .font(.title3)
            } else if prayer.isPassed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(isNext ? Color.indigo.opacity(0.05) : Color.clear)
    }
}

// MARK: - Qibla Compass View

struct QiblaCompassView: View {

    let direction: Double      // Qibla bearing from North (degrees)
    let deviceHeading: Double  // ✅ Fix: Live device compass heading (degrees)

    /// ✅ Fix: Needle rotation = qiblaDirection - deviceHeading
    /// This makes the needle always point toward Qibla regardless of device orientation
    private var needleRotation: Double {
        (direction - deviceHeading + 360).truncatingRemainder(dividingBy: 360)
    }

    var body: some View {
        ZStack {
            // Compass background
            Circle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 12)

            // Compass ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.6), Color.purple.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3
                )
                .padding(8)

            // ✅ Fix: Cardinal directions rotate OPPOSITE to device heading
            // so they stay fixed relative to the real world
            ForEach(["ش", "ق", "ج", "غ"], id: \.self) { dir in
                let index = ["ش", "ق", "ج", "غ"].firstIndex(of: dir)!
                let angle = Double(index) * 90.0
                Text(dir)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                    .offset(
                        x: sin(angle * .pi / 180) * 80,
                        y: -cos(angle * .pi / 180) * 80
                    )
            }
            .rotationEffect(.degrees(-deviceHeading))
            .animation(.easeInOut(duration: 0.3), value: deviceHeading)

            // Qibla needle — always points toward Qibla
            VStack(spacing: 0) {
                // Kaaba icon at tip
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.indigo)
                    .clipShape(Circle())

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.indigo, Color.indigo.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: 65)

                Circle()
                    .fill(Color.indigo.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
            .rotationEffect(.degrees(needleRotation))
            .animation(.easeInOut(duration: 0.3), value: needleRotation)

            // Center dot
            Circle()
                .fill(Color.indigo)
                .frame(width: 12, height: 12)

            // Direction label + accuracy hint
            VStack {
                Spacer()
                VStack(spacing: 2) {
                    Text("اتجاه الكعبة المشرفة")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if deviceHeading == 0 {
                        Text("وجّه الجهاز نحو الشمال للمعايرة")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrayerTimesView()
    }
}
