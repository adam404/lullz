//
//  BinauralBeatsView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct BinauralBeatsView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var showingInfo = false
    @State private var selectedPreset: BinauralBeatsGenerator.BinauralPreset
    @State private var showingSleepTimer = false
    @State private var animationPhase: Double = 0
    @State private var isAnimating = false
    @State private var customFrequency: Double = 10.0
    @State private var showEffectsPanel = false
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    init() {
        _selectedPreset = State(initialValue: BinauralBeatsGenerator.BinauralPreset.relaxation)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Top visualization and controls section (above the fold)
                    VStack(spacing: 15) {
                        // Visualization
                        binauralVisualization
                            .frame(height: 180)
                            .padding(.horizontal)
                        
                        // Play controls (moved up)
                        playControls
                    }
                    
                    // Quick audio options
                    VStack(spacing: 10) {
                        // Volume control
                        HStack {
                            Image(systemName: "speaker.fill")
                                .foregroundColor(.secondary)
                            Slider(value: $audioManager.binauralVolume, in: 0...1) { editing in
                                if !editing && audioManager.isPlaying && audioManager.currentSoundCategory == .binaural {
                                    audioManager.stopSound()
                                    audioManager.playSound()
                                }
                            }
                            .accentColor(.accentColor)
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.secondary)
                            
                            // Sleep timer button
                            Button(action: {
                                showingSleepTimer = true
                            }) {
                                Image(systemName: audioManager.sleepTimerActive ? "timer.circle.fill" : "timer.circle")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.horizontal)
                        
                        // Remove background noise toggle and related UI
                    }
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary.opacity(0.05))
                    )
                    .padding(.horizontal)
                    
                    // Preset selector
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Binaural Beat Presets")
                            .font(.headline)
                            .padding(.leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(BinauralBeatsGenerator.BinauralPreset.allCases) { preset in
                                    Button {
                                        withAnimation {
                                            selectedPreset = preset
                                            audioManager.currentBinauralPreset = preset
                                            if audioManager.isPlaying && audioManager.currentSoundCategory == .binaural {
                                                audioManager.stopSound()
                                                audioManager.playSound()
                                            }
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(preset.rawValue)
                                                .font(.headline)
                                                .foregroundColor(preset == selectedPreset ? .primary : .secondary)
                                            
                                            Text("\(String(format: "%.1f", abs(preset.rightFrequency - preset.leftFrequency)))Hz")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 130, height: 70, alignment: .leading)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(preset == selectedPreset 
                                                    ? Color.accentColor.opacity(0.2) 
                                                    : Color.secondary.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(
                                                            preset == selectedPreset 
                                                                ? Color.accentColor 
                                                                : Color.clear,
                                                            lineWidth: 2
                                                        )
                                                )
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Current preset info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedPreset.rawValue)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(getFrequencyDescription())
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                showingInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        
                        Text(selectedPreset.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 6)
                        
                        // Brainwave indicator
                        brainwaveIndicator
                            .frame(height: 30)
                            .padding(.vertical, 6)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .padding(.horizontal)
                    
                    // Advanced options
                    VStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                showEffectsPanel.toggle()
                            }
                        }) {
                            HStack {
                                Text("Advanced Options")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: showEffectsPanel ? "chevron.up" : "chevron.down")
                                    .font(.body)
                                    .foregroundColor(.accentColor)
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                        
                        if showEffectsPanel {
                            VStack(spacing: 20) {
                                // Replace carrier noise details with advanced visualization options
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Stereo Balance")
                                        .font(.headline)
                                    
                                    HStack {
                                        Text("L")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Slider(value: .constant(0.5)) // Placeholder for future balance control
                                        Text("R")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.top, 10)
                            .padding(.horizontal)
                            .padding(.bottom, 15)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .padding(.horizontal)
                    
                    // Safety disclaimer
                    if selectedPreset == .hemisync {
                        Text("Hemi-Sync® is designed to help synchronize brain hemispheres. For best results, use headphones and sit in a comfortable position with eyes closed.")
                            .font(.callout)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.yellow.opacity(0.2))
                            )
                            .padding(.horizontal)
                    }
                    
                    // Disclaimer
                    Text("⚠️ Binaural beats require headphones and should not be used while operating machinery or driving.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("Binaural Beats")
            .sheet(isPresented: $showingInfo) {
                BinauralInfoView(preset: selectedPreset)
            }
            .sheet(isPresented: $showingSleepTimer) {
                SleepTimerView()
            }
            .onReceive(timer) { _ in
                if audioManager.isPlaying && audioManager.currentSoundCategory == .binaural {
                    animationPhase += 0.1
                    isAnimating = true
                } else {
                    isAnimating = false
                }
            }
            .onAppear {
                isAnimating = audioManager.isPlaying && audioManager.currentSoundCategory == .binaural
                selectedPreset = audioManager.currentBinauralPreset
            }
        }
        // Set preferred color scheme to none to let system decide
        .preferredColorScheme(nil)
    }
    
    // MARK: - UI Components
      
    private var binauralVisualization: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - removed gradient and replaced with solid color
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                
                // Left channel wave
                waveform(offset: 0, color: .blue.opacity(0.6), speed: CGFloat(getFrequencyFor(position: .left)) / 100)
                    .opacity(isAnimating ? 1 : 0.3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask(
                        Rectangle()
                            .frame(width: geometry.size.width / 2, height: geometry.size.height)
                            .offset(x: -(geometry.size.width / 4))
                    )
                
                // Right channel wave
                waveform(offset: .pi, color: .red.opacity(0.6), speed: CGFloat(getFrequencyFor(position: .right)) / 100)
                    .opacity(isAnimating ? 1 : 0.3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask(
                        Rectangle()
                            .frame(width: geometry.size.width / 2, height: geometry.size.height)
                            .offset(x: geometry.size.width / 4)
                    )
                
                // Center indicator
                if isAnimating {
                    Rectangle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 1, height: 60)
                }
                
                // Text labels
                HStack {
                    VStack {
                        Spacer()
                        Text("\(String(format: "%.1f", getFrequencyFor(position: .left)))Hz")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(6)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Spacer()
                        Text("\(String(format: "%.1f", getFrequencyFor(position: .right)))Hz")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(6)
                            .background(Color.red.opacity(0.3))
                            .cornerRadius(4)
                    }
                }
                .padding()
            }
        }
    }
    
    private var brainwaveIndicator: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                let beatFrequency = abs(selectedPreset.rightFrequency - selectedPreset.leftFrequency)
                
                // Delta indicator
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(beatFrequency <= 4.0 ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 30, height: 8)
                    Text("Delta")
                        .font(.caption)
                        .foregroundColor(beatFrequency <= 4.0 ? .primary : .secondary)
                }
                .frame(width: 45)
                
                // Theta indicator
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(beatFrequency > 4.0 && beatFrequency <= 8.0 ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 30, height: 8)
                    Text("Theta")
                        .font(.caption)
                        .foregroundColor(beatFrequency > 4.0 && beatFrequency <= 8.0 ? .primary : .secondary)
                }
                .frame(width: 45)
                
                // Alpha indicator
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(beatFrequency > 8.0 && beatFrequency <= 13.0 ? Color.yellow : Color.gray.opacity(0.3))
                        .frame(width: 30, height: 8)
                    Text("Alpha")
                        .font(.caption)
                        .foregroundColor(beatFrequency > 8.0 && beatFrequency <= 13.0 ? .primary : .secondary)
                }
                .frame(width: 45)
                
                // Beta indicator
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(beatFrequency > 13.0 && beatFrequency <= 30.0 ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 30, height: 8)
                    Text("Beta")
                        .font(.caption)
                        .foregroundColor(beatFrequency > 13.0 && beatFrequency <= 30.0 ? .primary : .secondary)
                }
                .frame(width: 45)
                
                // Gamma indicator
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(beatFrequency > 30.0 ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: 30, height: 8)
                    Text("Gamma")
                        .font(.caption)
                        .foregroundColor(beatFrequency > 30.0 ? .primary : .secondary)
                }
                .frame(width: 45)
            }
            .padding(.horizontal, 10)
        }
    }
    
    private var playControls: some View {
        Button {
            audioManager.currentSoundCategory = .binaural
            audioManager.currentBinauralPreset = selectedPreset
            audioManager.togglePlayback()
        } label: {
            HStack {
                Image(systemName: audioManager.isPlaying && audioManager.currentSoundCategory == .binaural ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 40))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white, Color.accentColor)
                
                Text(audioManager.isPlaying && audioManager.currentSoundCategory == .binaural ? "Pause" : "Play")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.accentColor.opacity(0.9))
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 4, x: 0, y: 2)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal)
        .onAppear {
            // Update selected preset to match what's in the audio manager
            // when returning to this view
            selectedPreset = audioManager.currentBinauralPreset
        }
    }
    
    // MARK: - Helper Methods
    
    private func waveform(offset: CGFloat, color: Color, speed: CGFloat) -> some View {
        let amplitude: CGFloat = isAnimating ? 40 : 20
        
        return Canvas { context, size in
            // Safety check for valid dimensions
            guard size.width > 0, size.height > 0, size.width.isFinite, size.height.isFinite else { return }
            
            context.opacity = 0.8
            
            var path = Path()
            let width = size.width
            let height = size.height
            let midHeight = height / 2
            
            path.move(to: CGPoint(x: 0, y: midHeight))
            
            for x in stride(from: 0, through: width, by: 1) {
                let relativeX = x / width
                let sineValue = sin(relativeX * .pi * 10 + offset + animationPhase * speed)
                var y = midHeight + amplitude * sineValue
                
                // Ensure y is a valid, finite number
                if !y.isFinite {
                    y = midHeight
                }
                
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            context.stroke(path, with: .color(color), lineWidth: 3)
        }
    }
    
    private enum WavePosition {
        case left, right
    }
    
    private func getFrequencyFor(position: WavePosition) -> Float {
        switch position {
        case .left:
            return selectedPreset.leftFrequency
        case .right:
            return selectedPreset.rightFrequency
        }
    }
    
    private func getFrequencyDescription() -> String {
        let beatFrequency = abs(selectedPreset.rightFrequency - selectedPreset.leftFrequency)
        let stateDescription: String
        
        if beatFrequency <= 4.0 {
            stateDescription = "Delta waves"
        } else if beatFrequency <= 8.0 {
            stateDescription = "Theta waves"
        } else if beatFrequency <= 13.0 {
            stateDescription = "Alpha waves"
        } else if beatFrequency <= 30.0 {
            stateDescription = "Beta waves"
        } else {
            stateDescription = "Gamma waves"
        }
        
        return "L: \(String(format: "%.1f", selectedPreset.leftFrequency))Hz, R: \(String(format: "%.1f", selectedPreset.rightFrequency))Hz • \(String(format: "%.1f", beatFrequency))Hz \(stateDescription)"
    }
}

