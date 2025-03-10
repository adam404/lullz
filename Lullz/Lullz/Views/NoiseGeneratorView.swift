//
//  NoiseGeneratorView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct NoiseGeneratorView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var showingSaveProfile = false
    @State private var profileName = ""
    @State private var showingSleepTimer = false
    @State private var showingHealthDisclaimer = false
    @State private var showingInfo = false
    @State private var selectedNoise: AudioManager.NoiseType
    @State private var isUnmuting = false
    @State private var previousVolume: Float = 0.5
    @State private var showingCategoryPicker = false
    
    // Add this to handle notification from InformationView
    init() {
        // Set default noise type
        _selectedNoise = State(initialValue: .white)
        setupNotificationObserver()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Main visualization area with overlaid controls
                    ZStack {
                        // Background container
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.9))
                            .shadow(radius: 5)
                        
                        // Dynamic visualization
                        DynamicWaveVisualizer(noiseType: audioManager.currentNoiseType)
                            .padding([.horizontal, .vertical], 10)
                        
                        // Overlay controls
                        VStack {
                            Spacer()
                            
                            // Play/pause and volume controls
                            HStack(spacing: 20) {
                                // Mute/unmute button
                                Button(action: {
                                    toggleMute()
                                }) {
                                    Image(systemName: audioManager.volume > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Circle().fill(Color.accentColor.opacity(0.8)))
                                }
                                
                                // Play/pause button
                                Button(action: {
                                    audioManager.togglePlayback()
                                }) {
                                    Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                        .padding(15)
                                        .background(Circle().fill(Color.accentColor))
                                }
                                .accessibilityIdentifier("playPauseButton")
                                .accessibilityLabel(audioManager.isPlaying ? "Pause" : "Play")
                                .shadow(radius: 3)
                                
                                // Volume indicator
                                if audioManager.volume > 0 {
                                    HStack(spacing: 4) {
                                        ForEach(0..<Int(audioManager.volume * 5), id: \.self) { _ in
                                            RoundedRectangle(cornerRadius: 2)
                                                .frame(width: 4, height: 16)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                    .padding(8)
                                    .background(Capsule().fill(Color.black.opacity(0.5)))
                                }
                            }
                            .padding(.bottom, 15)
                        }
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                    
                    // Volume slider
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "speaker.fill")
                                .foregroundColor(.secondary)
                            
                            Slider(value: $audioManager.volume, in: 0...1) { editing in
                                if !editing && isUnmuting {
                                    isUnmuting = false
                                }
                            }
                            .accessibilityIdentifier("volumeControl")
                            .tint(Color.accentColor)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Volume")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Sleep timer indicator
                    if audioManager.sleepTimerActive {
                        ActiveTimerIndicatorView()
                    }
                    
                    // Show different controls based on sound category
                    if audioManager.currentSoundCategory == .noise {
                        // Noise type selection
                        VStack(alignment: .leading) {
                            Text("Select Noise Type")
                                .font(.headline)
                                .padding(.leading)
                            
                            NoiseGridSelectionView(selectedNoise: $selectedNoise)
                                .onChange(of: selectedNoise) { newValue in
                                    // Just update the noise type without toggling playback
                                    audioManager.currentNoiseType = newValue
                                }
                        }
                        
                        // Balance and delay controls
                        VStack(spacing: 20) {
                            Text("Audio Controls")
                                .font(.headline)
                            
                            // Balance slider
                            ControlSliderView(
                                value: $audioManager.balance,
                                range: 0...1,
                                label: "Balance",
                                iconLeading: "l.circle",
                                iconTrailing: "r.circle",
                                accessibilityId: "balanceControl"
                            )
                            
                            // Left delay slider
                            ControlSliderView(
                                value: $audioManager.leftDelay,
                                range: 0...1,
                                label: "Left Ear Delay",
                                textLeading: "0ms",
                                textTrailing: "500ms",
                                accessibilityId: "leftDelayControl"
                            )
                            
                            // Right delay slider
                            ControlSliderView(
                                value: $audioManager.rightDelay,
                                range: 0...1,
                                label: "Right Ear Delay",
                                textLeading: "0ms",
                                textTrailing: "500ms",
                                accessibilityId: "rightDelayControl"
                            )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .padding(.horizontal)
                        
                        // Noise info button
                        Button(action: {
                            showingInfo = true
                        }) {
                            HStack {
                                Image(systemName: "info.circle")
                                Text("About \(selectedNoise.rawValue) Noise")
                            }
                            .padding()
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.2))
                            )
                        }
                        .padding(.vertical)
                    } else {
                        // Binaural beats controls
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Binaural Beats")
                                .font(.headline)
                                .padding(.leading)
                            
                            // Binaural presets
                            VStack(alignment: .leading) {
                                Text("Select Preset")
                                    .font(.subheadline)
                                    .padding(.leading)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(BinauralBeatsGenerator.BinauralPreset.allCases, id: \.self) { preset in
                                            BinauralPresetButton(
                                                preset: preset,
                                                isSelected: audioManager.currentBinauralPreset == preset,
                                                action: {
                                                    audioManager.currentBinauralPreset = preset
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Binaural volume
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Binaural Volume")
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                ControlSliderView(
                                    value: $audioManager.binauralVolume,
                                    range: 0...1,
                                    label: "Volume",
                                    iconLeading: "waveform",
                                    iconTrailing: "waveform.badge.plus",
                                    accessibilityId: "binauralVolumeControl"
                                )
                                .padding(.horizontal)
                            }
                            
                            // Carrier noise toggle
                            VStack(spacing: 15) {
                                Toggle("Add Background Noise", isOn: $audioManager.carrierNoiseEnabled)
                                    .padding(.horizontal)
                                
                                if audioManager.carrierNoiseEnabled {
                                    ControlSliderView(
                                        value: $audioManager.carrierNoiseVolume,
                                        range: 0...1,
                                        label: "Background Noise Volume",
                                        iconLeading: "speaker.fill",
                                        iconTrailing: "speaker.wave.3.fill",
                                        accessibilityId: "carrierNoiseVolumeControl"
                                    )
                                    .padding(.horizontal)
                                    
                                    // Noise type picker for carrier noise
                                    Picker("Background Noise Type", selection: $audioManager.currentNoiseType) {
                                        ForEach(AudioManager.NoiseType.allCases) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(.horizontal)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                            .padding(.horizontal)
                            
                            // Info about binaural beats
                            Button(action: {
                                // Show binaural info (you could create a dedicated view for this)
                                // For now we'll reuse the existing info sheet
                                showingInfo = true
                            }) {
                                HStack {
                                    Image(systemName: "info.circle")
                                    Text("About Binaural Beats")
                                }
                                .padding()
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.2))
                                )
                            }
                            .padding(.vertical)
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Lullz")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingCategoryPicker = true
                    }) {
                        HStack {
                            Text(audioManager.currentSoundCategory.rawValue)
                            Image(systemName: "chevron.down")
                        }
                        .font(.headline)
                    }
                    .confirmationDialog(
                        "Select Sound Type",
                        isPresented: $showingCategoryPicker
                    ) {
                        ForEach(AudioManager.SoundCategory.allCases) { category in
                            Button(category.rawValue) {
                                audioManager.currentSoundCategory = category
                                
                                // If switching to binaural and we're playing noise, 
                                // set a suitable binaural preset
                                if category == .binaural && 
                                   audioManager.currentSoundCategory == .noise {
                                    audioManager.currentBinauralPreset = .relaxation
                                }
                            }
                        }
                    } message: {
                        Text("Choose sound type")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            showingSleepTimer = true
                        }) {
                            Image(systemName: audioManager.sleepTimerActive ? "timer.circle.fill" : "timer.circle")
                        }
                        .accessibilityIdentifier("sleepTimerButton")
                        
                        Button(action: {
                            showingSaveProfile = true
                        }) {
                            Image(systemName: "square.and.arrow.down")
                        }
                        .accessibilityIdentifier("saveProfileButton")
                    }
                }
            }
            .alert("Save Profile", isPresented: $showingSaveProfile) {
                TextField("Profile Name", text: $profileName)
                    .accessibilityIdentifier("profileNameField")
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    saveProfile()
                }
            } message: {
                Text("Enter a name for this sound profile")
            }
            .sheet(isPresented: $showingSleepTimer) {
                SleepTimerView()
            }
            .sheet(isPresented: $showingInfo) {
                NoiseInfoView(noiseType: selectedNoise)
            }
            .alert("Health Disclaimer", isPresented: $showingHealthDisclaimer) {
                Button("I Understand", role: .cancel) {
                    UserDefaults.standard.set(true, forKey: "hasAcknowledgedHealthDisclaimer")
                }
            } message: {
                Text("This app is for relaxation purposes only and is not a substitute for medical advice. If you have any health conditions, please consult a healthcare professional before use.")
            }
            .onAppear {
                // Check if the user has seen the health disclaimer
                let hasAcknowledged = UserDefaults.standard.bool(forKey: "hasAcknowledgedHealthDisclaimer")
                showingHealthDisclaimer = !hasAcknowledged
                
                // Set selected noise to match the current audio manager setting
                selectedNoise = audioManager.currentNoiseType
                
                // Start playing by default but muted
                if !audioManager.isPlaying {
                    // Save current volume setting
                    previousVolume = audioManager.volume
                    
                    // Start muted
                    audioManager.volume = 0
                    
                    // Start playback
                    audioManager.togglePlayback()
                }
            }
        }
    }
    
    private func toggleMute() {
        if audioManager.volume > 0 {
            // Save volume before muting
            previousVolume = audioManager.volume
            
            // Mute gradually
            withAnimation(.easeOut(duration: 0.5)) {
                audioManager.volume = 0
            }
        } else {
            // Unmute and gradually increase volume
            isUnmuting = true
            
            // Start a timer to ramp up volume gradually
            let targetVolume = max(0.5, previousVolume)
            let steps = 10
            let stepDuration = 0.06
            
            for step in 1...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                    audioManager.volume = Float(Double(step) / Double(steps)) * targetVolume
                    
                    // When complete
                    if step == steps {
                        isUnmuting = false
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        guard !profileName.isEmpty else { return }
        
        let profile = NoiseProfile(
            name: profileName,
            noiseType: audioManager.currentNoiseType.rawValue,
            volume: audioManager.volume,
            balance: audioManager.balance,
            leftDelay: audioManager.leftDelay,
            rightDelay: audioManager.rightDelay
        )
        
        let modelContext = SwiftDataModel.shared.modelContainer.mainContext
        modelContext.insert(profile)
        
        // Reset profile name field
        profileName = ""
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("TryNoiseType"),
            object: nil,
            queue: .main) { notification in
                if let noiseType = notification.object as? AudioManager.NoiseType {
                    // Set the noise type and play
                    DispatchQueue.main.async {
                        self.audioManager.currentNoiseType = noiseType
                        self.selectedNoise = noiseType
                        if !self.audioManager.isPlaying {
                            audioManager.togglePlayback()
                        }
                    }
                }
            }
    }
}

