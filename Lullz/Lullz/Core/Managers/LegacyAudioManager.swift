//
//  AudioManager.swift
//  Lullz
//
//  Created by Adam Scott
//

import Foundation
import AVFoundation
import Combine

/// Sound categories supported by the app
enum SoundCategory {
    case noise
    case binaural
    case mixed
}

/// Main audio manager class that coordinates audio playback across the app
class AudioManager: ObservableObject {
    // Singleton instance for app-wide access
    static let shared = AudioManager()
    
    // Dependencies
    private let audioService: AudioServiceProtocol
    
    // Published properties for reactive UI
    @Published var isPlaying: Bool = false
    @Published var volume: Float = 0.7 {
        didSet {
            audioService.setVolume(volume)
        }
    }
    @Published var stereoBalance: Float = 0.0 {
        didSet {
            audioService.setStereoBalance(stereoBalance)
        }
    }
    @Published var earDelay: Double = 0.0 {
        didSet {
            audioService.setEarDelay(earDelay)
        }
    }
    @Published var currentSoundCategory: SoundCategory = .noise
    
    // Private state
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(audioService: AudioServiceProtocol? = nil) {
        // Use the provided service or create a new one
        self.audioService = audioService ?? AudioService()
        
        // Set up observation of audio service state
        setupObservation()
    }
    
    // MARK: - Public API
    
    /// Play sound based on the current configuration
    func playSound() {
        do {
            try audioService.startPlayback()
            self.isPlaying = true
        } catch {
            print("Failed to start audio playback: \(error.localizedDescription)")
        }
    }
    
    /// Stop the current sound
    func stopSound() {
        audioService.stopPlayback()
        self.isPlaying = false
    }
    
    /// Toggle between play and pause
    func togglePlayback() {
        if isPlaying {
            stopSound()
        } else {
            playSound()
        }
    }
    
    /// Configure white noise
    func configureWhiteNoise() {
        let success = audioService.configureWhiteNoise()
        if !success {
            print("Failed to configure white noise")
        }
    }
    
    /// Configure pink noise
    func configurePinkNoise() {
        let success = audioService.configurePinkNoise()
        if !success {
            print("Failed to configure pink noise")
        }
    }
    
    /// Configure brown noise
    func configureBrownNoise() {
        let success = audioService.configureBrownNoise()
        if !success {
            print("Failed to configure brown noise")
        }
    }
    
    /// Configure binaural beats
    func configureBinauralBeats(withBaseFrequency baseFrequency: Double, beatFrequency: Double) {
        let success = audioService.configureBinauralBeats(baseFrequency: baseFrequency, beatFrequency: beatFrequency)
        if !success {
            print("Failed to configure binaural beats")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservation() {
        // This would monitor the audio service state
        // In a real implementation, the AudioService would have Observable properties
        // or would use NotificationCenter
        
        // For now, we'll use a simple timer as an example
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Update isPlaying state based on audioService
            let serviceIsPlaying = self.audioService.isPlaying
            if self.isPlaying != serviceIsPlaying {
                DispatchQueue.main.async {
                    self.isPlaying = serviceIsPlaying
                }
            }
        }
    }
} 