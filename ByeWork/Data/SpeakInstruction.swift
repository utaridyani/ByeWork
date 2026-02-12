//
//  SpeakInstruction.swift
//  ByeWork
//
//  Created by Utari Dyani Laksmi on 11/02/26.
//

import Foundation

struct SpeakInstruction: Identifiable {
    let id = UUID()
    let text: String
}

struct SpeakInstructionData {
    static let all: [SpeakInstruction] = [
        SpeakInstruction(
            text: "Good Morning"
        ),
        SpeakInstruction(
            text: "Good Afternoon"
        ),
        SpeakInstruction(
            text: "Good Night"
        )
    ]
}