// Modern control slider
struct ControlSliderView: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let label: String
    var iconLeading: String? = nil
    var iconTrailing: String? = nil
    var textLeading: String? = nil
    var textTrailing: String? = nil
    var accessibilityId: String? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Leading icon or text
                if let icon = iconLeading {
                    Image(systemName: icon)
                        .foregroundColor(.secondary)
                } else if let text = textLeading {
                    Text(text)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Slider
                Slider(value: $value, in: range)
                    .accessibilityIdentifier(accessibilityId ?? "")
                    .tint(Color.accentColor)
                
                // Trailing icon or text
                if let icon = iconTrailing {
                    Image(systemName: icon)
                        .foregroundColor(.secondary)
                } else if let text = textTrailing {
                    Text(text)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Update the NoiseInfoView to use NoiseTypeVisualizer
struct NoiseInfoView: View {
    let noiseType: AudioManager.NoiseType
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Noise visualization
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.9))
                        
                        NoiseTypeVisualizer(noiseType: noiseType, isPlaying: isAnimating)
                            .padding()
                    }
                    .frame(height: 150)
                    .padding(.bottom)
                    
                    Group {
                        Text(noiseType.rawValue + " Noise")
                            .font(.title)
                            .bold()
                        
                        Text(noiseType.description)
                            .padding(.vertical, 5)
                        
                        Text("Scientific Basis")
                            .font(.headline)
                            .padding(.top)
                        
                        Text(noiseType.scientificBasis)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Noise Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Add a new struct for binaural preset buttons
struct BinauralPresetButton: View {
    let preset: BinauralBeatsGenerator.BinauralPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(preset.rawValue)
                    .fontWeight(isSelected ? .bold : .regular)
                
                // Show the frequency difference
                Text("\(Int(preset.rightFrequency - preset.leftFrequency))Hz")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(minWidth: 120)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NoiseGeneratorView()
        .environmentObject(AudioManager())
} 