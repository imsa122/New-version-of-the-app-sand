//
//  GeofenceSetupView.swift
//  Sanad
//
//  View for setting up home location and geofence
//

import SwiftUI
import MapKit

struct GeofenceSetupView: View {
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SettingsViewModel
    
    @State private var region: MKCoordinateRegion
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var address = ""
    
    private let locationManager = LocationManager.shared
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        
        // تعيين الموقع الافتراضي
        let initialCoordinate = viewModel.settings.homeLocation?.coordinate ??
            locationManager.location?.coordinate ??
            CLLocationCoordinate2D(latitude: 21.4858, longitude: 39.1925)
        
        _selectedCoordinate = State(initialValue: initialCoordinate)
        _region = State(initialValue: MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
        _address = State(initialValue: viewModel.settings.homeLocation?.address ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // الخريطة - Map
                Map(position: .constant(.region(region)))
                    .frame(height: 400)
                    .overlay {
                        // علامة الموقع - Location Marker
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                    }
                
                // معلومات الموقع - Location Info
                VStack(spacing: 20) {
                    Text("حدد موقع المنزل")
                        .font(.headline)
                    
                    TextField("العنوان (اختياري)", text: $address)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    HStack(spacing: 15) {
                        Button {
                            useCurrentLocation()
                        } label: {
                            Label("الموقع الحالي", systemImage: "location.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button {
                            saveLocation()
                        } label: {
                            Label("حفظ", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("نطاق السياج: \(Int(viewModel.settings.geofenceRadius)) متر")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("تحديد موقع المنزل")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
    
    // MARK: - Actions
    
    private func useCurrentLocation() {
        guard let location = locationManager.location else { return }
        
        selectedCoordinate = location.coordinate
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        address = "الموقع الحالي"
    }
    
    private func saveLocation() {
        viewModel.setHomeLocation(
            coordinate: selectedCoordinate,
            address: address.isEmpty ? nil : address
        )
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    GeofenceSetupView(viewModel: SettingsViewModel())
}
