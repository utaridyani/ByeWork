//
//  HomeScreen.swift
//  ByeWork
//
//  Created by Utari Dyani Laksmi on 11/02/26.
//


import SwiftUI


struct HomeScreen: View {
    // for text
    @State private var showAltText = false
    @State private var pulseStarted: Bool = false
    @State private var pulsePhase = false
    
    @StateObject private var speech = SpeechRecognizer()
    @State private var nextScreen: Bool = false
    @State private var randomQuote: Quote = QuotesData.all.randomElement()!
    @State private var randomQuote2: [Quote2] = QuotesData2.all
    @State private var randomSpeakInstruction: SpeakInstruction = SpeakInstructionData.all.randomElement()!
    
    var speakInstruction: String {
            randomSpeakInstruction.text
        }
    
    var body: some View {
        NavigationStack {
            // mic logic
            VStack(spacing: 80){
                VStack(spacing: 0){
                    VStack(spacing: 0) {
                        ZStack {
                            Image("bubble-gr")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 470, height: 210)
                            
                            VStack(spacing: 0) {
                                Text(showAltText ? "Lets say" : randomQuote.text)
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundColor(.white)
                                    .animation(nil, value: showAltText)   // prevent text swap animation
                                
                                ZStack {
                                    Text(randomSpeakInstruction.text)
                                        .opacity(showAltText ? 1 : 0)
                                    
                                    Text(randomQuote2[randomQuote.id].text)
                                        .opacity(showAltText ? 0 : 1)
                                }
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .fontDesign(.rounded)
                                .animation(nil, value: showAltText)   // prevent text swap animation
                                .scaleEffect(pulseStarted ? (pulsePhase ? 1.05 : 0.95) : 1.0)
                                .opacity(pulseStarted ? (pulsePhase ? 1.0 : 0.7) : 1.0)
                                .animation(
                                    pulseStarted
                                    ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                                    : nil,
                                    value: pulsePhase
                                )
                            }
                            .offset(y: -16)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                // 1) swap text instantly (no animation)
                                showAltText = true
                                
                                // 2) start pulsing from this moment onward
                                pulseStarted = true
                                pulsePhase = true
                            }
                        }
                        
                        Image("smile2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 400, height: 300)
                        
                        
                        // mic
                        // dont forget to add plist for mic privacy
                    }
                    Button {
                        speech.startRecording()
                    } label: {
                        Image(systemName: speech.isRecording ? "mic.fill" : "mic")
                            .font(.system(size: 32))
                            .foregroundColor(speech.isRecording ? .white : .purple)
                            .animation(.easeInOut(duration: 0.3), value: speech.isRecording)
                    }
                    .frame(width: 80, height: 80)
//                    .scaleEffect(speech.isRecording ? 1.5 : 1.0)
                    .background(speech.isRecording ? Color.purple : Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4)
                        
                    
                    // for testing
//                    Text(speech.spokenText.isEmpty ? "Testing here" : speech.spokenText)
//                        .foregroundStyle(.gray)
//                        .multilineTextAlignment(.center)
//                        .padding()
                }
                .onAppear {
                    randomQuote = QuotesData.all.randomElement()!
                    randomSpeakInstruction = SpeakInstructionData.all.randomElement()!
                    speech.requestPermission()
                }
                .onChange(of: speech.spokenText) { _, newValue in
                    checkIfMatched(newValue)
                }
                .onChange(of: speech.isRecording) { _, isRecording in
                    if !isRecording && !nextScreen {
                        handleWrongAnswer()
                    }
                }
                .navigationDestination(isPresented: $nextScreen) {
                    ShakeView(isActive: $nextScreen)
                }
                .navigationBarBackButtonHidden(true)
                }
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
    
    func handleWrongAnswer() {
        let cleanedSpoken = speech.spokenText
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
        
        let cleanedInstruction = speakInstruction
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
        
        if !cleanedSpoken.contains(cleanedInstruction) {
            print("wrong")
            
            speech.spokenText = ""
            randomSpeakInstruction = SpeakInstructionData.all.randomElement()!
        }
    }
    
}

#Preview {
    HomeScreen()
}
