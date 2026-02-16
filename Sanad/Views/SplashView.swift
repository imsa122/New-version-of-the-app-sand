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
}
