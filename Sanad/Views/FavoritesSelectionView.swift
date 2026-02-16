//
//  FavoritesSelectionView.swift
//  Sanad
//
//  View for selecting favorite contacts to call
//

import SwiftUI
import Contacts

struct FavoritesSelectionView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var selectedContacts: Set<UUID> = []
    @State private var showContactPicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var onCallSelected: ([Contact]) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                // الخلفية - Background
                LinearGradient(
                    colors: [Color.green.opacity(0.1), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.contacts.filter({ $0.isFavorite }).isEmpty {
                        // حالة عدم وجود مفضلات - No Favorites State
                        emptyStateView
                    } else {
                        // قائمة المفضلات - Favorites List
                        favoritesListView
                    }
                }
            }
            .navigationTitle("اتصل بالعائلة")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showContactPicker = true
                    } label: {
                        Label("إضافة", systemImage: "person.badge.plus")
                            .foregroundColor(.green)
                    }
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
            .alert("تنبيه", isPresented: $showAlert) {
                Button("حسناً", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "person.2.fill")
                .font(.system(size: 80))
                .foregroundColor(.green.opacity(0.5))
            
            Text("لا توجد جهات اتصال مفضلة")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text("قم بإضافة أفراد العائلة والأصدقاء\nكجهات اتصال مفضلة للاتصال السريع")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showContactPicker = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("إضافة جهة اتصال")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(15)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Favorites List View
    
    private var favoritesListView: some View {
        VStack(spacing: 0) {
            // رأس القائمة - List Header
            VStack(spacing: 10) {
                Text("اختر من تريد الاتصال به")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                Text("يمكنك اختيار شخص واحد أو أكثر")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.8))
            
            // قائمة جهات الاتصال - Contacts List
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(viewModel.contacts.filter { $0.isFavorite }) { contact in
                        FavoriteContactCard(
                            contact: contact,
                            isSelected: selectedContacts.contains(contact.id)
                        ) {
                            toggleSelection(contact)
                        }
                    }
                }
                .padding()
            }
            
            // زر الاتصال - Call Button
            if !selectedContacts.isEmpty {
                callButtonView
            }
        }
    }
    
    // MARK: - Call Button View
    
    private var callButtonView: some View {
        VStack(spacing: 10) {
            Divider()
            
            Button {
                callSelectedContacts()
            } label: {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.title3)
                    
                    Text("اتصل الآن (\(selectedContacts.count))")
                        .font(.title3.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
                .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
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
    
    private func callSelectedContacts() {
        let contacts = viewModel.contacts.filter { selectedContacts.contains($0.id) }
        
        if contacts.isEmpty {
            alertMessage = "الرجاء اختيار جهة اتصال واحدة على الأقل"
            showAlert = true
            return
        }
        
        onCallSelected(contacts)
        dismiss()
    }
}

// MARK: - Favorite Contact Card

struct FavoriteContactCard: View {
    let contact: Contact
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // صورة أو أيقونة - Photo or Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [Color.green, Color.green.opacity(0.7)] : [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
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
                            .foregroundColor(isSelected ? .white : .blue)
                    }
                    
                    // علامة الاختيار - Check Mark
                    if isSelected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 25, y: -25)
                    }
                }
                
                // معلومات جهة الاتصال - Contact Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(contact.name)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                        Text(contact.relationship)
                            .font(.subheadline)
                    }
                    .foregroundColor(.gray)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                        Text(contact.phoneNumber)
                            .font(.subheadline)
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                // أيقونة الاختيار - Selection Icon
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .green : .gray.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(
                        color: isSelected ? Color.green.opacity(0.3) : Color.black.opacity(0.1),
                        radius: isSelected ? 10 : 5,
                        x: 0,
                        y: 3
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    FavoritesSelectionView { contacts in
        print("Selected contacts: \(contacts.map { $0.name })")
    }
}
