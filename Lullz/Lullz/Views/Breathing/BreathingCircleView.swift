//
//  BreathingCircleView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct BreathingCircleView: View {
    let phase: BreathPhase
    let progress: Double // 0.0 to 1.0
    var color: Color = .blue
    
    // Animation parameters
    private let minScale: CGFloat = 0.7
    private let maxScale: CGFloat = 1.0
    
    var currentScale: CGFloat {
        switch phase {
        case .inhale:
            return minScale + (maxScale - minScale) * CGFloat(progress)
        case .exhale:
            return maxScale - (maxScale - minScale) * CGFloat(progress)
        case .hold, .holdAfterInhale:
            return maxScale
        case .holdAfterExhale:
            return minScale
        }
    }
    
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 10)
            
            // Pulsing circle
            Circle()
                .scale(currentScale)
                .foregroundColor(color.opacity(0.2))
            
            // Inner circle
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
            
            Text(phase.instruction)
                .font(.headline)
                .foregroundColor(color)
        }
        .padding(20)
    }
} 