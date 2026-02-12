// Screen2View.swift
// Your second screen - add your content inside the NavigationStack
import SwiftUI

struct Screen2View: View {
    @State private var wobble = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 80) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
         
                    ZStack {
                        Image("bubble-gr")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 400, height: 200)
                            .rotationEffect(.degrees(wobble ? 0.5 : -0.5))
                            .animation(
                                .easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true),
                                value: wobble
                            )
                            .onAppear { wobble = true }
                        
                        VStack(spacing: 0) {
                            Text("Now")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(.white)

                            Text("“Raise your phone\nand shake it!”")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .fontDesign(.rounded)
                                .scaleEffect(pulse ? 1 : 0.925)
                                .opacity(pulse ? 1.0 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true),
                                    value: pulse
                                )
                                .onAppear {
                                    pulse = true
                                }
                        }.offset(y: -16)
                    }

                    Image("wave2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 300)
                        .rotationEffect(.degrees(wobble ? 1 : -1))
                        .animation(
                            .easeInOut(duration: 0.3)
                                .repeatForever(autoreverses: true),
                            value: wobble
                        )
                        .onAppear { wobble = true }
                }
            }
        }
        .padding(CGFloat(24))
    }
}

#Preview {
    Screen2View()
}
