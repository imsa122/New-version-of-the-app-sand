import SwiftUI

// MARK: - Palette

enum SanadPalette {
    static let emerald = Color(red: 0.08, green: 0.75, blue: 0.45)
    static let ocean = Color(red: 0.13, green: 0.55, blue: 0.95)
    static let violet = Color(red: 0.55, green: 0.33, blue: 0.95)
    static let coral = Color(red: 0.95, green: 0.30, blue: 0.35)
    static let amber = Color(red: 0.98, green: 0.64, blue: 0.18)
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.17)
}

// MARK: - Gradient Background

struct SanadGradientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.98, blue: 0.97),
                    Color(red: 0.95, green: 0.96, blue: 1.00),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(SanadPalette.emerald.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 25)
                .offset(x: -120, y: -260)

            Circle()
                .fill(SanadPalette.ocean.opacity(0.16))
                .frame(width: 300, height: 300)
                .blur(radius: 35)
                .offset(x: 140, y: -220)

            Circle()
                .fill(SanadPalette.violet.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 35)
                .offset(x: 120, y: 320)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Vision 2030 Time Header

struct SanadTimeHeader: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: now)
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.dateFormat = "EEEE، d MMMM yyyy"
        return formatter.string(from: now)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeText)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SanadPalette.ink, SanadPalette.ocean],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(dateText)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)

                Text("التحول الرقمي للرعاية الآمنة")
                    .font(.caption)
                    .foregroundColor(SanadPalette.emerald)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(SanadPalette.emerald.opacity(0.16))
                    .frame(width: 56, height: 56)
                Image(systemName: "shield.checkered")
                    .font(.title3.weight(.bold))
                    .foregroundColor(SanadPalette.emerald)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
        .onReceive(timer) { newDate in
            now = newDate
        }
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}

// MARK: - Premium Action Button

struct PremiumActionButton: View {
    let title: String
    let subtitle: String?
    let icon: String
    let gradient: [Color]
    var isEmergency: Bool = false
    let action: () -> Void

    @State private var pressed = false
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.92))
                    }
                }

                Spacer()
            }
            .padding()
            .frame(height: 84)
            .background(
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: gradient.last?.opacity(0.35) ?? .black.opacity(0.3), radius: 12, x: 0, y: 7)
            .scaleEffect(pressed ? 0.985 : 1)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isEmergency && pulse
                        ? Color.white.opacity(0.75)
                        : Color.clear,
                        lineWidth: 2
                    )
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
            )
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.01, maximumDistance: 20, pressing: { p in
            pressed = p
        }, perform: {})
        .onAppear {
            if isEmergency { pulse = true }
        }
    }
}

// MARK: - Mini Quick Card

struct QuickNavCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.headline.weight(.bold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 110)
            .padding(10)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: color.opacity(0.14), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}
