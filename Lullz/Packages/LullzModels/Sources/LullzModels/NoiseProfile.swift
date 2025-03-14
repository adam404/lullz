import Foundation
import SwiftData
import LullzCore

@Model
public final class NoiseProfile {
    public var name: String
    public var noiseType: String
    public var volume: Float
    public var balance: Float
    public var leftDelay: Float
    public var rightDelay: Float
    public var createdAt: Date
    
    public init(name: String, noiseType: String, volume: Float, balance: Float, leftDelay: Float, rightDelay: Float) {
        self.name = name
        self.noiseType = noiseType
        self.volume = volume
        self.balance = balance
        self.leftDelay = leftDelay
        self.rightDelay = rightDelay
        self.createdAt = Date()
    }
} 