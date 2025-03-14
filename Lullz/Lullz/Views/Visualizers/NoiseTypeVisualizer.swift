//
//  NoiseTypeVisualizer.swift
//  Lullz
//
//  Created by AI Assistant on 3/9/25.
//

import SwiftUI

struct NoiseTypeVisualizer: View {
    let noiseType: AudioManagerImpl.NoiseType
    let isPlaying: Bool
    @State private var phase: CGFloat = 0
    
    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw appropriate visualization for noise type
                switch noiseType {
                case .white:
                    drawWhiteNoisePattern(context: context, size: size)
                case .pink:
                    drawPinkNoisePattern(context: context, size: size, phase: phase)
                case .brown:
                    drawBrownNoisePattern(context: context, size: size, phase: phase)
                case .blue:
                    drawBlueNoisePattern(context: context, size: size, phase: phase)
                case .violet:
                    drawVioletNoisePattern(context: context, size: size, phase: phase)
                case .grey:
                    drawGreyNoisePattern(context: context, size: size, phase: phase)
                case .green:
                    drawGreenNoisePattern(context: context, size: size, phase: phase)
                case .black:
                    drawBlackNoisePattern(context: context, size: size)
                }
            }
            .onReceive(timer) { _ in
                if isPlaying {
                    withAnimation {
                        phase += 0.05
                        if phase > 2 * .pi {
                            phase = 0
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Drawing functions for different noise types
    
    private func drawWhiteNoisePattern(context: GraphicsContext, size: CGSize) {
        let width = size.width
        let height = size.height
        let pointSize: CGFloat = 2
        let numPoints = 200
        
        for _ in 0..<numPoints {
            let x = CGFloat.random(in: 0...width)
            let y = CGFloat.random(in: 0...height)
            
            context.fill(
                Path(ellipseIn: CGRect(
                    x: x - pointSize/2,
                    y: y - pointSize/2,
                    width: pointSize,
                    height: pointSize
                )),
                with: .color(.white.opacity(0.6))
            )
        }
    }
    
    private func drawPinkNoisePattern(context: GraphicsContext, size: CGSize, phase: CGFloat) {
        let width = size.width
        let height = size.height
        let midHeight = height / 2
        
        // Pink noise has more energy at lower frequencies
        // Draw a series of diminishing waves
        for i in 1...3 {
            let amplitude = CGFloat(4 - i) * height * 0.12
            let frequency = CGFloat(i) * 3
            
            var path = Path()
            path.move(to: CGPoint(x: 0, y: midHeight))
            
            for x in stride(from: 0, to: width, by: 1) {
                let relativeX = x / width
                let y = midHeight + sin(relativeX * frequency * .pi + phase) * amplitude
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            context.stroke(
                path,
                with: .color(.pink.opacity(Double(4-i) * 0.2)),
                lineWidth: CGFloat(4-i)
            )
        }
    }
    
    private func drawBrownNoisePattern(context: GraphicsContext, size: CGSize, phase: CGFloat) {
        let width = size.width
        let height = size.height
        let midHeight = height / 2
        
        // Brown noise is smoother and has more low frequency components
        var path = Path()
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        var y = midHeight
        for x in stride(from: 0, to: width, by: 2) {
            // Smooth random walk
            y += CGFloat.random(in: -2...2)
            // Constrain to view
            y = max(5, min(height - 5, y))
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Add a subtle sine wave modulation for some movement
        var sinePath = Path()
        sinePath.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let y = midHeight + sin(relativeX * 2 * .pi + phase) * height * 0.15
            sinePath.addLine(to: CGPoint(x: x, y: y))
        }
        
        context.stroke(
            path,
            with: .color(.brown.opacity(0.7)),
            lineWidth: 2
        )
        
        context.stroke(
            sinePath,
            with: .color(.brown.opacity(0.3)),
            lineWidth: 1.5
        )
    }
    
    private func drawBlueNoisePattern(context: GraphicsContext, size: CGSize, phase: CGFloat) {
        let width = size.width
        let height = size.height
        
        // Blue noise has more energy at higher frequencies
        // Draw a series of small, high-frequency waves
        for i in 0..<10 {
            let offsetY = height * (CGFloat(i) / 10) + sin(phase) * height * 0.05
            
            var path = Path()
            path.move(to: CGPoint(x: 0, y: offsetY))
            
            for x in stride(from: 0, to: width, by: 0.5) {
                let relativeX = x / width
                let highFreqComponent = sin(relativeX * 20 * .pi + phase + CGFloat(i))
                let y = offsetY + highFreqComponent * height * 0.02
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            context.stroke(
                path,
                with: .color(.blue.opacity(0.5)),
                lineWidth: 1
            )
        }
    }
    
    private func drawVioletNoisePattern(context: GraphicsContext, size: CGSize, phase: CGFloat) {
        let width = size.width
        let height = size.height
        
        // Violet noise has even more energy at highest frequencies
        // Draw many very high frequency small waves
        for i in 0..<12 {
            let offsetY = height * (CGFloat(i) / 12)
            
            var path = Path()
            path.move(to: CGPoint(x: 0, y: offsetY))
            
            for x in stride(from: 0, to: width, by: 0.5) {
                let relativeX = x / width
                let veryHighFreqComponent = sin(relativeX * 30 * .pi + phase * 1.5 + CGFloat(i))
                let ultraHighFreqComponent = sin(relativeX * 50 * .pi + phase * 2 + CGFloat(i))
                let y = offsetY + (veryHighFreqComponent + ultraHighFreqComponent * 0.5) * height * 0.015
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            context.stroke(
                path,
                with: .color(.purple.opacity(0.4)),
                lineWidth: 0.8
            )
        }
    }
    
    private func drawGreyNoisePattern(context: GraphicsContext, size: CGSize, phase: CGFloat) {
        let width = size.width
        let height = size.height
        let midHeight = height / 2
        
        // Grey noise is psychoacoustically flat
        // Implement as a mix of different wavelengths with equal perceptual power
        
        // Background grid pattern suggesting equal distribution
        for i in stride(from: 0, to: width, by: width/8) {
            let path = Path(CGRect(x: i, y: 0, width: 1, height: height))
            context.fill(path, with: .color(.gray.opacity(0.2)))
        }
        
        for i in stride(from: 0, to: height, by: height/8) {
            let path = Path(CGRect(x: 0, y: i, width: width, height: 1))
            context.fill(path, with: .color(.gray.opacity(0.2)))
        }
        
        // Draw different frequency components
        let frequencies = [2, 5, 10, 20]
        let amplitudes = [0.15, 0.1, 0.07, 0.05]
        
        for (i, frequency) in frequencies.enumerated() {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: midHeight))
            
            for x in stride(from: 0, to: width, by: 1) {
                let relativeX = x / width
                let y = midHeight + sin(relativeX * CGFloat(frequency) * .pi + phase) * height * amplitudes[i]
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            context.stroke(
                path,
                with: .color(.gray.opacity(0.5)),
                lineWidth: 1.5 - CGFloat(i) * 0.3
            )
        }
    }
    
    private func drawGreenNoisePattern(context: GraphicsContext, size: CGSize, phase: CGFloat) {
        let width = size.width
        let height = size.height
        let midHeight = height / 2
        
        // Green noise focuses on mid-frequencies
        // Create a nature-inspired pattern with gentle waves
        
        // Background suggestion of a natural landscape
        let horizon = height * 0.7
        
        // Draw horizon line
        context.stroke(
            Path(CGRect(x: 0, y: horizon, width: width, height: 1)),
            with: .color(.green.opacity(0.2)),
            lineWidth: 1
        )
        
        // Draw gentle hills or waves
        var hillPath = Path()
        hillPath.move(to: CGPoint(x: 0, y: horizon))
        
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let hillHeight = sin(relativeX * 3 * .pi + phase * 0.2) * height * 0.1
            hillPath.addLine(to: CGPoint(x: x, y: horizon - hillHeight))
        }
        hillPath.addLine(to: CGPoint(x: width, y: horizon))
        hillPath.closeSubpath()
        
        context.fill(
            hillPath,
            with: .color(.green.opacity(0.2))
        )
        
        // Add some mid-frequency waves
        var wavePath = Path()
        wavePath.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let midFreqComponent = sin(relativeX * 6 * .pi + phase)
            let y = midHeight + midFreqComponent * height * 0.15
            wavePath.addLine(to: CGPoint(x: x, y: y))
        }
        
        context.stroke(
            wavePath,
            with: .color(.green.opacity(0.6)),
            lineWidth: 2
        )
    }
    
    private func drawBlackNoisePattern(context: GraphicsContext, size: CGSize) {
        let width = size.width
        let height = size.height
        
        // Black noise is mostly silence with occasional sound
        // Draw a mostly empty field with occasional small dots
        
        // Fill with very dark background
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(.black.opacity(0.8))
        )
        
        // Add occasional small bright spots
        for _ in 0..<10 {
            if Bool.random() {
                let x = CGFloat.random(in: 0...width)
                let y = CGFloat.random(in: 0...height)
                let size = CGFloat.random(in: 1...3)
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: size, height: size)),
                    with: .color(.white.opacity(CGFloat.random(in: 0.3...0.7)))
                )
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        NoiseTypeVisualizer(noiseType: AudioManagerImpl.NoiseType.pink, isPlaying: true)
            .frame(width: 200, height: 120)
    }
} 