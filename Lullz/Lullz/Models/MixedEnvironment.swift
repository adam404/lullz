//
//  MixedEnvironment.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import Foundation
import SwiftData

// Define the ModulationType enum first, outside of any class
enum ModulationType: String, Codable {
    case none = "None"
    case amplitude = "Amplitude"
    case frequency = "Frequency"
    case spatial = "Spatial"
}

// Main environment model
@Model
final class MixedEnvironment {
    @Attribute(.unique) var id: UUID
    var name: String
    var environmentDescription: String
    var createdAt: Date
    var isPreset: Bool = false
    
    @Relationship var soundLayers: [SoundLayer] = []
    
    init(name: String, description: String, layers: [SoundLayer] = []) {
        self.id = UUID()
        self.name = name
        self.environmentDescription = description
        self.createdAt = Date()
        self.soundLayers = layers
    }
    
    // Computed property to maintain compatibility with existing code
    var layers: [SoundLayer] {
        get { return soundLayers }
        set { soundLayers = newValue }
    }
}

// Sound layer model
@Model
final class SoundLayer {
    var id: UUID
    var soundType: String // "white", "pink", "brown", etc. or "binaural_relaxation", etc.
    var volume: Float
    var balance: Float
    var isActive: Bool
    
    // For binaural beats only
    var binauralPreset: String?
    
    // For special effects - store these as strings to work with SwiftData
    var modulationType: String?
    var modulationRate: Float?
    var modulationDepth: Float?
    
    // Parent relationship
    var environment: MixedEnvironment?
    
    init(soundType: String, volume: Float, balance: Float, isActive: Bool, 
         binauralPreset: String? = nil, modulation: ModulationType? = nil, 
         modulationRate: Float? = nil, modulationDepth: Float? = nil) {
        self.id = UUID()
        self.soundType = soundType
        self.volume = volume
        self.balance = balance
        self.isActive = isActive
        self.binauralPreset = binauralPreset
        self.modulationType = modulation?.rawValue
        self.modulationRate = modulationRate
        self.modulationDepth = modulationDepth
    }
    
    // Computed property for modulation to maintain compatibility
    var modulation: ModulationType? {
        get {
            guard let type = modulationType else { return nil }
            return ModulationType(rawValue: type)
        }
        set {
            modulationType = newValue?.rawValue
        }
    }
} 