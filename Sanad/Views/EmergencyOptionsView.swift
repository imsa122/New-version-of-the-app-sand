//
//  EmergencyOptionsView.swift
//  Sanad
//
//  View for emergency assistance options
//

import SwiftUI

struct EmergencyOptionsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingEmergencyServices = false
    @State private var showingFavoriteContacts = false
    @State private var selectedContact: Contact?
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // الخلفية - Background
                LinearGradient(
                    colors: [Color.red.opacity(0.1), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // رأس الصفحة - Header
                    headerView
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            // الخيار الأول: الاتصال بالعائلة - Call Family
                            callFamilyOptionView
                            
                            // فاصل - Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                
                                Text("أو")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal)
                            
                            // الخيار الثاني: خدمات الطوارئ - Emergency Services
                            emergencyServicesOptionView
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("المساعدة الطارئة")
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
            .sheet(isPresented: $showingFavoriteContacts) {
                FavoriteContactsForEmergencyView { contact in
                    callContact(contact)
                }
            }
            .sheet(isPresented: $showingEmergencyServices) {
                EmergencyServicesView { service in
                    callEmergencyService(service)
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("حسناً", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            Text("اختر نوع المساعدة")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text("يمكنك الاتصال بالعائلة أو خدمات الطوارئ")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white.opacity(0.8))
    }
    
    // MARK: - Call Family Option
    
    private var callFamilyOptionView: some View {
        Button {
            if viewModel.contacts.filter({ $0.isFavorite }).isEmpty {
                alertTitle = "لا توجد جهات اتصال"
                alertMessage = "الرجاء إضافة جهات اتصال مفضلة أولاً من الإعدادات"
                showAlert = true
            } else {
                showingFavoriteContacts = true
            }
        } label: {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("الاتصال بالعائلة")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text("اتصل بأفراد العائلة أو الأصدقاء المفضلين")
                        .font(.body)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text("اختر من تريد الاتصال به")
                            .font(.subheadline.bold())
                        
                        Image(systemName: "arrow.left")
                            .font(.subheadline)
                    }
                    .foregroundColor(.green)
                }
            }
            .padding(25)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .green.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Emergency Services Option
    
    private var emergencyServicesOptionView: some View {
        Button {
            showingEmergencyServices = true
        } label: {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "cross.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("خدمات الطوارئ")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text("اتصل بالإسعاف، الدفاع المدني، أو الشرطة")
                        .font(.body)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text("اختر الخدمة المطلوبة")
                            .font(.subheadline.bold())
                        
                        Image(systemName: "arrow.left")
                            .font(.subheadline)
                    }
                    .foregroundColor(.red)
                }
            }
            .padding(25)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .red.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.red.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Actions
    
    private func callContact(_ contact: Contact) {
        let phoneNumber = contact.phoneNumber.replacingOccurrences(of: " ", with: "")
        
        if let url = URL(string: "tel://\(phoneNumber)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            dismiss()
        } else {
            alertTitle = "خطأ"
            alertMessage = "لا يمكن إجراء المكالمة"
            showAlert = true
        }
    }
    
    private func callEmergencyService(_ service: EmergencyService) {
        if let url = URL(string: "tel://\(service.number)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            dismiss()
        } else {
            alertTitle = "خطأ"
            alertMessage = "لا يمكن إجراء المكالمة"
            showAlert = true
        }
    }
}

// MARK: - Favorite Contacts For Emergency View

struct FavoriteContactsForEmergencyView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    
    var onCallContact: (Contact) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.green.opacity(0.1), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.contacts.filter { $0.isFavorite }) { contact in
                            EmergencyContactCard(contact: contact) {
                                onCallContact(contact)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("اختر من تريد الاتصال به")
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
        }
    }
}

// MARK: - Emergency Contact Card

struct EmergencyContactCard: View {
    let contact: Contact
    let onCall: () -> Void
    
    var body: some View {
        Button(action: onCall) {
            HStack(spacing: 15) {
                // صورة - Photo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    if let photoData = contact.photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(contact.name)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    Text(contact.relationship)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                        Text(contact.phoneNumber)
                            .font(.subheadline)
                    }
                    .foregroundColor(.green)
                }
                
                Spacer()
                
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Emergency Services View

struct EmergencyServicesView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var onCallService: (EmergencyService) -> Void
    
    let emergencyServices: [EmergencyService] = [
        EmergencyService(
            name: "الإسعاف",
            nameEnglish: "Ambulance",
            number: "997",
            icon: "cross.case.fill",
            color: .red,
            description: "للحالات الطبية الطارئة"
        ),
        EmergencyService(
            name: "الدفاع المدني",
            nameEnglish: "Civil Defense",
            number: "998",
            icon: "flame.fill",
            color: .orange,
            description: "للحرائق والكوارث"
        ),
        EmergencyService(
            name: "الشرطة",
            nameEnglish: "Police",
            number: "999",
            icon: "shield.fill",
            color: .blue,
            description: "للحالات الأمنية"
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.red.opacity(0.1), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // تحذير - Warning
                        warningView
                        
                        // قائمة الخدمات - Services List
                        ForEach(emergencyServices) { service in
                            EmergencyServiceCard(service: service) {
                                onCallService(service)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("خدمات الطوارئ")
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
        }
    }
    
    private var warningView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("تنبيه هام")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("استخدم هذه الأرقام في حالات الطوارئ الحقيقية فقط")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Emergency Service Card

struct EmergencyServiceCard: View {
    let service: EmergencyService
    let onCall: () -> Void
    
    var body: some View {
        Button(action: onCall) {
            HStack(spacing: 20) {
                // أيقونة الخدمة - Service Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [service.color, service.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: service.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: service.icon)
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(service.name)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text(service.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.headline)
                        
                        Text(service.number)
                            .font(.title3.bold())
                    }
                    .foregroundColor(service.color)
                }
                
                Spacer()
                
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(service.color)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: service.color.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(service.color.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Emergency Service Model

struct EmergencyService: Identifiable {
    let id = UUID()
    let name: String
    let nameEnglish: String
    let number: String
    let icon: String
    let color: Color
    let description: String
}

// MARK: - Preview

#Preview {
    EmergencyOptionsView()
}
