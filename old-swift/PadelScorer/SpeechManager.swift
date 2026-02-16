import Foundation
import Speech
import AVFoundation
import Observation

@Observable
final class SpeechManager {
    var isListening = false
    var lastHeard = ""
    var authStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    var onTeamDetected: ((Team) -> Void)?

    private let usWords: Set<String> = ["us", "hours", "ours", "nuestro", "nuestros", "nosotros"]
    private let themWords: Set<String> = ["them", "then", "suyo", "suyos", "ellos"]

    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { self.authStatus = status }
        }
        AVAudioApplication.requestRecordPermission { _ in }
    }

    func toggleListening() {
        if isListening { stopListening() } else { startListening() }
    }

    func startListening() {
        guard authStatus == .authorized, let speechRecognizer, speechRecognizer.isAvailable else { return }

        stopListening()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = false
        self.recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self, let result else {
                if error != nil { self?.stopListening() }
                return
            }
            let text = result.bestTranscription.formattedString.lowercased()
            self.lastHeard = text

            let words = text.split(separator: " ").map(String.init)
            if let lastWord = words.last {
                if self.usWords.contains(lastWord) {
                    self.onTeamDetected?(.us)
                    // Restart to listen for next command
                    self.restartListening()
                } else if self.themWords.contains(lastWord) {
                    self.onTeamDetected?(.them)
                    self.restartListening()
                }
            }
        }

        do {
            try audioEngine.start()
            isListening = true
        } catch {
            stopListening()
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }

    private func restartListening() {
        stopListening()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startListening()
        }
    }
}
