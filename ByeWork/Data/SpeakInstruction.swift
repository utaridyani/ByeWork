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
            text: "Good job"
        ),
        SpeakInstruction(
            text: "Great job"
        ),
        SpeakInstruction(
            text: "Thank you"
        ),
        SpeakInstruction(
            text: "See you"
        )
    ]
}
