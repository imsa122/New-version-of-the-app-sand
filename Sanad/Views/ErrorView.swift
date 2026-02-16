//
//  ErrorView.swift
//  Sanad
//
//  Beautiful error display component with Arabic support
//

import SwiftUI

struct ErrorView: View {
    let error: SanadError
    let retryAction: (() -> Void)?
    let dismissAction: (() -> Void)?
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // Error Icon with Animation
            ZStack {
                Circle()
                    .fill(severityColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Image(systemName: errorIcon)
                    .font(.system(size: 50))
                    .foregroundColor(severityColor)
            }
            .padding(.bottom, 10)
            
            // Error Title
            Text(error.errorDescription ?? "حدث خطأ")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            // Failure Reason (if available)
            if let reason = error.failureReason {
                Text(reason)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // Recovery Suggestion
            if let suggestion = error.recoverySuggestion {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                        Text("الحل المقترح")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text(suggestion)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                // Retry Button
                if let retry = retryAction {
                    Button(action: {
                        HapticManager.impact(.medium)
                        retry()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                            Text("حاول مرة أخرى")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
                
                // Dismiss Button
                if let dismiss = dismissAction {
                    Button(action: {
                        HapticManager.selection()
                        dismiss()
                    }) {
                        Text("إغلاق")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
        .onAppear {
            isAnimating = true
            HapticManager.notification(.error)
        }
    }
    
    // MARK: - Computed Properties
    
    private var errorIcon: String {
        switch error {
        case .locationUnavailable, .locationPermissionDenied, .locationServiceDisabled, .geofenceSetupFailed:
            return "location.slash.fill"
        case .noContacts, .noEmergencyContacts, .noFavoriteContacts, .contactNotFound:
            return "person.crop.circle.badge.exclamationmark"
        case .invalidPhoneNumber:
            return "phone.badge.exclamationmark"
        case .phoneCallFailed:
            return "phone.down.fill"
        case .smsFailedToSend:
            return "message.badge.fill"
        case .whatsappNotInstalled:
            return "app.badge"
        case .noMedications, .medicationNotFound:
            return "pills.fill"
        case .invalidMedicationName, .invalidDosage, .invalidTime:
            return "exclamationmark.circle.fill"
        case .notificationPermissionDenied:
            return "bell.slash.fill"
        case .voiceRecognitionFailed, .microphonePermissionDenied, .speechRecognitionNotAvailable:
            return "mic.slash.fill"
        case .voiceCommandNotRecognized:
            return "waveform.badge.exclamationmark"
        case .storageError, .dataCorrupted, .saveFailed, .loadFailed:
            return "externaldrive.badge.exclamationmark"
        case .encryptionFailed, .decryptionFailed:
            return "lock.slash.fill"
        case .networkUnavailable:
            return "wifi.slash"
        case .requestTimeout:
            return "clock.badge.exclamationmark"
        case .emergencyActivationFailed:
            return "exclamationmark.triangle.fill"
        case .operationCancelled:
            return "xmark.circle.fill"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var severityColor: Color {
        switch error.severity {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }
}

// MARK: - Compact Error View

struct CompactErrorView: View {
    let error: SanadError
    let dismissAction: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(error.errorDescription ?? "حدث خطأ")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if let dismiss = dismissAction {
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Error Alert Modifier

struct ErrorAlert: ViewModifier {
    @Binding var error: SanadError?
    let retryAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "تنبيه",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
                presenting: error
            ) { error in
                if let retry = retryAction {
                    Button("حاول مرة أخرى") {
                        retry()
                    }
                }
                Button("إغلاق", role: .cancel) {
                    self.error = nil
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.errorDescription ?? "حدث خطأ")
                    
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
    }
}

extension View {
    func errorAlert(error: Binding<SanadError?>, retryAction: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlert(error: error, retryAction: retryAction))
    }
}

// MARK: - Haptic Manager

class HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Preview

#Preview("Full Error View") {
    ErrorView(
        error: .locationPermissionDenied,
        retryAction: { print("Retry") },
        dismissAction: { print("Dismiss") }
    )
}

#Preview("Compact Error View") {
    CompactErrorView(
        error: .noEmergencyContacts,
        dismissAction: { print("Dismiss") }
    )
}
