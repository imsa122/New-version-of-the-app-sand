//
//  ContactsListView.swift
//  Sanad
//
//  View for managing family contacts
//

import SwiftUI

struct ContactsListView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showAddContact = false
    @State private var selectedContact: Contact?
    
    var body: some View {
        List {
            ForEach(viewModel.contacts) { contact in
                ContactRow(contact: contact) {
                    selectedContact = contact
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    viewModel.deleteContact(viewModel.contacts[index])
                }
            }
        }
        .navigationTitle("جهات الاتصال")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddContact = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showAddContact) {
            AddContactView { contact in
                viewModel.addContact(contact)
            }
        }
        .sheet(item: $selectedContact) { contact in
            EditContactView(contact: contact) { updatedContact in
                viewModel.updateContact(updatedContact)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let contact: Contact
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // صورة أو أيقونة - Photo or Icon
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        if let photoData = contact.photoData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                        }
                    }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(contact.relationship)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(contact.phoneNumber)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    if contact.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.green)
                    }
                    
                    if contact.isEmergencyContact {
                        Image(systemName: "star.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 5)
        }
    }
}

// MARK: - Add Contact View

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Contact) -> Void
    
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var relationship = ""
    @State private var isEmergencyContact = false
    @State private var isFavorite = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("معلومات جهة الاتصال") {
                    TextField("الاسم", text: $name)
                    TextField("رقم الهاتف", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("العلاقة (مثل: ابن، ابنة)", text: $relationship)
                }
                
                Section("التصنيفات") {
                    Toggle(isOn: $isFavorite) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.green)
                            Text("جهة اتصال مفضلة")
                        }
                    }
                    
                    Toggle(isOn: $isEmergencyContact) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.red)
                            Text("جهة اتصال طارئة")
                        }
                    }
                }
                
                Section {
                    Text("• المفضلة: للاتصال السريع وإرسال الموقع")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("• الطارئة: لتلقي تنبيهات الطوارئ التلقائية")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("إضافة جهة اتصال")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        let contact = Contact(
                            name: name,
                            phoneNumber: phoneNumber,
                            relationship: relationship,
                            isEmergencyContact: isEmergencyContact,
                            isFavorite: isFavorite
                        )
                        onSave(contact)
                        dismiss()
                    }
                    .disabled(name.isEmpty || phoneNumber.isEmpty)
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

// MARK: - Edit Contact View

struct EditContactView: View {
    @Environment(\.dismiss) private var dismiss
    let contact: Contact
    let onSave: (Contact) -> Void
    
    @State private var name: String
    @State private var phoneNumber: String
    @State private var relationship: String
    @State private var isEmergencyContact: Bool
    @State private var isFavorite: Bool
    
    init(contact: Contact, onSave: @escaping (Contact) -> Void) {
        self.contact = contact
        self.onSave = onSave
        _name = State(initialValue: contact.name)
        _phoneNumber = State(initialValue: contact.phoneNumber)
        _relationship = State(initialValue: contact.relationship)
        _isEmergencyContact = State(initialValue: contact.isEmergencyContact)
        _isFavorite = State(initialValue: contact.isFavorite)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("معلومات جهة الاتصال") {
                    TextField("الاسم", text: $name)
                    TextField("رقم الهاتف", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("العلاقة", text: $relationship)
                }
                
                Section("التصنيفات") {
                    Toggle(isOn: $isFavorite) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.green)
                            Text("جهة اتصال مفضلة")
                        }
                    }
                    
                    Toggle(isOn: $isEmergencyContact) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.red)
                            Text("جهة اتصال طارئة")
                        }
                    }
                }
                
                Section {
                    Text("• المفضلة: للاتصال السريع وإرسال الموقع")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("• الطارئة: لتلقي تنبيهات الطوارئ التلقائية")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("تعديل جهة الاتصال")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        var updatedContact = contact
                        updatedContact.name = name
                        updatedContact.phoneNumber = phoneNumber
                        updatedContact.relationship = relationship
                        updatedContact.isEmergencyContact = isEmergencyContact
                        updatedContact.isFavorite = isFavorite
                        onSave(updatedContact)
                        dismiss()
                    }
                    .disabled(name.isEmpty || phoneNumber.isEmpty)
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ContactsListView()
    }
}
