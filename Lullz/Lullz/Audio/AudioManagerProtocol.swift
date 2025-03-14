import Foundation
import AVFoundation
import SwiftUI

// Define a protocol that both audio manager implementations will conform to
protocol AudioManagerProtocol: ObservableObject {
    var isPlaying: Bool { get set }
    var volume: Double { get set }
    
    // Add the missing properties that are referenced in other files
    var sleepTimerActive: Bool { get set }
    var sleepTimerDuration: TimeInterval { get set }
    
    // Define SoundCategory enum - use a qualified name to avoid ambiguity
    typealias SoundCategory = AudioManagerNoiseType
}

// Use this extension to provide default implementations
extension AudioManagerProtocol {
    var sleepTimerActive: Bool {
        get { false }
        set { }
    }
    
    var sleepTimerDuration: TimeInterval {
        get { 0 }
        set { }
    }
}

// Renamed to AudioManagerNoiseType to avoid conflicts with other NoiseType enums
enum AudioManagerNoiseType: String, CaseIterable, Identifiable {
    case white, pink, brown, blue, violet, grey, green, black, binaural, noise
    
    var id: String { rawValue }
    
    // Define colors for UI references that use .white, .pink, etc.
    var color: Color {
        switch self {
        case .white: return .white
        case .pink: return .pink
        case .brown: return .brown
        case .blue: return .blue
        case .violet: return .purple
        case .grey: return .gray
        case .green: return .green
        case .black: return .black
        case .binaural: return .cyan
        case .noise: return .orange
        }
    }
}
