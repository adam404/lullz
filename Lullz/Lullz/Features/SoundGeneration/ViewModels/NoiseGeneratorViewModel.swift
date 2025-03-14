//
//  NoiseGeneratorViewModel.swift
//  Lullz
//
//  Created by Adam Scott
//

import SwiftUI
import Combine

enum NoiseType: String, CaseIterable, Identifiable {
    case white = "White"
    case pink = "Pink"
    case brown = "Brown"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .white:
            return "Full spectrum noise, equal energy across all frequencies. Best for masking variable sounds."
        case .pink:
            return "Lower energy in higher frequencies. Sounds more natural and is good for concentration."
        case .brown:
            return "Even lower energy in higher frequencies. Deep, soothing sound like ocean waves."
        }
    }
    
    var icon: String {
        switch self {
        case .white: return "waveform"
        case .pink: return "waveform.path"
        case .brown: return "waveform.badge.minus"
        }
    }
}

class NoiseGeneratorViewModel: ObservableObject {
    // MARK: - Properties
    private let audioManager: AudioManagerImpl
    
    // MARK: - Published properties
    @Published var selectedNoiseType: NoiseType = .white
    @Published var isMuted: Bool = false
    @Published var volume: Double = 0.5
    @Published var balance: Double = 0.0  // -1.0 (left) to 1.0 (right)
    @Published var leftEarDelay: Double = 0.0
    @Published var rightEarDelay: Double = 0.0
    @Published var timerDuration: TimeInterval = 0
    @Published var sleepTimerMinutes: Int = 30
    @Published var isTimerActive: Bool = false
    @Published var remainingTime: TimeInterval = 0
    
    // UI state
    @Published var isPlaying: Bool = false
    @Published var isInfoSheetPresented: Bool = false
    @Published var isSaveProfileSheetPresented: Bool = false
    @Published var isSaving: Bool = false
    @Published var profileName: String = ""
    @Published var profileDescription: String = ""
    @Published var isShowingActiveTimer: Bool = false
    @Published var isVisualFeedbackEnabled: Bool = true
    
    // Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    // MARK: - Init
    
    init(audioManager: AudioManagerImpl) {
        self.audioManager = audioManager
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Monitor audio manager state
        audioManager.$isPlaying
            .receive(on: RunLoop.main)
            .sink { [weak self] (isPlaying: Bool) in
                guard let self = self else { return }
                // Only update if the sound category is noise
                if self.audioManager.currentSoundCategory == AudioManagerImpl.SoundCategory.noise {
                    self.isPlaying = isPlaying
                }
            }
            .store(in: &cancellables)
        
        audioManager.$volume
            .receive(on: RunLoop.main)
            .sink { [weak self] volume in
                self?.volume = volume // Already Double now
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func togglePlayback() {
        if isPlaying {
            stopNoise()
        } else {
            playNoise()
        }
    }
    
    func selectNoiseType(_ type: NoiseType) {
        selectedNoiseType = type
        if isPlaying {
            playNoise() // Restart with new noise type
        }
    }
    
    func updateVolume(_ newVolume: Double) {
        volume = newVolume
        audioManager.volume = newVolume
    }
    
    func updateBalance(_ newBalance: Double) {
        balance = newBalance
        // Stereo balance is not directly available in AudioManagerImpl
        // This is a no-op or requires a different approach
        // audioManager.stereoBalance = Float(newBalance)
        print("Stereo balance adjustment not implemented in AudioManagerImpl")
    }
    
    func updateEarDelay(_ newDelay: Double) {
        leftEarDelay = newDelay
        rightEarDelay = newDelay
        // Ear delay is not directly available in AudioManagerImpl
        // This is a no-op or requires a different approach
        // audioManager.earDelay = newDelay
        print("Ear delay adjustment not implemented in AudioManagerImpl")
    }
    
    func startSleepTimer() {
        isShowingActiveTimer = true
        timerDuration = TimeInterval(sleepTimerMinutes * 60)
        
        // Cancel any existing timer
        timer?.invalidate()
        
        // Create a new timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timerDuration > 0 {
                self.timerDuration -= 1
            } else {
                // Time's up, stop playback
                self.stopNoise()
                self.isShowingActiveTimer = false
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }
    
    func cancelSleepTimer() {
        isShowingActiveTimer = false
        timer?.invalidate()
        timer = nil
    }
    
    func saveProfile() {
        isSaveProfileSheetPresented = true
        
        // Logic to save the current noise profile to SwiftData or other storage
        
        // Reset state after saving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSaveProfileSheetPresented = false
            self.profileName = ""
            self.profileDescription = ""
        }
    }
    
    // MARK: - Private Methods
    
    private func playNoise() {
        // Set the sound category to noise
        audioManager.currentSoundCategory = AudioManagerImpl.SoundCategory.noise
        
        // Configure noise parameters
        configureNoiseParameters()
        
        // Play the noise
        audioManager.playSound()
        isPlaying = true
    }
    
    private func stopNoise() {
        audioManager.stopSound()
        isPlaying = false
    }
    
    private func configureNoiseParameters() {
        // Set noise type using the currentNoiseType property
        audioManager.currentNoiseType = convertNoiseType(selectedNoiseType)
        
        // Apply volume settings directly
        audioManager.volume = volume
        
        // Handle the missing properties with workarounds if needed
        // For example, if stereoBalance is not available, we might need to use a different approach
        // or modify the AudioManagerImpl to include these properties
    }
    
    // Helper method to convert between different NoiseType enums if needed
    private func convertNoiseType(_ localType: NoiseType) -> AudioManagerImpl.NoiseType {
        // Map the ViewModels NoiseType to AudioManagerImpl.NoiseType
        switch localType {
        case .white:
            return .white
        case .pink:
            return .pink
        case .brown:
            return .brown
        }
    }
} 