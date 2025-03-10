//
//  WaveformVisualizer.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct WaveformVisualizer: View {
    @ObservedObject var visualizer: SoundVisualizer
    var color: Color = .accentColor
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !visualizer.waveformPoints.isEmpty else { return }
                
                let midHeight = geometry.size.height / 2
                let heightScale = geometry.size.height / 4 // Scale to use half the view height
                
                // Move to the first point
                let firstPoint = visualizer.waveformPoints[0]
                let x = firstPoint.x * geometry.size.width
                let y = midHeight + firstPoint.y * heightScale
                path.move(to: CGPoint(x: x, y: y))
                
                // Draw lines to subsequent points
                for i in 1..<visualizer.waveformPoints.count {
                    let point = visualizer.waveformPoints[i]
                    let x = point.x * geometry.size.width
                    let y = midHeight + point.y * heightScale
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, lineWidth: 2)
        }
    }
} 