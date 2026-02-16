//
//  SettingsView.swift
//  Sanad
//
//  Settings screen for app configuration
//

import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showContactsView = false
    @State private var showGeofenceSetup = false
    
    var body: some View {
        List {
            // قسم المظهر - Appearance Section
            Section("المظهر") {
                Picker("حجم الخط", selection: $viewModel.settings.fontSize) {
                    ForEach(FontSize.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .onChange(of: viewModel.settings.fontSize) { _, newValue in
                    viewModel.updateFontSize(newValue)
                }
            }
            
            // قسم جهات الاتصال - Contacts Section
            Section("جهات الاتصال") {
                NavigationLink {
                    ContactsListView()
                } label: {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                        Text("إدارة جهات الاتصال")
                        Spacer()
                        Text("\(viewModel.contacts.count)")
                            .foregroundColor(.gray)
                    }
                }
                
                NavigationLink {
                    EmergencyContactsView()
                } label: {
                    HStack {
                        Image(systemName: "phone.fill.badge.plus")
                            .foregroundColor(.red)
                        Text("جهات الاتصال الطارئة")
                        Spacer()
                        Text("\(viewModel.emergencyContacts.count)")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // قسم الموقع - Location Section
            Section("الموقع والسياج الجغرافي") {
                if let homeLocation = viewModel.settings.homeLocation {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("موقع المنزل")
                            .font(.caption)
                            .foregroundColor(.gray)
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
                        HStack {
                            Image(systemName: "location.circle")
                                .foregroundColor(.green)
                            Text("تحديد موقع المنزل")
                        }
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("نطاق السياج الجغرافي: \(Int(viewModel.settings.geofenceRadius)) متر")
                    Slider(
                        value: Binding(
                            get: { viewModel.settings.geofenceRadius },
                            set: { viewModel.updateGeofenceRadius($0) }
                        ),
                        in: 100...2000,
                        step: 100
                    )
                }
            }
            
            // قسم الأمان - Safety Section
            Section("الأمان والطوارئ") {
                Toggle(isOn: Binding(
                    get: { viewModel.settings.fallDetectionEnabled },
                    set: { viewModel.toggleFallDetection($0) }
                )) {
                    HStack {
                        Image(systemName: "figure.fall")
                            .foregroundColor(.orange)
                        Text("كشف السقوط")
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("مهلة الطوارئ: \(viewModel.settings.emergencyTimeout) ثانية")
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.settings.emergencyTimeout) },
                            set: { viewModel.updateEmergencyTimeout(Int($0)) }
                        ),
                        in: 10...60,
                        step: 5
                    )
                }
            }
            
            // قسم الأوامر الصوتية - Voice Commands Section
            Section("الأوامر الصوتية") {
                Toggle(isOn: Binding(
                    get: { viewModel.settings.voiceCommandsEnabled },
                    set: { viewModel.toggleVoiceCommands($0) }
                )) {
                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.purple)
                        Text("تفعيل الأوامر الصوتية")
                    }
                }
                
                if viewModel.settings.voiceCommandsEnabled {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("الأوامر المتاحة:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        CommandRow(command: "اتصل بالعائلة")
                        CommandRow(command: "أرسل موقعي")
                        CommandRow(command: "ساعدني / مساعدة")
                        CommandRow(command: "أدويتي")
                    }
                    .padding(.vertical, 5)
                }
            }
            
            // قسم حول التطبيق - About Section
            Section("حول التطبيق") {
                HStack {
                    Text("الإصدار")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("اللغة")
                    Spacer()
                    Text("العربية")
                        .foregroundColor(.gray)
                }
            }
            
            // قسم الإجراءات - Actions Section
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

// MARK: - Command Row

struct CommandRow: View {
    let command: String
    
    var body: some View {
        HStack {
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
