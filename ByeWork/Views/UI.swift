//
//  UI.swift
//  ByeWork
//
//  Created by Utari Dyani Laksmi on 11/02/26.
//

// Screen1View.swift
// Your first screen - add your content inside the NavigationStack
import SwiftUI

struct Screen3View: View {
    @State private var showAltText = false
        @State private var pulseStarted = false
        @State private var pulsePhase = false
    
    var body: some View {
        VStack(spacing: 80) {
            
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    ZStack {
                        Image("bubble-gr")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 400, height: 200)

                        VStack(spacing: 0) {
                            Text(showAltText ? "Lets say" : "Today might be long,")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(.black)
                                .animation(nil, value: showAltText)   // prevent text swap animation

                            ZStack {
                                Text("Great Day!")
                                    .opacity(showAltText ? 1 : 0)

                                Text("but its still YOUR day.")
                                    .opacity(showAltText ? 0 : 1)
                            }
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
                    
                }

                Button(action: {
                    // action here
                }) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.purple).font(Font.system(size: 32))
                }
                .frame(width: 80, height: 80)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.2), radius: 4)
//                .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
            }
        }
        .padding(CGFloat(24))
    }
}

#Preview {
    Screen3View()
}
