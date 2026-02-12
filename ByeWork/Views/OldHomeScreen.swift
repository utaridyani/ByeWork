//
//  HomeScreen.swift
//  ByeWork
//
//  Created by Utari Dyani Laksmi on 11/02/26.
//


import SwiftUI


struct OldHomeScreen: View {
    // for text
    @State private var showAltText = false
    @State private var pulseStarted: Bool = false
    @State private var pulsePhase = false
    
    @StateObject private var speech = SpeechRecognizer()
    @State private var nextScreen: Bool = false
    @State private var randomQuote: Quote = QuotesData.all.randomElement()!
    @State private var randomSpeakInstruction: SpeakInstruction = SpeakInstructionData.all.randomElement()!
    
    var speakInstruction: String {
            randomSpeakInstruction.text
        }
    
    var body: some View {
        NavigationStack {
            // mic logic
            VStack(spacing: 80){
                // quote, randomize everytime the screen appear
                // Text(randomQuote.text)
                
                Text("Let's say \(randomSpeakInstruction.text)")
                
                Text(speech.spokenText.isEmpty ? "Testing here" : speech.spokenText)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // mic
                // dont forget to add plist for mic privacy
                Button {
                    speech.startRecording()
                } label: {
                    Image(systemName: speech.isRecording ? "mic.fill" : "mic")
                        .font(.largeTitle)
                        .padding()
                        .background(Circle().fill(speech.isRecording ? .red : .blue))
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                randomQuote = QuotesData.all.randomElement()!
                randomSpeakInstruction = SpeakInstructionData.all.randomElement()!
                speech.requestPermission()
            }
            .onChange(of: speech.spokenText) { _, newValue in
                checkIfMatched(newValue)
            }
            .navigationDestination(isPresented: $nextScreen) {
                SecondScreen()
            }
            .navigationBarBackButtonHidden(true)
        }
    }
    
    func checkIfMatched(_ spoken: String) {
        
        let cleanedSpoken = spoken
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
        
        let cleanedInstruction = speakInstruction
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
        
        print("Spoken:", cleanedSpoken)
        print("Expected:", cleanedInstruction)
        
        if cleanedSpoken.contains(cleanedInstruction) && !nextScreen {
            speech.stopRecording()
            nextScreen = true
        }
    }
    
}

#Preview {
    HomeScreen()
}
