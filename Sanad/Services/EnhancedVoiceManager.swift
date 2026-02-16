//
//  EnhancedVoiceManager.swift
//  Sanad
//
//  Enhanced voice recognition with Arabic commands
//

import Foundation
import Speech
import AVFoundation
import Combine

/// مدير الأوامر الصوتية المحسّن - Enhanced Voice Manager
class EnhancedVoiceManager: ObservableObject {
    
    static let shared = EnhancedVoiceManager()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let synthesizer = AVSpeechSynthesizer()
    
    @Published var isListening: Bool = false
    @Published var recognizedText: String = ""
    @Published var lastCommand: VoiceCommand?
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private init() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// طلب إذن التعرف على الصوت - Request Speech Recognition Permission
    func requestPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                completion(status == .authorized)
            }
        }
    }
    
    // MARK: - Speech Recognition
    
    /// بدء الاستماع - Start Listening
    func startListening() throws {
        // إيقاف أي مهمة تعرف سابقة
        stopListening()
        
        // التحقق من الإذن
        guard authorizationStatus == .authorized else {
            throw VoiceError.notAuthorized
        }
        
        // التحقق من توفر المحرك الصوتي
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw VoiceError.recognizerNotAvailable
        }
        
        // إعداد جلسة الصوت
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // إنشاء طلب التعرف
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.unableToCreateRequest
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // الحصول على مدخل الصوت
        let inputNode = audioEngine.inputNode
        
        // بدء مهمة التعرف
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                self.recognizedText = transcription
                
                // معالجة الأمر
                self.processCommand(transcription)
            }
            
            if error != nil || result?.isFinal == true {
                self.stopListening()
            }
        }
        
        // إعداد تنسيق الصوت
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // بدء المحرك الصوتي
        audioEngine.prepare()
        try audioEngine.start()
        
        isListening = true
        speak("أنا أستمع")
    }
    
    /// إيقاف الاستماع - Stop Listening
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
    
    // MARK: - Command Processing
    
    /// معالجة الأمر الصوتي - Process Voice Command
    private func processCommand(_ text: String) {
        let lowercased = text.lowercased()
        
        // اكتشاف الأوامر
        if lowercased.contains("اتصل") || lowercased.contains("اتصال") {
            if lowercased.contains("ابن") || lowercased.contains("ولد") {
                lastCommand = .callSon
                NotificationCenter.default.post(name: .voiceCommandReceived, object: VoiceCommand.callSon)
            } else if lowercased.contains("ابنة") || lowercased.contains("بنت") {
                lastCommand = .callDaughter
                NotificationCenter.default.post(name: .voiceCommandReceived, object: VoiceCommand.callDaughter)
            } else {
                lastCommand = .callFamily
                NotificationCenter.default.post(name: .voiceCommandReceived, object: VoiceCommand.callFamily)
            }
        } else if lowercased.contains("موقع") || lowercased.contains("مكان") {
            lastCommand = .sendLocation
            NotificationCenter.default.post(name: .voiceCommandReceived, object: VoiceCommand.sendLocation)
        } else if lowercased.contains("مساعدة") || lowercased.contains("ساعد") || lowercased.contains("نجدة") {
            lastCommand = .emergency
            NotificationCenter.default.post(name: .voiceCommandReceived, object: VoiceCommand.emergency)
        } else if lowercased.contains("دواء") || lowercased.contains("أدوية") {
            lastCommand = .showMedications
            NotificationCenter.default.post(name: .voiceCommandReceived, object: VoiceCommand.showMedications)
        }
    }
    
    // MARK: - Text to Speech
    
    /// نطق النص - Speak Text
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        utterance.rate = 0.5 // سرعة بطيئة للوضوح
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    /// إيقاف النطق - Stop Speaking
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - Voice Commands
enum VoiceCommand {
    case callFamily
    case callSon
    case callDaughter
    case sendLocation
    case emergency
    case showMedications
    
    var description: String {
        switch self {
        case .callFamily: return "الاتصال بالعائلة"
        case .callSon: return "الاتصال بالابن"
        case .callDaughter: return "الاتصال بالابنة"
        case .sendLocation: return "إرسال الموقع"
        case .emergency: return "طلب المساعدة"
        case .showMedications: return "عرض الأدوية"
        }
    }
}

// MARK: - Voice Errors
enum VoiceError: Error {
    case notAuthorized
    case recognizerNotAvailable
    case unableToCreateRequest
    
    var localizedDescription: String {
        switch self {
        case .notAuthorized:
            return "لم يتم منح إذن التعرف على الصوت"
        case .recognizerNotAvailable:
            return "خدمة التعرف على الصوت غير متوفرة"
        case .unableToCreateRequest:
            return "تعذر إنشاء طلب التعرف على الصوت"
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let voiceCommandReceived = Notification.Name("voiceCommandReceived")
}
