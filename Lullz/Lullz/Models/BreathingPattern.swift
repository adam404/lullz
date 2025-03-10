//
//  BreathingPattern.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import Foundation
import SwiftData

enum BreathPhase: String, Codable, CaseIterable {
    case inhale = "Inhale"
    case exhale = "Exhale"
    case hold = "Hold"
    case holdAfterInhale = "Hold after inhale"
    case holdAfterExhale = "Hold after exhale"
    
    var instruction: String {
        switch self {
        case .inhale: return "Breathe in slowly"
        case .exhale: return "Breathe out slowly"
        case .hold, .holdAfterInhale: return "Hold your breath"
        case .holdAfterExhale: return "Hold your breath"
        }
    }
}

struct BreathStep: Codable, Identifiable, Hashable {
    var id = UUID()
    var phase: BreathPhase
    var durationSeconds: Double
    
    static func == (lhs: BreathStep, rhs: BreathStep) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Model
final class BreathingPattern {
    @Attribute(.unique) var name: String
    var patternDescription: String
    var steps: [BreathStep]
    var isPreset: Bool = false
    var createdAt: Date
    
    // Audio settings
    var useAudioCues: Bool = true
    var audioVolume: Float = 0.4
    var backgroundNoiseType: String? // Optional noise in the background
    var backgroundNoiseVolume: Float = 0.2
    var binauralPreset: String? // Optional binaural beats
    
    // Visual settings
    var accentColor: String = "#007AFF" // Default iOS blue
    
    // Additional settings
    var vibrationEnabled: Bool = true
    var voiceGuidanceEnabled: Bool = false
    
    var inhaleTime: Double
    var holdAfterInhale: Double
    var exhaleTime: Double
    var holdAfterExhale: Double
    
    init(name: String, description: String, steps: [BreathStep], isPreset: Bool = false) {
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
    var cycleDuration: Double {
        steps.reduce(0) { $0 + $1.durationSeconds }
    }
} 
