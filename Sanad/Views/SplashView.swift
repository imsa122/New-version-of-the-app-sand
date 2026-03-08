import SwiftUI

struct SplashView: View {
    
    @State private var isActive = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            
            if isActive {
                
                if hasCompletedOnboarding {
                    EnhancedMainView()
                } else {
                    OnboardingView()
                }
                
            } else {
                splashContent
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isActive)
    }
}

// MARK: - Splash Content

extension SplashView {
    
    private var splashContent: some View {
        ZStack {
            
            LinearGradient(
                colors: [Color.blue.opacity(0.2), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 22) {
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 185, height: 185)
                        .blur(radius: 2)
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 170, height: 170)
                    
                    Image("sanadlogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 132, height: 132)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 10)
                
                Text("سند")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.00, green: 0.75, blue: 0.65), Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("رفيقك في الأمان")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation {
                    isActive = true
                }
            }
        }
    }
}
