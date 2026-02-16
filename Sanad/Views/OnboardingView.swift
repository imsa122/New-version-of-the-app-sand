import SwiftUI
import AVFoundation

struct OnboardingView: View {
    
    // MARK: - Properties
    
    @State private var currentPage = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("onboardingVoiceEnabled") private var voiceEnabled = true
    
    let pages: [OnboardingPage] = [
        
        OnboardingPage(
            icon: "heart.fill",
            title: "مرحباً بك في سند",
            description: "تطبيق بسيط يساعدك تتواصل مع عائلتك وتحصل على المساعدة بسهولة",
            color: .blue,
            features: []
        ),
        
        OnboardingPage(
            icon: "phone.fill",
            title: "كل شيء بضغطة زر",
            description: "استخدم الأزرار الكبيرة للاتصال، إرسال موقعك، أو طلب المساعدة",
            color: .green,
            features: [
                "اتصال سريع بالعائلة",
                "مشاركة موقعك فوراً",
                "زر طوارئ واضح وآمن"
            ]
        ),
        
        OnboardingPage(
            icon: "checkmark.circle.fill",
            title: "جاهز للبدء",
            description: "نحن هنا لدعمك في أي وقت",
            color: .blue,
            features: []
        )
    ]
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.25),
                    .white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                
                // 🔊 زر الصوت
                HStack {
                    Spacer()
                    
                    Button(action: toggleVoice) {
                        Image(systemName: voiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(Color.white.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                
                Spacer()
                
                // Swipe Pages
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(for: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                Spacer()
                
                // Page Indicator
                HStack(spacing: 10) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 30 : 10, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 25)
                
                // Next Button
                Button(action: nextPage) {
                    Text(currentPage == pages.count - 1 ? "ابدأ الآن" : "التالي")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(pages[currentPage].color)
                        .cornerRadius(18)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            speakCurrentPage()
        }
        .onChange(of: currentPage) { _ in
            speakCurrentPage()
        }
    }
    
    // MARK: - Page View
    
    private func pageView(for page: OnboardingPage) -> some View {
        VStack {
            
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 150, height: 150)
                
                Image(systemName: page.icon)
                    .font(.system(size: 70))
                    .foregroundColor(page.color)
            }
            .padding(.bottom, 30)
            
            Text(page.title)
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 15)
            
            Text(page.description)
                .font(.system(size: 22))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            if !page.features.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(page.features, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(page.color)
                                .font(.title2)
                            
                            Text(feature)
                                .font(.system(size: 20))
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 25)
            }
        }
    }
    
    // MARK: - Actions
    
    private func nextPage() {
        if currentPage < pages.count - 1 {
            currentPage += 1
        } else {
            hasCompletedOnboarding = true
        }
    }
    
    private func toggleVoice() {
        voiceEnabled.toggle()
        
        if voiceEnabled {
            speakCurrentPage()
        } else {
            SpeechManager.shared.stop()
        }
    }
    
    private func speakCurrentPage() {
        guard voiceEnabled else { return }
        
        let page = pages[currentPage]
        let fullText = page.title + ". " + page.description
        SpeechManager.shared.speak(fullText)
    }
}

// MARK: - Model

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let features: [String]
}

// MARK: - Speech Manager

class SpeechManager {
    
    static let shared = SpeechManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
