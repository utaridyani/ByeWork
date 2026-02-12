//
//  SecondScreen.swift
//  ByeWork
//
//  Created by Utari Dyani Laksmi on 11/02/26.
//

import SwiftUI

struct SecondScreen: View {
    
    @State private var goBack: Bool = false
    
    var body: some View {
        VStack {
            Text("Second Screen")
            
            Button("Go Back") {
                goBack.toggle()
            }
        }
        .navigationDestination(isPresented: $goBack) {
            HomeScreen()
        }
    }
}

#Preview {
    NavigationStack {
        SecondScreen()
    }
}
