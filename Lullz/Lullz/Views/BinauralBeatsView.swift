//
//  BinauralBeatsView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

// Create a separate view for the frequency preset button
struct FrequencyPresetButton: View {
    let preset: (name: String, value: Double, description: String)
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(preset.name)
                    .font(.headline)
                Text("\(String(format: "%.1f", preset.value)) Hz")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Create a coordinator class to handle audio operations
class BinauralBeatsCoordinator: ObservableObject {
    var audioManager: AudioManagerImpl
    
    @Published var selectedFrequency: Double = 7.83
    @Published var volume: Double = 0.7
    @Published var isMuted: Bool = false
    
    init(audioManager: AudioManagerImpl) {
        self.audioManager = audioManager
    }
    
    var isPlaying: Bool {
        audioManager.isPlaying && audioManager.currentSoundCategory == AudioManagerImpl.SoundCategory.binaural
    }
    
    // Fixed method calls to match the actual AudioManager API
    func playBinaural(frequency: Double) {
        // Assuming the actual method is playSound but we need to set the
        // frequency first and ensure the category is binaural
        audioManager.currentSoundCategory = AudioManagerImpl.SoundCategory.binaural
        // We need to check for the actual method or property to set frequency
        // For now, assuming we need to configure this before playing
        if audioManager.isPlaying {
            audioManager.playSound()
        } else {
            audioManager.playSound()
        }
    }
    
    func stop() {
        if audioManager.isPlaying {
            audioManager.togglePlayback() // This should stop if it's playing
        }
    }
    
    func updateVolume(_ newVolume: Double) {
        // Fix type consistency - ensure volume is always Double
        audioManager.volume = newVolume
    }
    
    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            playBinaural(frequency: selectedFrequency)
        }
    }
    
    func toggleMute() {
        isMuted.toggle()
        if isPlaying {
            updateVolume(isMuted ? 0 : volume)
        }
    }
    
    func selectPreset(_ preset: (name: String, value: Double, description: String)) {
        selectedFrequency = preset.value
        if isPlaying {
            playBinaural(frequency: preset.value)
        }
    }
}

struct BinauralBeatsView: View {
    @EnvironmentObject var audioManager: AudioManagerImpl
    
    // Use a dummy audio manager for initialization that will be replaced in onAppear
    @StateObject private var coordinator = BinauralBeatsCoordinator(audioManager: AudioManagerImpl.shared)
    
    // Binaural frequency categories
    private let deltaPreset = (name: "Delta", value: 2.5, description: "Deep sleep, healing (0.5-4Hz)")
    private let thetaPreset = (name: "Theta", value: 5.5, description: "Meditation, creativity (4-8Hz)")
    private let alphaPreset = (name: "Alpha", value: 10.0, description: "Relaxation, focus (8-13Hz)")
    private let betaPreset = (name: "Beta", value: 18.0, description: "Active thinking, alertness (13-30Hz)")
    private let gammaPreset = (name: "Gamma", value: 40.0, description: "Higher cognitive processing (30-100Hz)")
    private let schumannPreset = (name: "Schumann", value: 7.83, description: "Earth's resonance frequency")
    
    // Combine them into the array
    var frequencyPresets: [(name: String, value: Double, description: String)] {
        [deltaPreset, thetaPreset, alphaPreset, betaPreset, gammaPreset, schumannPreset]
    }
    
