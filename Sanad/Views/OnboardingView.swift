//
//  OnboardingView.swift
//  Sanad
//
//  Beautiful onboarding flow for new users
//  Introduces app features with elegant Arabic UI
//

import SwiftUI

struct OnboardingView: View {
    
    // MARK: - Properties
    
    @State private var currentPage = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isAnimating = false
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "heart.fill",
            title: "مرحباً بك في سند",
            description: "رفيقك الذكي للعناية بكبار السن وذوي الاحتياجات الخاصة",
            color: .blue,
            features: []
        ),
        OnboardingPage(
            icon: "phone.fill",
            title: "اتصل بالعائلة بسهولة",
            description: "اتصل بأحبائك بضغطة زر واحدة",
            color: .green,
            features: [
                "اتصال سريع بالمفضلين",
                "أزرار كبيرة وواضحة",
                "أوامر صوتية بالعربية"
            ]
        ),
        OnboardingPage(
            icon: "location.fill",
            title: "شارك موقعك",
            description: "أرسل موقعك الحالي للعائلة فوراً عبر واتساب أو الرسائل",
            color: .blue,
            features: [
                "مشاركة فورية للموقع",
                "رابط خرائط جوجل",
                "إرسال عبر واتساب أو SMS"
            ]
        ),
        OnboardingPage(
            icon: "exclamationmark.triangle.fill",
            title: "المساعدة الطارئة",
            description: "احصل على المساعدة عند الحاجة مع نظام طوارئ ذكي",
            color: .red,
            features: [
                "اتصال بالعائلة أو الطوارئ",
                "إرسال تلقائي للموقع",
                "كشف السقوط التلقائي"
            ]
        ),
        OnboardingPage(
            icon: "pills.fill",
            title: "تذكير الأدوية",
            description: "لن تنسى أدويتك بعد اليوم مع التذكير الصوتي",
            color: .orange,
            features: [
                "تذكير صوتي بالعربية",
                "جدولة أوقات متعددة",
                "إشعارات منتظمة"
            ]
        ),
        OnboardingPage(
            icon: "shield.fill",
            title: "آمن ومحمي",
            description: "بياناتك محمية بأحدث تقنيات التشفير",
            color: .purple,
            features: [
                "تشفير البيانات الحساسة",
                "تخزين آمن في Keychain",
                "خصوصية كاملة"
            ]
        ),
        OnboardingPage(
            icon: "checkmark.circle.fill",
            title: "جاهز للبدء!",
            description: "دعنا نبدأ رحلتك مع سند",
            color: .green,
            features: []
        )
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.3),
                    pages[currentPage].color.opacity(0.1),
                    .white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(action: completeOnboarding) {
                            Text("تخطي")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(20)
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                // Page content
                VStack(spacing: 30) {
                    // Icon with animation
                    ZStack {
                        Circle()
                            .fill(pages[currentPage].color.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        Image(systemName: pages[currentPage].icon)
                            .font(.system(size: 70))
                            .foregroundColor(pages[currentPage].color)
                            .scaleEffect(isAnimating ? 1.0 : 0.9)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                    // Title
                    Text(pages[currentPage].title)
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 30)
                        .transition(.opacity)
                    
                    // Description
                    Text(pages[currentPage].description)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                    
                    // Features list
                    if !pages[currentPage].features.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(pages[currentPage].features, id: \.self) { feature in
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(pages[currentPage].color)
                                        .font(.title3)
                                    
                                    Text(feature)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 10)
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                Spacer()
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 30 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Next/Get Started button
                Button(action: nextPage) {
                    HStack(spacing: 12) {
                        Text(currentPage == pages.count - 1 ? "ابدأ الآن" : "التالي")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Image(systemName: currentPage == pages.count - 1 ? "checkmark" : "arrow.left")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [
                                pages[currentPage].color,
                                pages[currentPage].color.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: pages[currentPage].color.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            isAnimating = true
        }
    }
    
    // MARK: - Actions
    
    private func nextPage() {
        HapticManager.impact(.medium)
        
        if currentPage < pages.count - 1 {
            withAnimation(.spring()) {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        HapticManager.notification(.success)
        
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let features: [String]
}

// MARK: - Onboarding Container

struct OnboardingContainerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                EnhancedMainView()
            } else {
                OnboardingView()
            }
        }
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    OnboardingView()
}

#Preview("Container") {
    OnboardingContainerView()
}
