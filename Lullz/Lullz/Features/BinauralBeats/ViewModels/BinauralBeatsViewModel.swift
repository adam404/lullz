//
//  BinauralBeatsViewModel.swift
//  Lullz
//
//  Created by Adam Scott
//

import SwiftUI
import Combine

// Model: BinauralPreset
struct BinauralPreset: Identifiable {
    let id = UUID()
    let name: String
    let frequency: Double
    let description: String
    let associatedState: String
    
    static let presets: [BinauralPreset] = [
        BinauralPreset(
            name: "Schumann Resonance",
            frequency: 7.83,
            description: "Earth's natural frequency. Promotes grounding, stability, and resonance with nature.",
            associatedState: "Relaxed alertness"
        ),
        BinauralPreset(
            name: "Delta",
            frequency: 2.5,
            description: "Deep sleep waves. Helps with healing, regeneration, and deep unconscious processing.",
            associatedState: "Deep sleep"
        ),
        BinauralPreset(
            name: "Theta",
            frequency: 5.5,
            description: "Dream state and deep meditation. Enhances creativity, intuition, and memory.",
            associatedState: "Meditation & REM"
        ),
        BinauralPreset(
            name: "Alpha",
            frequency: 10.0,
            description: "Relaxed alertness. Reduces stress, promotes calmness with mental clarity.",
            associatedState: "Relaxed alertness"
        ),
        BinauralPreset(
            name: "SMR",
            frequency: 14.0,
            description: "Sensorimotor rhythm. Improves focus, attention, and cognitive processing.",
            associatedState: "Focused attention"
        ),
        BinauralPreset(
            name: "Beta",
            frequency: 18.0,
            description: "Active thinking. Enhances logical thinking, problem-solving, and active focus.",
            associatedState: "Active thinking"
        ),
        BinauralPreset(
            name: "Gamma",
            frequency: 40.0,
            description: "Peak performance. Associated with higher cognitive processing and learning.",
            associatedState: "Peak performance"
        )
    ]
}

// ViewModel: BinauralBeatsViewModel
class BinauralBeatsViewModel: ObservableObject {
    // Audio manager reference
    private let audioManager: AudioManagerImpl
    
    // Published properties for view binding
    @Published var selectedFrequency: Double = 7.83 {
        didSet {
            if oldValue != selectedFrequency {
                updateBinauralBeat()
                selectedPreset = findMatchingPreset()
            }
        }
    }
    @Published var baseFrequency: Double = 200.0
    @Published var volume: Double = 0.7
    @Published var isMuted: Bool = false
    @Published var isPlaying: Bool = false
    @Published var selectedPreset: BinauralPreset?
    @Published var isAdvancedOptionsVisible: Bool = false
    @Published var isInfoSheetPresented: Bool = false
    @Published var isSaveProfileSheetPresented: Bool = false
    @Published var profileName: String = ""
    @Published var isSaving: Bool = false
    
    // Timer-related properties
    @Published var sleepTimerMinutes: Int = 30
    @Published var isTimerActive: Bool = false
    @Published var remainingTime: TimeInterval = 0
    
    // Presets
    let presets = BinauralPreset.presets
    
    // Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    init(audioManager: AudioManagerImpl) {
        self.audioManager = audioManager
        self.selectedPreset = presets.first
        self.selectedFrequency = presets.first?.frequency ?? 7.83
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Monitor audio manager state
        audioManager.$isPlaying
            .receive(on: RunLoop.main)
            .sink { [weak self] (isPlaying: Bool) in
                guard let self = self else { return }
                // Only update if the sound category is binaural
                if self.audioManager.currentSoundCategory == AudioManagerImpl.SoundCategory.binaural {
                    self.isPlaying = isPlaying
                }
            }
            .store(in: &cancellables)
        
        audioManager.$volume
            .receive(on: RunLoop.main)
            .sink { [weak self] volume in
                self?.volume = Double(volume)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func togglePlayback() {
        if isPlaying {
            stopBinaural()
        } else {
            playBinaural()
        }
    }
    
    func selectFrequency(_ frequency: Double) {
        selectedFrequency = frequency
        
        // Try to find a matching preset
        selectedPreset = presets.first { preset in
            abs(preset.frequency - frequency) < 0.1 // Tolerance for floating point comparison
        }
        
        if isPlaying {
            // Update the playing binaural beat
            configureBinauralParameters()
        }
    }
    
    func selectPreset(_ preset: BinauralPreset) {
        selectedPreset = preset
        selectedFrequency = preset.frequency
        
        if isPlaying {
            // Update the playing binaural beat
            configureBinauralParameters()
        }
    }
    
    func updateVolume(_ newVolume: Double) {
        volume = newVolume
        audioManager.volume = newVolume
    }
    
    func updateBaseFrequency(_ newBaseFrequency: Double) {
        baseFrequency = newBaseFrequency
        
        if isPlaying {
            configureBinauralParameters()
        }
    }
    
    func toggleMute() {
        isMuted.toggle()
        
        if isMuted {
            audioManager.volume = 0
        } else {
            audioManager.volume = volume
        }
    }
    
    func startSleepTimer() {
        isTimerActive = true
        remainingTime = TimeInterval(sleepTimerMinutes * 60)
        
        // Cancel any existing timer
        timer?.invalidate()
        
        // Create a new timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                // Time's up, stop playback
                self.stopBinaural()
                self.isTimerActive = false
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }
    
    func cancelSleepTimer() {
        isTimerActive = false
        timer?.invalidate()
        timer = nil
    }
    
    func saveProfile() {
        isSaving = true
        
        // Logic to save the current binaural beat profile to SwiftData or other storage
        
        // Reset state after saving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSaving = false
            self.isSaveProfileSheetPresented = false
            self.profileName = ""
        }
    }
    
    // MARK: - Private Methods
    
    private func playBinaural() {
        // Set the sound category to binaural
        audioManager.currentSoundCategory = AudioManagerImpl.SoundCategory.binaural
        
        // Configure binaural parameters
        configureBinauralParameters()
        
        // Play the binaural beat
        audioManager.playSound()
        isPlaying = true
    }
    
    private func stopBinaural() {
        audioManager.stopSound()
        isPlaying = false
    }
    
    private func configureBinauralParameters() {
        // Instead of calling a specific method, set properties directly to configure
        // the audio engine for binaural beats
        audioManager.currentSoundCategory = AudioManagerImpl.SoundCategory.binaural
        
        // The currentBinauralPreset might need to be configured based on selected frequencies
        // For now, we'll use the playSound method which should handle the binaural settings
        if isPlaying {
            audioManager.playSound()
        }
        
        // Apply volume settings
        audioManager.volume = isMuted ? 0 : volume
    }
    
    // Get current brain state based on frequency
    func getBrainState() -> String {
        if let preset = selectedPreset {
            return preset.associatedState
        }
        
        // If no preset matches, determine the brain state based on frequency ranges
        switch selectedFrequency {
        case 0.5...4:
            return "Deep sleep"
        case 4...8:
            return "Meditation & REM"
        case 8...12:
            return "Relaxed alertness"
        case 12...15:
            return "Focused attention"
        case 15...30:
            return "Active thinking"
        case 30...100:
            return "Peak performance"
        default:
            return "Custom frequency"
        }
    }
    
    // Format time for display
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func updateBinauralBeat() {
        // Implementation of updateBinauralBeat method
    }
    
    private func findMatchingPreset() -> BinauralPreset? {
        // Implementation of findMatchingPreset method
        return nil
    }
} 