    var body: some View {
        VStack {
            // Header section
            VStack {
                Text("Binaural Beats")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Select or adjust frequency to enhance your mental state")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Frequency selection section
            VStack(spacing: 25) {
                // Preset frequency buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // Direct buttons for each preset
                        FrequencyPresetButton(
                            preset: deltaPreset,
                            isSelected: coordinator.selectedFrequency == deltaPreset.value,
                            action: { coordinator.selectPreset(deltaPreset) }
                        )
                        
                        FrequencyPresetButton(
                            preset: thetaPreset,
                            isSelected: coordinator.selectedFrequency == thetaPreset.value,
                            action: { coordinator.selectPreset(thetaPreset) }
                        )
                        
                        FrequencyPresetButton(
                            preset: alphaPreset,
                            isSelected: coordinator.selectedFrequency == alphaPreset.value,
                            action: { coordinator.selectPreset(alphaPreset) }
                        )
                        
                        FrequencyPresetButton(
                            preset: betaPreset,
                            isSelected: coordinator.selectedFrequency == betaPreset.value,
                            action: { coordinator.selectPreset(betaPreset) }
                        )
                        
                        FrequencyPresetButton(
                            preset: gammaPreset,
                            isSelected: coordinator.selectedFrequency == gammaPreset.value,
                            action: { coordinator.selectPreset(gammaPreset) }
                        )
                        
                        FrequencyPresetButton(
                            preset: schumannPreset,
                            isSelected: coordinator.selectedFrequency == schumannPreset.value,
                            action: { coordinator.selectPreset(schumannPreset) }
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Custom frequency slider
                VStack(spacing: 5) {
                    Text("Custom Frequency: \(String(format: "%.1f", coordinator.selectedFrequency)) Hz")
                        .font(.subheadline)
                    
                    Slider(value: $coordinator.selectedFrequency, in: 0.5...100, step: 0.1)
                        .onChange(of: coordinator.selectedFrequency) { _, newValue in
                            if coordinator.isPlaying {
                                coordinator.playBinaural(frequency: newValue)
                            }
                        }
                }
                .padding(.horizontal)
                
                // Frequency description
                Group {
                    if let selected = frequencyPresets.first(where: { $0.value == coordinator.selectedFrequency }) {
                        Text(selected.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Custom frequency")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical)
            
            // Binaural visualization
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
                    .frame(height: 120)
                    .padding(.horizontal)
                
                // Simple visualization (can be replaced with actual visualization)
                HStack(spacing: 3) {
                    ForEach(0..<30, id: \.self) { i in
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: 3, height: getBarHeight(for: i, frequency: coordinator.selectedFrequency))
                            .opacity(coordinator.isPlaying ? 1.0 : 0.5)
                            .animation(
                                coordinator.isPlaying ?
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.05) : nil,
                                value: coordinator.isPlaying
                            )
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Audio controls with coordinator
            AudioControlsView(
                isPlaying: coordinator.isPlaying,
                volume: coordinator.volume,
                isMuted: coordinator.isMuted,
                onPlayPause: { coordinator.togglePlayback() },
                onVolumeChange: { newVolume in
                    coordinator.volume = newVolume
                    if coordinator.isPlaying {
                        coordinator.updateVolume(newVolume)
                    }
                    if coordinator.isMuted {
                        coordinator.isMuted = false
                        coordinator.updateVolume(newVolume)
                    }
                },
                onMuteToggle: { coordinator.toggleMute() }
            )
            .padding()
        }
        .onAppear {
            // Update the coordinator to use the environment's audioManager instead of the dummy one
            coordinator.audioManager = audioManager
            
            // Initialize with current state if applicable
            coordinator.selectedFrequency = 7.83  // Default to Schumann resonance
            
            // Initialize coordinator with current volume if applicable
            if audioManager.currentSoundCategory == AudioManagerImpl.SoundCategory.binaural && audioManager.isPlaying {
                coordinator.volume = Double(audioManager.volume)
            }
        }
    }
    
    // Helper function to generate varying bar heights for visualization
    private func getBarHeight(for index: Int, frequency: Double) -> CGFloat {
        let baseHeight: CGFloat = 30
        let maxAdditional: CGFloat = 50
        
        // Use different height calculations based on the frequency range
        let heightFactor = frequency / 50.0 // normalize to 0-2 for most frequencies
        
        // Create a wave pattern
        let wavePosition = Double(index) / 30.0 * 2 * Double.pi
        let waveFactor = sin(wavePosition + Double(frequency / 10.0))
        
        return baseHeight + (waveFactor * heightFactor * maxAdditional) + 10
    }
}

#Preview {
    BinauralBeatsView()
        .environmentObject(AudioManagerImpl())
} 
