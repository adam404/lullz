//
//  BinauralBeatsView.swift
//  Lullz
//
//  Created by Adam Scott
//

import SwiftUI
import Combine

struct BinauralBeatsFeatureView: View {
    // Use StateObject for view model instantiation in the view
    @StateObject private var viewModel: BinauralBeatsViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    // Dependency injection through init
    init(audioManager: AudioManagerImpl? = nil) {
        // Use the provided audio manager or the shared instance
        let manager = audioManager ?? AudioManagerImpl.shared
        // Use _StateObject for initialization in init
        _viewModel = StateObject(wrappedValue: BinauralBeatsViewModel(audioManager: manager))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            // Main content
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    headerView
                    
                    // Brain state indicator
                    brainStateIndicator
                    
                    // Frequency display
                    frequencyDisplay
                    
                    // Frequency control
                    frequencyControl
                    
                    // Preset selection
                    presetSelector
                    
                    // Advanced options toggle
                    advancedOptionsToggle
                    
                    // Advanced options
                    if viewModel.isAdvancedOptionsVisible {
                        advancedOptions
                    }
                    
                    // Play/Pause button
                    playButton
                    
                    // Additional controls
                    additionalControls
                    
                    // Timer indicator (if active)
                    timerIndicator
                    
                    // Information section
                    infoButton
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $viewModel.isInfoSheetPresented) {
            infoSheet
        }
        .sheet(isPresented: $viewModel.isSaveProfileSheetPresented) {
            saveProfileSheet
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.3),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var headerView: some View {
        Text("Binaural Beats")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.top, 20)
    }
    
    private var brainStateIndicator: some View {
        VStack(spacing: 10) {
            Text("Current Brain State")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            Text(viewModel.getBrainState())
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15))
                .cornerRadius(15)
        }
    }
    
    private var frequencyDisplay: some View {
        VStack(spacing: 5) {
            Text("\(String(format: "%.2f", viewModel.selectedFrequency)) Hz")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Binaural Beat Frequency")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 5)
    }
    
    private var frequencyControl: some View {
        VStack(spacing: 10) {
            // Slider for frequency control
            Slider(
                value: Binding(
                    get: { viewModel.selectedFrequency },
                    set: { viewModel.selectFrequency($0) }
                ),
                in: 0.5...40,
                step: 0.1
            )
            .accentColor(.white)
            
            // Frequency range labels
            HStack {
                Text("0.5 Hz")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("40 Hz")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
    }
    
    private var presetSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Presets")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.presets) { preset in
                        presetButton(preset)
                    }
                }
                .padding(.horizontal, 5)
            }
        }
    }
    
    private func presetButton(_ preset: BinauralPreset) -> some View {
        Button {
            viewModel.selectPreset(preset)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(preset.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(String(format: "%.2f", preset.frequency)) Hz")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(width: 150, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(viewModel.selectedPreset?.id == preset.id ? 
                          Color.white.opacity(0.3) : Color.white.opacity(0.15))
            )
        }
    }
    
    private var advancedOptionsToggle: some View {
        Button {
            withAnimation {
                viewModel.isAdvancedOptionsVisible.toggle()
            }
        } label: {
            HStack {
                Text(viewModel.isAdvancedOptionsVisible ? "Hide Advanced Options" : "Show Advanced Options")
                    .font(.headline)
                
                Image(systemName: viewModel.isAdvancedOptionsVisible ? "chevron.up" : "chevron.down")
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.15))
            .cornerRadius(10)
        }
    }
    
    private var advancedOptions: some View {
        VStack(spacing: 15) {
            // Base frequency control
            VStack(spacing: 5) {
                HStack {
                    Text("Base Frequency")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.baseFrequency)) Hz")
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Slider(
                    value: Binding(
                        get: { viewModel.baseFrequency },
                        set: { viewModel.updateBaseFrequency($0) }
                    ),
                    in: 100...400,
                    step: 1
                )
                .accentColor(.white)
            }
            
            // Volume control
            VStack(spacing: 5) {
                HStack {
                    Text("Volume")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.volume * 100))%")
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Slider(
                    value: Binding(
                        get: { viewModel.volume },
                        set: { viewModel.updateVolume($0) }
                    ),
                    in: 0...1,
                    step: 0.01
                )
                .accentColor(.white)
            }
            
            // Mute toggle
            Button {
                viewModel.toggleMute()
            } label: {
                HStack {
                    Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 20))
                    
                    Text(viewModel.isMuted ? "Unmute" : "Mute")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(viewModel.isMuted ? 0.25 : 0.15))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .transition(.opacity)
    }
    
    private var playButton: some View {
        Button {
            viewModel.togglePlayback()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 20)
    }
    
    private var additionalControls: some View {
        VStack(spacing: 15) {
            // Sleep timer button
            Button {
                if viewModel.isTimerActive {
                    viewModel.cancelSleepTimer()
                } else {
                    viewModel.startSleepTimer()
                }
            } label: {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 20))
                    
                    Text(viewModel.isTimerActive ? "Cancel Timer" : "Sleep Timer")
                        .font(.headline)
                }
                .foregroundColor(viewModel.isTimerActive ? .orange : .white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
            }
            
            // Save profile button
            Button {
                viewModel.isSaveProfileSheetPresented = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 20))
                    
                    Text("Save Profile")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
            }
        }
    }
    
    private var timerIndicator: some View {
        Group {
            if viewModel.isTimerActive {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    
                    Text("Sleep in \(viewModel.formatTime(viewModel.remainingTime))")
                        .foregroundColor(.orange)
                }
                .padding(.bottom, 10)
            }
        }
    }
    
    private var infoButton: some View {
        Button {
            viewModel.isInfoSheetPresented = true
        } label: {
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                
                Text("About Binaural Beats")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.15))
            .cornerRadius(10)
        }
    }
    
    private var infoSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("About Binaural Beats")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("When two slightly different frequencies are presented separately to each ear, the brain detects the phase difference between them, creating an auditory illusion known as a binaural beat. This beat matches the difference between the two frequencies.")
                    .font(.body)
                
                Text("Brain States & Frequencies")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 15) {
                    frequencyInfoRow("Delta (0.5-4 Hz)", "Deep sleep, healing, unconscious mind")
                    frequencyInfoRow("Theta (4-8 Hz)", "Meditation, REM sleep, creativity")
                    frequencyInfoRow("Alpha (8-12 Hz)", "Relaxation, calmness, present moment awareness")
                    frequencyInfoRow("SMR (12-15 Hz)", "Mental alertness, physical relaxation")
                    frequencyInfoRow("Beta (15-30 Hz)", "Active thinking, focus, alertness")
                    frequencyInfoRow("Gamma (30-100 Hz)", "Higher mental activity, insight")
                }
                
                Text("Best Practices")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 10)
                
                Text("• Use stereo headphones for best results\n• Start with short sessions (15-30 minutes)\n• Choose frequencies based on your desired mental state\n• Find a quiet, comfortable environment\n• Combine with meditation or relaxation techniques")
                    .font(.body)
                
                Text("Research & Limitations")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 10)
                
                Text("While many users report benefits from binaural beats, scientific research shows mixed results. Individual responses may vary. This app is for entertainment purposes and is not intended to diagnose, treat, cure, or prevent any disease.")
                    .font(.body)
                
                Button {
                    viewModel.isInfoSheetPresented = false
                } label: {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }
    
    private func frequencyInfoRow(_ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var saveProfileSheet: some View {
        VStack(spacing: 20) {
            Text("Save Binaural Beat Profile")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Profile Name", text: $viewModel.profileName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button {
                viewModel.saveProfile()
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 5)
                    }
                    
                    Text(viewModel.isSaving ? "Saving..." : "Save")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(viewModel.profileName.isEmpty || viewModel.isSaving)
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    // Preview with mock audio manager
    BinauralBeatsFeatureView()
} 