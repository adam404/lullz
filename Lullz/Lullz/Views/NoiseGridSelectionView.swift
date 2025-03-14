//
//  NoiseGridSelectionView.swift
//  Lullz
//
//  Created by AI Assistant on 3/9/25.
//

import SwiftUI

struct NoiseGridSelectionView: View {
    @EnvironmentObject var audioManager: AudioManagerImpl
    @Binding var selectedNoise: AudioManagerImpl.NoiseType
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(AudioManagerImpl.NoiseType.allCases) { noiseType in
                NoiseTypeCard(
                    noiseType: noiseType,
                    isSelected: selectedNoise == noiseType,
                    isPlaying: audioManager.isPlaying && audioManager.currentNoiseType == noiseType,
                    onSelect: { 
                        // Just update the selected noise type
                        // The parent view will handle updating the audio manager
                        selectedNoise = noiseType
                    }
                )
            }
        }
        .padding()
    }
}

struct NoiseTypeCard: View {
    let noiseType: AudioManagerImpl.NoiseType
    let isSelected: Bool
    let isPlaying: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(height: 130)
                        .shadow(radius: isSelected ? 5 : 2)
                    
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.8))
                                .padding(.horizontal, 5)
                            
                            // Use the new NoiseTypeVisualizer
                            NoiseTypeVisualizer(noiseType: noiseType, isPlaying: isPlaying || isSelected)
                                .frame(height: 60)
                                .padding([.leading, .trailing], 10)
                        }
                        .frame(height: 60)
                        .padding([.leading, .trailing], 5)
                        .padding(.top, 5)
                        
                        Text(noiseType.rawValue)
                            .font(.headline)
                            .foregroundColor(isSelected ? .white : .primary)
                            .padding(.top, 5)
                    }
                }
                
                Text(shortDescription(for: noiseType))
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(height: 40)
                    .lineLimit(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func shortDescription(for noiseType: AudioManagerImpl.NoiseType) -> String {
        switch noiseType {
        case .white:
            return "Equal across all frequencies, masks sounds"
        case .pink:
            return "Natural-sounding, decreases at higher frequencies"
        case .brown:
            return "Deep, rich sound like rainfall or ocean"
        case .blue:
            return "Emphasis on higher frequencies, helps focus"
        case .violet:
            return "Strongest high frequencies, can help with tinnitus"
        case .grey:
            return "Engineered to sound equally loud to human ears"
        case .green:
            return "Midrange focus, resembles natural environments"
        case .black:
            return "Minimal sound for deep focus and meditation"
        }
    }
}

#Preview {
    NoiseGridSelectionView(selectedNoise: Binding.constant(AudioManagerImpl.NoiseType.white))
        .environmentObject(AudioManagerImpl())
} 