//
//  DynamicWaveVisualizer.swift
//  Lullz
//
//  Created by AI Assistant on 3/9/25.
//

import SwiftUI
import Foundation
import AVFoundation
import Observation

@Observable
final class DynamicWaveVisualizerState {
    var phase: CGFloat = 0
    var amplitude: CGFloat = 1.0
    var waveSpeed: Double = 1.0
    
    func updatePhase(delta: CGFloat) {
        phase += delta
        if phase > 100 {
            phase = 0
        }
    }
    
    func updateAmplitude() {
        amplitude = CGFloat.random(in: 0.9...1.1)
    }
    
    func configureForNoiseType(_ noiseType: AudioManagerImpl.NoiseType) {
        waveSpeed = noiseType.defaultWaveSpeed
    }
}

struct DynamicWaveVisualizer: View {
    private let noiseType: AudioManagerImpl.NoiseType
    @State private var state = DynamicWaveVisualizerState()
    
    // Use a more efficient timer with background priority
    private let timer = Timer.publish(
        every: 0.016,
        on: .main,
        in: .common
    ).autoconnect()
    
    init(noiseType: AudioManagerImpl.NoiseType) {
        self.noiseType = noiseType
    }
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Safety check for zero width or height
                guard size.width > 0, size.height > 0, size.width.isFinite, size.height.isFinite else { return }
                
                let width = size.width
                let height = size.height
                let midHeight = height / 2
                
                // Draw multiple layers for more complex visualization
                let layers = getWaveLayers(for: noiseType)
                
