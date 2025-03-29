//
//  NoiseTypeVisualizer.swift
//  Lullz
//
//  Created by Adam Scott on 3/9/25.
//

import SwiftUI
import AVFoundation

struct NoiseTypeVisualizer: View {
    let noiseType: AudioManagerImpl.NoiseType
    let isPlaying: Bool
    let visualizer: SoundVisualizer
    
    // Number of bars to display in the visualizer
    private let barCount = 15
    
    // Generate sample data based on noise type
    private func generateSampleData() -> [CGFloat] {
        // If we're not playing, return a flat line with some randomness
        if !isPlaying {
            return (0..<barCount).map { _ in CGFloat.random(in: 0.05...0.15) }
        }
        
        // Generate data based on noise type characteristics
        switch noiseType {
        case .white:
            // White noise has equal energy across all frequencies
            return (0..<barCount).map { _ in CGFloat.random(in: 0.3...0.8) }
            
        case .pink:
            // Pink noise decreases with frequency (1/f)
            return (0..<barCount).map { i in
                let base = 0.8 - (CGFloat(i) / CGFloat(barCount) * 0.5)
                return base + CGFloat.random(in: -0.15...0.15)
            }
            
        case .brown:
            // Brown noise decreases more rapidly with frequency (1/f²)
            return (0..<barCount).map { i in
                let base = 0.8 - (pow(CGFloat(i) / CGFloat(barCount), 2) * 0.7)
                return base + CGFloat.random(in: -0.1...0.1)
            }
            
        case .blue:
            // Blue noise increases with frequency
            return (0..<barCount).map { i in
                let base = 0.3 + (CGFloat(i) / CGFloat(barCount) * 0.5)
                return base + CGFloat.random(in: -0.15...0.15)
            }
            
        case .violet:
            // Violet noise increases more rapidly with frequency
            return (0..<barCount).map { i in
                let base = 0.2 + (pow(CGFloat(i) / CGFloat(barCount), 2) * 0.7)
                return base + CGFloat.random(in: -0.1...0.1)
            }
            
        case .grey:
            // Grey noise has a psychoacoustic equal loudness curve
            return (0..<barCount).map { i in
                // Simulate the equal loudness contour (roughly)
                let mid = barCount / 2
                let distance = abs(i - mid)
                let base = 0.7 - (CGFloat(distance) / CGFloat(barCount) * 0.3)
                return base + CGFloat.random(in: -0.15...0.15)
            }
            
        case .green:
            // Green noise is focused in the middle frequency range
            return (0..<barCount).map { i in
                let mid = barCount / 2
                let distance = abs(i - mid)
                let base = distance < 5 ? 0.7 - (CGFloat(distance) / 10.0) : 0.2
                return base + CGFloat.random(in: -0.1...0.1)
            }
            
        case .black:
            // Black noise has minimal energy
            return (0..<barCount).map { _ in CGFloat.random(in: 0.05...0.2) }
        }
    }
    
    var body: some View {
        // Use a timer to update the visualization
        TimelineView(.animation(minimumInterval: 0.1, paused: !isPlaying)) { _ in
            HStack(spacing: 2) {
                ForEach(generateSampleData(), id: \.self) { value in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: value))
                        .frame(height: value * 60) // Scale the height
                }
            }
        }
    }
    
    // Helper to determine bar color based on noise type and value
    private func barColor(for value: CGFloat) -> Color {
        let baseColor: Color
        
        switch noiseType {
        case .white:
            baseColor = Color.white
        case .pink:
            baseColor = Color.pink
        case .brown:
            baseColor = Color.brown
        case .blue:
            baseColor = Color.blue
        case .violet:
            baseColor = Color.purple
        case .grey:
            baseColor = Color.gray
        case .green:
            baseColor = Color.green
        case .black:
            baseColor = Color.black
        }
        
        // For dark colors like black and brown, make them more visible
        if noiseType == .black || noiseType == .brown {
            return baseColor.opacity(0.8).lighter(by: 0.3)
        }
        
        return baseColor.opacity(0.8)
    }
}

// Helper extension to lighten colors
extension Color {
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
}

// Helper to make array of CGFloat conform to RandomAccessCollection
extension Array: RandomAccessCollection where Element == CGFloat {}

struct NoiseTypeVisualizer_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ForEach(AudioManagerImpl.NoiseType.allCases) { noiseType in
                VStack {
                    Text(noiseType.rawValue)
                    NoiseTypeVisualizer(
                        noiseType: noiseType,
                        isPlaying: true,
                        visualizer: SoundVisualizer(audioEngine: AVAudioEngine())
                    )
                    .frame(height: 60)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}
