//
//  BinauralBeatsGenerator.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import Foundation
import AVFoundation

class BinauralBeatsGenerator {
    
    enum BrainwaveState: String, CaseIterable, Identifiable {
        case delta = "Delta"
        case theta = "Theta"
        case alpha = "Alpha"
        case beta = "Beta"
        case gamma = "Gamma"
        
        var id: String { self.rawValue }
        
        var frequencyRange: ClosedRange<Float> {
            switch self {
            case .delta: return 0.5...4.0    // Deep sleep
            case .theta: return 4.0...8.0    // Meditation, drowsiness
            case .alpha: return 8.0...13.0   // Relaxed alertness
            case .beta: return 13.0...30.0   // Active thinking
            case .gamma: return 30.0...100.0 // Higher mental activity
            }
        }
        
        var description: String {
            switch self {
            case .delta:
                return "0.5-4Hz: Associated with deep, dreamless sleep and healing. May help with deep relaxation and recovery."
            case .theta:
                return "4-8Hz: Associated with meditation, creativity, and REM sleep. May enhance intuition and deep relaxation."
            case .alpha:
                return "8-13Hz: Associated with relaxed alertness and calmness. May reduce stress and promote mindfulness."
            case .beta:
                return "13-30Hz: Associated with active thinking and focus. May improve concentration and mental performance."
            case .gamma:
                return "30-100Hz: Associated with higher cognitive processing. May enhance perception and problem-solving."
            }
        }
    }
    
    enum BinauralPreset: String, CaseIterable, Identifiable {
        case relaxation = "Deep Relaxation"
        case focus = "Enhanced Focus"
        case meditation = "Meditation"
        case sleep = "Sleep Aid"
        case creativity = "Creativity"
        case hemisync = "Hemi-Sync"
        
        var id: String { self.rawValue }
        
        var leftFrequency: Float {
            switch self {
            case .relaxation: return 200.0
            case .focus: return 315.0
            case .meditation: return 250.0
            case .sleep: return 180.0
            case .creativity: return 220.0
            case .hemisync: return 210.0
            }
        }
        
        var rightFrequency: Float {
            switch self {
            case .relaxation: return 204.0 // 4Hz binaural beat (theta)
            case .focus: return 325.0 // 10Hz binaural beat (alpha)
            case .meditation: return 256.0 // 6Hz binaural beat (theta)
            case .sleep: return 182.0 // 2Hz binaural beat (delta)
            case .creativity: return 228.0 // 8Hz binaural beat (alpha)
            case .hemisync: return 226.0 // 16Hz binaural beat (beta)
            }
        }
        
        var description: String {
            switch self {
            case .relaxation:
                return "A 4Hz theta binaural beat to promote deep relaxation and tranquility."
            case .focus:
                return "A 10Hz alpha binaural beat designed to enhance concentration and mental clarity."
            case .meditation:
                return "A 6Hz theta binaural beat for meditation and mindfulness practices."
            case .sleep:
                return "A 2Hz delta binaural beat to help with falling asleep and improving sleep quality."
            case .creativity:
                return "An 8Hz alpha binaural beat to stimulate creative thinking and problem-solving."
            case .hemisync:
                return "A specialized 16Hz beta binaural beat designed to synchronize brain hemispheres using the Hemi-Sync® technique."
            }
        }
        
        var scientificBasis: String {
            switch self {
            case .relaxation:
                return "Theta brainwaves (4-8Hz) are associated with deep relaxation and meditation. Research suggests exposure to theta binaural beats may enhance theta brainwave activity."
            case .focus:
                return "Alpha brainwaves (8-13Hz) are linked to relaxed alertness. Studies indicate alpha binaural beats may improve attention and reduce errors in cognitive tasks."
            case .meditation:
                return "Theta binaural beats at 6Hz target the frequency range associated with deep meditation states. Research has shown potential benefits for meditative practice."
            case .sleep:
                return "Delta brainwaves (0.5-4Hz) dominate during deep sleep stages. Delta binaural beats may help transition into sleep states according to sleep laboratory research."
            case .creativity:
                return "The alpha-theta boundary (around 8Hz) is associated with creative insights and 'flow states'. Studies suggest this frequency may enhance creative problem-solving."
            case .hemisync:
                return "Hemi-Sync® technology, developed by the Monroe Institute, uses binaural beats to promote synchronization between left and right brain hemispheres. It utilizes specific frequency following responses to guide the brain into targeted states."
            }
        }
    }
    
    // Generate samples for the left and right channels with binaural beat
    static func generateBinauralSamples(leftFreq: Float, rightFreq: Float, sampleRate: Double, time: Double) -> (left: Float, right: Float) {
        let leftPhase = Float(2.0 * Double.pi * Double(leftFreq) * time)
        let rightPhase = Float(2.0 * Double.pi * Double(rightFreq) * time)
        
        // Use sine waves for clean tones
        let leftSample = sin(leftPhase)
        let rightSample = sin(rightPhase)
        
        return (leftSample, rightSample)
    }
} 