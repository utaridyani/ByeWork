//
//  Quotes.swift
//  ByeWork
//
//  Created by Utari Dyani Laksmi on 11/02/26.
//

import Foundation

struct Quote2: Identifiable {
    let id: Int
    let text: String
}

struct QuotesData2 {
    static let all: [Quote2] = [
        Quote2(id: 0, text: "but its still YOUR day"),
        Quote2(id: 1, text: "you can do is rest"),
        Quote2(id: 2, text: "let's leave it for tomorrow"),
        Quote2(id: 3, text: "Home is ready for you")
    ]
}
