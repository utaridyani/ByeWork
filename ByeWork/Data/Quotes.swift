//
//  Quotes.swift
//  ByeWork
//
//  Created by Utari Dyani Laksmi on 11/02/26.
//

import Foundation

struct Quote: Identifiable {
    let id: Int
    let text: String
}

struct QuotesData {
    static let all: [Quote] = [
        Quote(id: 0, text: "Today might be long,"),
        Quote(id: 1, text: "Some days are heavy,"),
        Quote(id: 2, text: "It’s okay to pause,"),
        Quote(id: 3, text: "Work is done for today,")
    ]
}
