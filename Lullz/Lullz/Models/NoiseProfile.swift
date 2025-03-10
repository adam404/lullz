//
//  NoiseProfile.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import Foundation
import SwiftData

@Model
final class NoiseProfile {
    var name: String
    var noiseType: String
    var volume: Float
    var balance: Float
    var leftDelay: Float
    var rightDelay: Float
    var createdAt: Date
    
    init(name: String, noiseType: String, volume: Float, balance: Float, leftDelay: Float, rightDelay: Float) {
        self.name = name
        self.noiseType = noiseType
        self.volume = volume
        self.balance = balance
        self.leftDelay = leftDelay
        self.rightDelay = rightDelay
        self.createdAt = Date()
    }
} 