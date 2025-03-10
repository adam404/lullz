//
//  SpectrumVisualizer.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct SpectrumVisualizer: View {
    @ObservedObject var visualizer: SoundVisualizer
    var barCount: Int = 32
    var color: Color = .accentColor
    
    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width / CGFloat(barCount)
            let levels = visualizer.getBandLevels(bands: barCount)
            
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.7))
                        .frame(width: max(1, barWidth - 2), height: geometry.size.height * CGFloat(levels[index]))
                }
            }
            .frame(height: geometry.size.height, alignment: .bottom)
        }
    }
} 