                for layer in layers {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: midHeight))
                    
                    // Draw waveform with higher resolution
                    for x in stride(from: 0, to: width, by: 0.5) {
                        let relativeX = x / width
                        
                        // Calculate y position based on wave parameters with safety checks
                        let localPhase = state.phase * layer.speedMultiplier
                        var y = midHeight + sin(relativeX * layer.frequency * .pi * 2 + localPhase) 
                            * layer.amplitude 
                            * state.amplitude 
                            * midHeight * 0.7
                        
                        // Ensure y is a valid, finite number
                        if !y.isFinite {
                            y = midHeight
                        }
                        
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    // Stroke with appropriate color and opacity
                    context.stroke(
                        path,
                        with: .color(layer.color.opacity(layer.opacity)),
                        lineWidth: layer.lineWidth
                    )
                }
                
                // Add frequency bars for certain noise types
                if noiseType.supportsFrequencyBars {
                    drawFrequencyBars(context: context, size: size)
                }
            }
            .onReceive(timer) { _ in
                // Update phase for continuous animation
                withAnimation(.easeInOut(duration: 1.5)) {
                    state.updatePhase(delta: 0.03 * state.waveSpeed)
                    state.updateAmplitude()
                }
            }
            .onAppear {
                // Set parameters based on noise type
                state.configureForNoiseType(noiseType)
            }
            .task(priority: .background) {
                // Any background processing can go here
            }
        }
    }
    
    private func getWaveLayers(for noiseType: AudioManagerImpl.NoiseType) -> [WaveLayer] {
        switch noiseType {
        case .white:
            return [
                WaveLayer(frequency: 10, amplitude: 0.3, speedMultiplier: 1.0, color: .white, opacity: 0.7, lineWidth: 2),
                WaveLayer(frequency: 20, amplitude: 0.2, speedMultiplier: 1.5, color: .white, opacity: 0.5, lineWidth: 1.5),
                WaveLayer(frequency: 30, amplitude: 0.1, speedMultiplier: 2.0, color: .white, opacity: 0.3, lineWidth: 1)
            ]
            
        case .pink:
            return [
                WaveLayer(frequency: 5, amplitude: 0.4, speedMultiplier: 0.7, color: .pink, opacity: 0.7, lineWidth: 2),
                WaveLayer(frequency: 15, amplitude: 0.2, speedMultiplier: 1.3, color: .pink, opacity: 0.5, lineWidth: 1.5),
                WaveLayer(frequency: 25, amplitude: 0.1, speedMultiplier: 1.8, color: .pink, opacity: 0.3, lineWidth: 1)
            ]
            
        case .brown:
            return [
                WaveLayer(frequency: 2, amplitude: 0.5, speedMultiplier: 0.5, color: .brown, opacity: 0.8, lineWidth: 3),
                WaveLayer(frequency: 4, amplitude: 0.3, speedMultiplier: 0.7, color: .brown, opacity: 0.6, lineWidth: 2),
                WaveLayer(frequency: 8, amplitude: 0.1, speedMultiplier: 0.9, color: .brown, opacity: 0.4, lineWidth: 1)
            ]
            
        case .blue:
            return [
                WaveLayer(frequency: 15, amplitude: 0.2, speedMultiplier: 1.5, color: .blue, opacity: 0.7, lineWidth: 1.5),
                WaveLayer(frequency: 25, amplitude: 0.3, speedMultiplier: 2.0, color: .blue, opacity: 0.7, lineWidth: 2),
                WaveLayer(frequency: 35, amplitude: 0.4, speedMultiplier: 2.5, color: .blue, opacity: 0.6, lineWidth: 1.5)
            ]
            
        case .violet:
            return [
                WaveLayer(frequency: 20, amplitude: 0.2, speedMultiplier: 1.8, color: .purple, opacity: 0.7, lineWidth: 1.5),
                WaveLayer(frequency: 35, amplitude: 0.3, speedMultiplier: 2.2, color: .purple, opacity: 0.7, lineWidth: 2),
                WaveLayer(frequency: 50, amplitude: 0.4, speedMultiplier: 2.7, color: .purple, opacity: 0.6, lineWidth: 1)
            ]
            
        case .grey:
            return [
                WaveLayer(frequency: 5, amplitude: 0.3, speedMultiplier: 0.8, color: .gray, opacity: 0.7, lineWidth: 2),
                WaveLayer(frequency: 12, amplitude: 0.3, speedMultiplier: 1.2, color: .gray, opacity: 0.7, lineWidth: 2),
                WaveLayer(frequency: 20, amplitude: 0.2, speedMultiplier: 1.6, color: .gray, opacity: 0.5, lineWidth: 1.5)
            ]
            
        case .green:
            return [
                WaveLayer(frequency: 4, amplitude: 0.2, speedMultiplier: 0.7, color: .green, opacity: 0.7, lineWidth: 1.5),
                WaveLayer(frequency: 10, amplitude: 0.4, speedMultiplier: 1.0, color: .green, opacity: 0.7, lineWidth: 2),
                WaveLayer(frequency: 18, amplitude: 0.2, speedMultiplier: 1.3, color: .green, opacity: 0.5, lineWidth: 1.5)
            ]
            
        case .black:
            return [
                WaveLayer(frequency: 2, amplitude: 0.1, speedMultiplier: 0.3, color: .gray, opacity: 0.7, lineWidth: 1.5),
                WaveLayer(frequency: 3, amplitude: 0.05, speedMultiplier: 0.4, color: .gray, opacity: 0.5, lineWidth: 1)
            ]
        }
    }
    
    private func drawFrequencyBars(context: GraphicsContext, size: CGSize) {
        // Safety check for zero width or height
        guard size.width > 0, size.height > 0, size.width.isFinite, size.height.isFinite else { return }
        
        let barCount = 20
        let barWidth = size.width / CGFloat(barCount)
        let maxHeight = size.height * 0.5
        
        for i in 0..<barCount {
            let x = CGFloat(i) * barWidth
            
            // Height varies based on a semi-random pattern with phase influence
            let heightFactor: CGFloat
            
            switch noiseType {
            case .white:
                // Random heights for white noise
                heightFactor = CGFloat.random(in: 0.2...1.0)
            case .pink:
                // Decreasing heights for pink noise (higher at low frequencies)
                let baseFactor = 1.0 - (CGFloat(i) / CGFloat(barCount) * 0.7)
                heightFactor = baseFactor * CGFloat.random(in: 0.5...1.0)
            case .grey:
                // More balanced heights for grey noise
                heightFactor = CGFloat.random(in: 0.4...0.8)
            default:
                heightFactor = 0.5
            }
            
            let height = maxHeight * heightFactor
            // Ensure height is positive and finite
            guard height > 0, height.isFinite else { continue }
            
            let y = (size.height - height) / 2
            // Ensure y is finite
            guard y.isFinite else { continue }
            
            // Ensure all rect parameters are valid
            guard barWidth > 0, x.isFinite, barWidth.isFinite else { continue }
            
            let rect = CGRect(x: x + 1, y: y, width: max(0, barWidth - 2), height: height)
            let color = noiseType.color
            
            // Draw bar
            context.fill(
                Path(roundedRect: rect, cornerRadius: 2),
                with: .color(color.opacity(0.5))
            )
        }
    }
    
    // Helper struct for wave parameters
    struct WaveLayer {
        let frequency: CGFloat
        let amplitude: CGFloat
        let speedMultiplier: CGFloat
        let color: Color
        let opacity: Double
        let lineWidth: CGFloat
    }
}

// MARK: - NoiseType Extensions
private extension AudioManagerImpl.NoiseType {
    var defaultWaveSpeed: Double {
        switch self {
        case .white: return 1.5
        case .pink: return 1.2
        case .brown: return 0.7
        case .blue: return 1.8
        case .violet: return 2.0
        case .grey: return 1.0
        case .green: return 0.9
        case .black: return 0.5
        }
    }
    
    var supportsFrequencyBars: Bool {
        [.white, .pink, .grey].contains(self)
    }
    
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
        }
    }
}

#Preview {
    NavigationStack {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            DynamicWaveVisualizer(noiseType: .white)
                .frame(height: 200)
                .padding()
        }
    }
} 