//
//  Item.swift
//  ByeWork
//
//  Created by Utari Dyani Laksmi on 11/02/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
