//
//  CircularVisualizer.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct CircularVisualizer: View {
    @ObservedObject var visualizer: SoundVisualizer
    var barCount: Int = 180
    var color: Color = .accentColor
    var innerRadiusFraction: CGFloat = 0.4
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let minDimension = min(geometry.size.width, geometry.size.height)
            let outerRadius = minDimension / 2
            let innerRadius = outerRadius * innerRadiusFraction
            
            // Get spectrum data
            let levels = visualizer.getBandLevels(bands: barCount)
            
            ZStack {
                // Draw circular bars
                ForEach(0..<barCount, id: \.self) { index in
                    let angle = CGFloat(index) * (2 * .pi / CGFloat(barCount))
                    let magnitude = CGFloat(levels[index % levels.count]) * (outerRadius - innerRadius) + innerRadius
                    
                    Path { path in
                        // Inner point
                        let innerX = center.x + innerRadius * cos(angle)
                        let innerY = center.y + innerRadius * sin(angle)
                        
                        // Outer point
                        let outerX = center.x + magnitude * cos(angle)
                        let outerY = center.y + magnitude * sin(angle)
                        
                        path.move(to: CGPoint(x: innerX, y: innerY))
                        path.addLine(to: CGPoint(x: outerX, y: outerY))
                    }
                    .stroke(color.opacity(0.6), lineWidth: 2)
                }
                
                // Inner circle
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: innerRadius * 2, height: innerRadius * 2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
} 