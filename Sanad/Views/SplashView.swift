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
            
            VStack(spacing: 25) {
                
                Image("sanadlogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .shadow(radius: 10)
                
                Text("Sanad")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.blue)
                
                Text("معك دائمًا… للراحة والأمان")
                    .font(.title3)
                    .foregroundColor(.gray)
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
