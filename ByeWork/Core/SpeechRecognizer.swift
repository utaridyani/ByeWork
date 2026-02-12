//
//  SpeechRecognition.swift
//  ByeWork
//
//  Created by Utari Dyani Laksmi on 11/02/26.
//

import Foundation
import Speech
import AVFoundation
import Combine

class SpeechRecognizer: ObservableObject {
    
    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    
    @Published var spokenText: String = ""
    @Published var isRecording = false
    
    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            print("Speech auth status:", status)
        }
    }
    
    func startRecording() {
        
        if audioEngine.isRunning {
            stopRecording()
            return
        }
        
        spokenText = ""
        
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        
        let inputNode = audioEngine.inputNode
        
        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                DispatchQueue.main.async {
                    self.spokenText = result.bestTranscription.formattedString
                    self.resetSilenceTimer()
                }
            }

            if error != nil {
                self.stopRecording()
            }
        }
        
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            print("AudioEngine start error:", error)
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.handleSilence()
        }
    }

    private func handleSilence() {
        print("2 seconds silence detected")
        stopRecording()
    }
}
