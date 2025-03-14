import Foundation
import SwiftData
import LullzCore

public enum BreathPhase: String, Codable, CaseIterable {
    case inhale = "Inhale"
    case exhale = "Exhale"
    case hold = "Hold"
    case holdAfterInhale = "Hold after inhale"
    case holdAfterExhale = "Hold after exhale"
    
    public var instruction: String {
        switch self {
        case .inhale: return "Breathe in slowly"
        case .exhale: return "Breathe out slowly"
        case .hold, .holdAfterInhale: return "Hold your breath"
        case .holdAfterExhale: return "Hold your breath"
        }
    }
}

public struct BreathStep: Codable, Identifiable, Hashable {
    public var id = UUID()
    public var phase: BreathPhase
    public var durationSeconds: Double
    
    public init(phase: BreathPhase, durationSeconds: Double) {
        self.phase = phase
        self.durationSeconds = durationSeconds
    }
    
    public static func == (lhs: BreathStep, rhs: BreathStep) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Model
public final class BreathingPattern {
    @Attribute(.unique) public var name: String
    public var patternDescription: String
    public var steps: [BreathStep]
    public var isPreset: Bool = false
    public var createdAt: Date
    
    // Audio settings
    public var useAudioCues: Bool = true
    public var audioVolume: Float = 0.4
    public var backgroundNoiseType: String? // Optional noise in the background
    public var backgroundNoiseVolume: Float = 0.2
    public var binauralPreset: String? // Optional binaural beats
    
    // Visual settings
    public var accentColor: String = "#007AFF" // Default iOS blue
    
    // Additional settings
    public var vibrationEnabled: Bool = true
    public var voiceGuidanceEnabled: Bool = false
    
    public var inhaleTime: Double
    public var holdAfterInhale: Double
    public var exhaleTime: Double
    public var holdAfterExhale: Double
    
    public init(name: String, description: String, steps: [BreathStep], isPreset: Bool = false) {
        self.name = name
        self.patternDescription = description
        self.steps = steps
        self.isPreset = isPreset
        self.createdAt = Date()
        
        // Initialize the time variables with default values
        // These can be calculated based on steps or set to default values
        self.inhaleTime = steps.first(where: { $0.phase == .inhale })?.durationSeconds ?? 4.0
        self.holdAfterInhale = steps.first(where: { $0.phase == .holdAfterInhale })?.durationSeconds ?? 1.0
        self.exhaleTime = steps.first(where: { $0.phase == .exhale })?.durationSeconds ?? 4.0
        self.holdAfterExhale = steps.first(where: { $0.phase == .holdAfterExhale })?.durationSeconds ?? 1.0
    }
    
    // Helper to get total cycle time
    public var cycleDuration: Double {
        steps.reduce(0) { $0 + $1.durationSeconds }
    }
} 