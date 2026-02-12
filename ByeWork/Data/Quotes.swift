//
//  Quotes.swift
//  ByeWork
//
//  Created by Utari Dyani Laksmi on 11/02/26.
//

import Foundation

struct Quote: Identifiable {
    let id = UUID()
    let text: String
}

struct QuotesData {
    static let all: [Quote] = [
        Quote(
            text: "No matter what happened, it’s great day and I’m glad we got through it"
        ),
        Quote(
            text: "2. No matter what happened, it’s great day and I’m glad we got through it"
        ),
        Quote(
            text: "3. No matter what happened, it’s great day and I’m glad we got through it"
        )
    ]
}