struct BinauralInfoView: View {
    let preset: BinauralBeatsGenerator.BinauralPreset
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Preset info
                    Group {
                        Text(preset.rawValue)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(preset.description)
                            .font(.body)
                        
                        Divider()
                        
                        Text("How It Works")
                            .font(.headline)
                        
                        Text("This preset uses a carrier tone of \(String(format: "%.1f", preset.leftFrequency))Hz in the left ear and \(String(format: "%.1f", preset.rightFrequency))Hz in the right ear, creating a binaural beat of \(String(format: "%.1f", abs(preset.rightFrequency - preset.leftFrequency)))Hz.")
                        
                        Text("Scientific Basis")
                            .font(.headline)
                        
                        Text(preset.scientificBasis)
                    }
                    .padding(.horizontal)
                    
                    // Brainwave info if it's Hemi-Sync
                    if preset == .hemisync {
                        Group {
                            Divider()
                            
                            Text("About Hemi-Sync®")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Text("Hemi-Sync® (Hemispheric Synchronization) is a patented sound technology developed by Robert Monroe and the Monroe Institute. It uses binaural beats to create specific brainwave states and synchronize the left and right hemispheres of the brain.\n\nThe technology is designed to produce a focused, whole-brain state known as hemispheric synchronization, where both hemispheres work together in a coherent, efficient manner.\n\nNote: Our implementation is inspired by the general principles of hemispheric synchronization but is not affiliated with or endorsed by the Monroe Institute.")
                                .padding(.horizontal)
                            
                            Text("Best Practices")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(["Use stereo headphones for best results", "Sit or lie in a comfortable position", "Close your eyes and breathe deeply", "Start with short sessions (15-20 minutes)", "Avoid operating machinery or driving"], id: \.self) { practice in
                                    HStack(alignment: .top) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text(practice)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Disclaimer
                    Group {
                        Divider()
                        
                        Text("Disclaimer")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text("Binaural beats are provided for entertainment purposes only. The effects of binaural beats vary from person to person. Lullz is not a medical device and makes no medical claims about the effects of binaural beats.\n\nIndividuals with a history of seizures, epilepsy, or neurological disorders should consult a healthcare professional before using binaural beats.\n\nLullz is not affiliated with or endorsed by the Monroe Institute or Hemi-Sync®, which are registered trademarks of Interstate Industries, Inc.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("About \(preset.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BinauralBeatsView_Previews: PreviewProvider {
    static var previews: some View {
        BinauralBeatsView()
            .environmentObject(AudioManager())
    }
} 
