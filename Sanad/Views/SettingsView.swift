//
//  SettingsView.swift
//  Sanad
//
//  Settings screen — updated with Dark Mode, HealthKit,
//  iCloud sync, Prayer Times, and Activity Log sections
//

import SwiftUI

struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var cloudSync = CloudSyncManager.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"

    @State private var showGeofenceSetup = false
    @State private var showSyncAlert = false

    var body: some View {
        List {

            // MARK: - Appearance Section
            Section {
                // Font Size
                Picker("حجم الخط", selection: $viewModel.settings.fontSize) {
                    ForEach(FontSize.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .onChange(of: viewModel.settings.fontSize) { _, newValue in
                    viewModel.updateFontSize(newValue)
                }

                // ✅ NEW: Dark Mode picker
                Picker("المظهر", selection: $preferredColorScheme) {
                    Text("تلقائي").tag("system")
                    Text("فاتح").tag("light")
                    Text("داكن").tag("dark")
                }
                .pickerStyle(.segmented)
            } header: {
                SettingsSectionHeader(icon: "paintbrush.fill", title: "المظهر", color: .purple)
            }

            // MARK: - Contacts Section
            Section {
                NavigationLink {
                    ContactsListView()
                } label: {
                    SettingsRow(
                        icon: "person.2.fill",
                        title: "إدارة جهات الاتصال",
                        badge: "\(viewModel.contacts.count)",
                        color: .blue
                    )
                }

                NavigationLink {
                    EmergencyContactsView()
                } label: {
                    SettingsRow(
                        icon: "phone.fill.badge.plus",
                        title: "جهات الاتصال الطارئة",
                        badge: "\(viewModel.emergencyContacts.count)",
                        color: .red
                    )
                }
            } header: {
                SettingsSectionHeader(icon: "person.2.fill", title: "جهات الاتصال", color: .blue)
            }

            // MARK: - Location & Geofence Section
            Section {
                if let homeLocation = viewModel.settings.homeLocation {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("موقع المنزل")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(homeLocation.address ?? "محدد")
                            .font(.body)
                        Button("تغيير الموقع") {
                            showGeofenceSetup = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                } else {
                    Button {
                        showGeofenceSetup = true
                    } label: {
                        SettingsRow(icon: "location.circle", title: "تحديد موقع المنزل", color: .green)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("نطاق السياج الجغرافي: \(Int(viewModel.settings.geofenceRadius)) متر")
                        .font(.subheadline)
                    Slider(
                        value: Binding(
                            get: { viewModel.settings.geofenceRadius },
                            set: { viewModel.updateGeofenceRadius($0) }
                        ),
                        in: 100...2000,
                        step: 100
                    )
                    .tint(.green)
                }
            } header: {
                SettingsSectionHeader(icon: "location.fill", title: "الموقع والسياج الجغرافي", color: .green)
            }

            // MARK: - Safety Section
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.settings.fallDetectionEnabled },
                    set: { viewModel.toggleFallDetection($0) }
                )) {
                    SettingsRow(icon: "figure.fall", title: "كشف السقوط", color: .orange)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("مهلة الطوارئ: \(viewModel.settings.emergencyTimeout) ثانية")
                        .font(.subheadline)
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.settings.emergencyTimeout) },
                            set: { viewModel.updateEmergencyTimeout(Int($0)) }
                        ),
                        in: 10...60,
                        step: 5
                    )
                    .tint(.red)
                }
            } header: {
                SettingsSectionHeader(icon: "shield.fill", title: "الأمان والطوارئ", color: .red)
            }

            // MARK: - Voice Commands Section
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.settings.voiceCommandsEnabled },
                    set: { viewModel.toggleVoiceCommands($0) }
                )) {
                    SettingsRow(icon: "mic.fill", title: "تفعيل الأوامر الصوتية", color: .purple)
                }

                if viewModel.settings.voiceCommandsEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("الأوامر المتاحة:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        CommandRow(command: "اتصل بالعائلة")
                        CommandRow(command: "أرسل موقعي")
                        CommandRow(command: "ساعدني / مساعدة")
                        CommandRow(command: "أدويتي")
                        CommandRow(command: "أوقات الصلاة")
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                SettingsSectionHeader(icon: "mic.fill", title: "الأوامر الصوتية", color: .purple)
            }

            // MARK: - ✅ NEW: Health Section
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.settings.healthKitEnabled },
                    set: { enabled in
                        viewModel.settings.healthKitEnabled = enabled
                        viewModel.saveSettings()
                        if enabled {
                            HealthKitManager.shared.requestAuthorization { _ in }
                        }
                    }
                )) {
                    SettingsRow(icon: "heart.fill", title: "تفعيل بيانات الصحة", color: .pink)
                }

                if viewModel.settings.healthKitEnabled {
                    Button {
                        HealthKitManager.shared.fetchAllHealthData()
                    } label: {
                        SettingsRow(icon: "arrow.clockwise", title: "تحديث بيانات الصحة", color: .pink)
                    }
                }
            } header: {
                SettingsSectionHeader(icon: "heart.fill", title: "الصحة", color: .pink)
            }

            // MARK: - ✅ NEW: Prayer Times Section
            Section {
                NavigationLink {
                    PrayerTimesView()
                } label: {
                    SettingsRow(icon: "moon.stars.fill", title: "أوقات الصلاة والقبلة", color: .indigo)
                }
            } header: {
                SettingsSectionHeader(icon: "moon.stars.fill", title: "أوقات الصلاة", color: .indigo)
            }

            // MARK: - ✅ NEW: iCloud Sync Section
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.settings.iCloudSyncEnabled },
                    set: { enabled in
                        viewModel.settings.iCloudSyncEnabled = enabled
                        viewModel.saveSettings()
                        if enabled {
                            CloudSyncManager.shared.checkCloudAvailability()
                            CloudSyncManager.shared.setupAutoSync()
                        }
                    }
                )) {
                    SettingsRow(icon: "icloud.fill", title: "مزامنة iCloud", color: .blue)
                }

                if viewModel.settings.iCloudSyncEnabled {
                    Button {
                        CloudSyncManager.shared.syncAll()
                    } label: {
                        HStack {
                            SettingsRow(icon: "arrow.triangle.2.circlepath", title: "مزامنة الآن", color: .blue)
                            if cloudSync.isSyncing {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }

                    if let lastSync = cloudSync.lastSyncDate {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("آخر مزامنة: \(lastSync.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let error = cloudSync.syncError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            } header: {
                SettingsSectionHeader(icon: "icloud.fill", title: "المزامنة السحابية", color: .blue)
            }

            // MARK: - ✅ NEW: Activity Log Section
            Section {
                NavigationLink {
                    ActivityLogView()
                } label: {
                    SettingsRow(icon: "list.bullet.clipboard.fill", title: "سجل النشاط", color: .teal)
                }
            } header: {
                SettingsSectionHeader(icon: "list.bullet.clipboard.fill", title: "السجلات", color: .teal)
            }

            // MARK: - About Section
            Section {
                HStack {
                    Text("الإصدار")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("اللغة")
                    Spacer()
                    Text("العربية")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("المطور")
                    Spacer()
                    Text("فريق سند")
                        .foregroundColor(.secondary)
                }
            } header: {
                SettingsSectionHeader(icon: "info.circle.fill", title: "حول التطبيق", color: .gray)
            }

            // MARK: - Danger Zone
            Section {
                Button(role: .destructive) {
                    viewModel.resetSettings()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("إعادة تعيين الإعدادات")
                    }
                }

                Button(role: .destructive) {
                    viewModel.clearAllData()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("مسح جميع البيانات")
                    }
                }
            }
        }
        .navigationTitle("الإعدادات")
        .navigationBarTitleDisplayMode(.large)
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(isPresented: $showGeofenceSetup) {
            GeofenceSetupView(viewModel: viewModel)
        }
    }
}

// MARK: - Settings Section Header

struct SettingsSectionHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            Text(title)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    var badge: String? = nil
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
            Spacer()
            if let badge = badge {
                Text(badge)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
    }
}

// MARK: - Command Row

struct CommandRow: View {
    let command: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.circle.fill")
                .foregroundColor(.purple)
                .font(.caption)
            Text(command)
                .font(.caption)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
}
