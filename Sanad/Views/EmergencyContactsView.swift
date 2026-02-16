//
//  EmergencyContactsView.swift
//  Sanad
//
//  View for managing emergency contacts
//

import SwiftUI

struct EmergencyContactsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        List {
            if viewModel.emergencyContacts.isEmpty {
                ContentUnavailableView(
                    "لا توجد جهات اتصال طارئة",
                    systemImage: "phone.badge.plus",
                    description: Text("قم بإضافة جهات اتصال وتحديدها كجهات طارئة من قائمة جهات الاتصال")
                )
            } else {
                Section {
                    ForEach(viewModel.emergencyContacts) { contact in
                        EmergencyContactRow(contact: contact) {
                            viewModel.toggleEmergencyContact(contact)
                        }
                    }
                }
                
                Section {
                    Text("سيتم إرسال تنبيهات الطوارئ لجميع جهات الاتصال المحددة أعلاه")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("جهات الاتصال الطارئة")
        .navigationBarTitleDisplayMode(.large)
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            viewModel.loadContacts()
        }
    }
}

// MARK: - Emergency Contact Row

struct EmergencyContactRow: View {
    let contact: Contact
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // أيقونة الطوارئ - Emergency Icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "phone.fill.badge.plus")
                    .foregroundColor(.red)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(contact.name)
                    .font(.headline)
                
                Text(contact.relationship)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(contact.phoneNumber)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button {
                onToggle()
            } label: {
                Image(systemName: "star.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EmergencyContactsView()
    }
}
