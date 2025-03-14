import Foundation
import SwiftData
import LullzCore

// Define the ModulationType enum first, outside of any class
public enum ModulationType: String, Codable {
    case none = "None"
    case amplitude = "Amplitude"
    case frequency = "Frequency"
    case spatial = "Spatial"
}

// Main environment model
@Model
public final class MixedEnvironment {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var environmentDescription: String
    public var createdAt: Date
    public var isPreset: Bool = false
    
    @Relationship public var soundLayers: [SoundLayer] = []
    
    public init(name: String, description: String, layers: [SoundLayer] = []) {
        self.id = UUID()
        self.name = name
        self.environmentDescription = description
        self.createdAt = Date()
        self.soundLayers = layers
    }
    
    // Computed property to maintain compatibility with existing code
    public var layers: [SoundLayer] {
        get { return soundLayers }
        set { soundLayers = newValue }
    }
}

// Sound layer model
@Model
public final class SoundLayer {
    public var id: UUID
    public var soundType: String // "white", "pink", "brown", etc. or "binaural_relaxation", etc.
    public var volume: Float
    public var balance: Float
    public var isActive: Bool
    
    // For binaural beats only
    public var binauralPreset: String?
    
    // For special effects - store these as strings to work with SwiftData
    public var modulationType: String?
    public var modulationRate: Float?
    public var modulationDepth: Float?
    
    // Parent relationship
    public var environment: MixedEnvironment?
    
    public init(soundType: String, volume: Float, balance: Float, isActive: Bool, 
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
    public var modulation: ModulationType? {
        get {
            guard let type = modulationType else { return nil }
            return ModulationType(rawValue: type)
        }
        set {
            modulationType = newValue?.rawValue
        }
    }
} 