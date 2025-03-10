//
//  Item.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
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
