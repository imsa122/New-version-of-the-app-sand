//
//  LocationSharingOptionsView.swift
//  Sanad
//
//  View for selecting how to share location (WhatsApp or SMS)
//

import SwiftUI
import MessageUI

struct LocationSharingOptionsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var selectedContacts: Set<UUID> = []
    @State private var showingSharingMethod = false
    @State private var selectedMethod: SharingMethod?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showMessageComposer = false
    
    let locationText: String
    let locationLink: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                // الخلفية - Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.contacts.filter({ $0.isFavorite }).isEmpty {
                        emptyStateView
                    } else {
                        contentView
                    }
                }
            }
            .navigationTitle("إرسال موقعي")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
            .alert("تنبيه", isPresented: $showAlert) {
                Button("حسناً", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showMessageComposer) {
                if let method = selectedMethod {
                    MessageComposeView(
                        recipients: getSelectedPhoneNumbers(),
                        message: getLocationMessage(),
                        method: method
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "location.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.5))
            
            Text("لا توجد جهات اتصال مفضلة")
                .font(.title2.bold())
            
            Text("قم بإضافة جهات اتصال مفضلة\nلإرسال موقعك إليهم")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // معلومات الموقع - Location Info
            locationInfoView
            
            // رأس القائمة - Header
            VStack(spacing: 10) {
                Text("اختر من تريد إرسال موقعك إليه")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                Text("يمكنك اختيار شخص واحد أو أكثر")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.8))
            
            // قائمة جهات الاتصال - Contacts List
            ScrollView {
                LazyVStack(spacing: 15) {
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
            
            // أزرار الإرسال - Send Buttons
            if !selectedContacts.isEmpty {
                sendButtonsView
            }
        }
    }
    
    // MARK: - Location Info View
    
    private var locationInfoView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("موقعك الحالي")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.gray)
                
                Text(locationLink)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue.opacity(0.1))
        )
        .padding()
    }
    
    // MARK: - Send Buttons View
    
    private var sendButtonsView: some View {
        VStack(spacing: 12) {
            Divider()
            
            Text("اختر طريقة الإرسال")
                .font(.subheadline.bold())
                .foregroundColor(.gray)
            
            HStack(spacing: 15) {
                // زر واتساب - WhatsApp Button
                Button {
                    sendViaWhatsApp()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "message.fill")
                            .font(.title2)
                        
                        Text("واتساب")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // زر الرسائل - SMS Button
                Button {
                    sendViaSMS()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "text.bubble.fill")
                            .font(.title2)
                        
                        Text("رسالة نصية")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal)
            
            Text("تم اختيار \(selectedContacts.count) من جهات الاتصال")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 5)
        }
        .padding(.vertical)
        .background(Color.white)
    }
    
    // MARK: - Actions
    
    private func toggleSelection(_ contact: Contact) {
        if selectedContacts.contains(contact.id) {
            selectedContacts.remove(contact.id)
        } else {
            selectedContacts.insert(contact.id)
        }
    }
    
    private func sendViaWhatsApp() {
        let contacts = viewModel.contacts.filter { selectedContacts.contains($0.id) }
        
        if contacts.isEmpty {
            alertMessage = "الرجاء اختيار جهة اتصال واحدة على الأقل"
            showAlert = true
            return
        }
        
        // إرسال عبر واتساب لكل جهة اتصال
        for contact in contacts {
            let phoneNumber = contact.phoneNumber.replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "+", with: "")
            
            let message = getLocationMessage()
            let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            if let whatsappURL = URL(string: "https://wa.me/\(phoneNumber)?text=\(encodedMessage)") {
                if UIApplication.shared.canOpenURL(whatsappURL) {
                    UIApplication.shared.open(whatsappURL)
                } else {
                    alertMessage = "واتساب غير مثبت على جهازك"
                    showAlert = true
                    return
                }
            }
        }
        
        dismiss()
    }
    
    private func sendViaSMS() {
        let contacts = viewModel.contacts.filter { selectedContacts.contains($0.id) }
        
        if contacts.isEmpty {
            alertMessage = "الرجاء اختيار جهة اتصال واحدة على الأقل"
            showAlert = true
            return
        }
        
        selectedMethod = .sms
        showMessageComposer = true
    }
    
    private func getSelectedPhoneNumbers() -> [String] {
        return viewModel.contacts
            .filter { selectedContacts.contains($0.id) }
            .map { $0.phoneNumber }
    }
    
    private func getLocationMessage() -> String {
        return """
        📍 موقعي الحالي من تطبيق سند
        
        \(locationText)
        
        رابط الخريطة:
        \(locationLink)
        """
    }
}

// MARK: - Location Contact Card

struct LocationContactCard: View {
    let contact: Contact
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // صورة - Photo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [Color.blue, Color.blue.opacity(0.7)] : [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    if let photoData = contact.photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 25))
                            .foregroundColor(isSelected ? .white : .gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(contact.relationship)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .gray.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(
                        color: isSelected ? Color.blue.opacity(0.2) : Color.black.opacity(0.05),
                        radius: isSelected ? 8 : 3,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sharing Method

enum SharingMethod {
    case whatsapp
    case sms
}

// MARK: - Message Compose View

struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let message: String
    let method: SharingMethod
    
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
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    LocationSharingOptionsView(
        locationText: "خط العرض: 21.4858\nخط الطول: 39.1925",
        locationLink: "https://www.google.com/maps?q=21.4858,39.1925"
    )
}
