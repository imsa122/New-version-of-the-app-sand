//
//  LocationSharingOptionsView.swift
//  Sanad
//

import SwiftUI
import MessageUI

struct LocationSharingOptionsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var selectedContacts: Set<UUID> = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showMessageComposer = false
    
    let locationText: String
    let locationLink: String
    
    var body: some View {
        NavigationStack {
            VStack {
                
                if viewModel.contacts.filter({ $0.isFavorite }).isEmpty {
                    Text("لا توجد جهات اتصال مفضلة")
                        .font(.title3)
                        .padding()
                } else {
                    
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(viewModel.contacts.filter { $0.isFavorite }) { contact in
                                LocationContactCard(
                                    contact: contact,
                                    isSelected: selectedContacts.contains(contact.id)
                                ) {
                                    toggleSelection(contact)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    if !selectedContacts.isEmpty {
                        sendButtonsView
                    }
                }
            }
            .navigationTitle("إرسال موقعي")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") { dismiss() }
                }
            }
            .alert("تنبيه", isPresented: $showAlert) {
                Button("حسناً", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showMessageComposer) {
                MessageComposeView(
                    recipients: getSelectedPhoneNumbers(),
                    message: getLocationMessage()
                )
            }
        }
    }
}

// MARK: - Send Buttons

extension LocationSharingOptionsView {
    
    private var sendButtonsView: some View {
        VStack(spacing: 15) {
            
            Divider()
            
            HStack {
                
                Button {
                    sendViaWhatsApp()
                } label: {
                    Text("واتساب")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button {
                    sendViaSMS()
                } label: {
                    Text("رسالة نصية")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Actions

extension LocationSharingOptionsView {
    
    private func toggleSelection(_ contact: Contact) {
        if selectedContacts.contains(contact.id) {
            selectedContacts.remove(contact.id)
        } else {
            selectedContacts.insert(contact.id)
        }
    }
    
    private func sendViaWhatsApp() {
        
        let contacts = viewModel.contacts.filter {
            selectedContacts.contains($0.id)
        }
        
        guard let contact = contacts.first else {
            alertMessage = "الرجاء اختيار جهة اتصال"
            showAlert = true
            return
        }
        
        let cleanedNumber = cleanPhoneNumber(contact.phoneNumber)
        
        let message = getLocationMessage()
        let encodedMessage = message.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? ""
        
        guard let url = URL(
            string: "https://wa.me/\(cleanedNumber)?text=\(encodedMessage)"
        ) else {
            alertMessage = "رابط واتساب غير صالح"
            showAlert = true
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            dismiss()
        } else {
            alertMessage = "واتساب غير مثبت على جهازك"
            showAlert = true
        }
    }
    
    private func sendViaSMS() {
        showMessageComposer = true
    }
    
    private func getSelectedPhoneNumbers() -> [String] {
        viewModel.contacts
            .filter { selectedContacts.contains($0.id) }
            .map { $0.phoneNumber }
    }
    
    private func getLocationMessage() -> String {
        """
        📍 موقعي الحالي من تطبيق سند
        
        \(locationText)
        
        رابط الخريطة:
        \(locationLink)
        """
    }
    
    private func cleanPhoneNumber(_ number: String) -> String {
        var cleaned = number
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "+", with: "")
        
        // لو يبدأ بـ 05 نحوله لصيغة السعودية
        if cleaned.hasPrefix("05") {
            cleaned.removeFirst()
            cleaned = "966" + cleaned
        }
        
        return cleaned
    }
}

// MARK: - Contact Card

struct LocationContactCard: View {
    
    let contact: Contact
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(contact.name)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

// MARK: - SMS Composer

struct MessageComposeView: UIViewControllerRepresentable {
    
    let recipients: [String]
    let message: String
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = recipients
        controller.body = message
        controller.messageComposeDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        
        let parent: MessageComposeView
        
        init(_ parent: MessageComposeView) {
            self.parent = parent
        }
        
        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            parent.dismiss()
        }
    }
}
