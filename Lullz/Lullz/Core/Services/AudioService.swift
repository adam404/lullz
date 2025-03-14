//
//  AudioService.swift
//  Lullz
//
//  Created by Adam Scott
//

import Foundation
import AVFoundation
import Combine

/// Protocol defining the audio service interface
protocol AudioServiceProtocol {
    /// Configure audio for white noise generation
    func configureWhiteNoise() -> Bool
    
    /// Configure audio for pink noise generation
    func configurePinkNoise() -> Bool
    
    /// Configure audio for brown noise generation
    func configureBrownNoise() -> Bool
    
    /// Configure audio for binaural beats
    func configureBinauralBeats(baseFrequency: Double, beatFrequency: Double) -> Bool
    
    /// Start audio playback
    func startPlayback() throws
    
    /// Stop audio playback
    func stopPlayback()
    
    /// Set the volume level (0.0 to 1.0)
    func setVolume(_ volume: Float)
    
    /// Set the stereo balance (-1.0 to 1.0, where -1.0 is full left, 1.0 is full right)
    func setStereoBalance(_ balance: Float)
    
    /// Set the ear delay in seconds (0.0 to 0.3)
    func setEarDelay(_ delay: Double)
    
    /// Check if audio is currently playing
    var isPlaying: Bool { get }
}

/// Audio service implementation
class AudioService: AudioServiceProtocol {
    // Audio engine and nodes
    private var audioEngine: AVAudioEngine
    private var noisePlayer: AVAudioPlayerNode
    private var leftEarPlayer: AVAudioPlayerNode
    private var rightEarPlayer: AVAudioPlayerNode
    private var mixer: AVAudioMixerNode
    
    // Audio buffers
    private var whiteNoiseBuffer: AVAudioPCMBuffer?
    private var pinkNoiseBuffer: AVAudioPCMBuffer?
    private var brownNoiseBuffer: AVAudioPCMBuffer?
    private var binauralLeftBuffer: AVAudioPCMBuffer?
    private var binauralRightBuffer: AVAudioPCMBuffer?
    
    // Current state
    private(set) var isPlaying: Bool = false
    private var currentAudioType: AudioType = .none
    private var currentVolume: Float = 0.7
    private var currentBalance: Float = 0.0
    private var currentEarDelay: Double = 0.0
    
    // Audio settings
    private let sampleRate: Double = 44100.0
    private let channels: AVAudioChannelCount = 2
    
    // Audio types supported
    enum AudioType {
        case none
        case whiteNoise
        case pinkNoise
        case brownNoise
        case binauralBeats
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialize audio components
        audioEngine = AVAudioEngine()
        noisePlayer = AVAudioPlayerNode()
        leftEarPlayer = AVAudioPlayerNode()
        rightEarPlayer = AVAudioPlayerNode()
        mixer = AVAudioMixerNode()
        
        // Set up audio session
        configureAudioSession()
        
        // Set up audio engine
        setupAudioEngine()
        
        // Generate audio buffers
        prepareAudioBuffers()
    }
    
    // MARK: - Public API
    
    func configureWhiteNoise() -> Bool {
        guard let buffer = whiteNoiseBuffer else { return false }
        
        stopPlayback()
        noisePlayer.scheduleBuffer(buffer, at: nil, options: .loops)
        currentAudioType = .whiteNoise
        return true
    }
    
    func configurePinkNoise() -> Bool {
        guard let buffer = pinkNoiseBuffer else { return false }
        
        stopPlayback()
        noisePlayer.scheduleBuffer(buffer, at: nil, options: .loops)
        currentAudioType = .pinkNoise
        return true
    }
    
    func configureBrownNoise() -> Bool {
        guard let buffer = brownNoiseBuffer else { return false }
        
        stopPlayback()
        noisePlayer.scheduleBuffer(buffer, at: nil, options: .loops)
        currentAudioType = .brownNoise
        return true
    }
    
    func configureBinauralBeats(baseFrequency: Double, beatFrequency: Double) -> Bool {
        // Generate binaural beat buffers with the specified frequencies
        generateBinauralBeatBuffers(baseFrequency: baseFrequency, beatFrequency: beatFrequency)
        
        guard let leftBuffer = binauralLeftBuffer, let rightBuffer = binauralRightBuffer else {
            return false
        }
        
        stopPlayback()
        
        // Schedule buffers for each ear
        leftEarPlayer.scheduleBuffer(leftBuffer, at: nil, options: .loops)
        rightEarPlayer.scheduleBuffer(rightBuffer, at: nil, options: .loops)
        
        currentAudioType = .binauralBeats
        return true
    }
    
    func startPlayback() throws {
        guard !isPlaying else { return }
        
        // Start the audio engine if it's not running
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
        
        // Start the appropriate player(s) based on audio type
        if currentAudioType == .binauralBeats {
            leftEarPlayer.play()
            
            // Apply delay if needed
            if currentEarDelay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + currentEarDelay) {
                    self.rightEarPlayer.play()
                }
            } else {
                rightEarPlayer.play()
            }
        } else if currentAudioType != .none {
            noisePlayer.play()
        }
        
        isPlaying = true
    }
    
    func stopPlayback() {
        // Stop all players
        noisePlayer.stop()
        leftEarPlayer.stop()
        rightEarPlayer.stop()
        isPlaying = false
    }
    
    func setVolume(_ volume: Float) {
        currentVolume = volume
        mixer.outputVolume = volume
    }
    
    func setStereoBalance(_ balance: Float) {
        currentBalance = balance
        applyBalanceSettings()
    }
    
    func setEarDelay(_ delay: Double) {
        currentEarDelay = delay
        
        // If currently playing binaural beats, restart with new delay
        if isPlaying && currentAudioType == .binauralBeats {
            let wasPlaying = isPlaying
            stopPlayback()
            
            // Only restart if it was playing
            if wasPlaying {
                try? startPlayback()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioEngine() {
        // Add nodes to engine
        audioEngine.attach(noisePlayer)
        audioEngine.attach(leftEarPlayer)
        audioEngine.attach(rightEarPlayer)
        audioEngine.attach(mixer)
        
        // Connect nodes
        audioEngine.connect(noisePlayer, to: mixer, format: nil)
        audioEngine.connect(leftEarPlayer, to: mixer, format: nil)
        audioEngine.connect(rightEarPlayer, to: mixer, format: nil)
        audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: nil)
        
        // Set initial volume
        mixer.outputVolume = currentVolume
        
        // Prepare engine
        audioEngine.prepare()
    }
    
    private func prepareAudioBuffers() {
        // Generate initial audio buffers
        whiteNoiseBuffer = generateWhiteNoiseBuffer()
        pinkNoiseBuffer = generatePinkNoiseBuffer()
        brownNoiseBuffer = generateBrownNoiseBuffer()
    }
    
    private func generateWhiteNoiseBuffer() -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * 5) // 5 seconds of audio
        guard let buffer = AVAudioPCMBuffer(pcmFormat: createAudioFormat(), frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        // Fill buffer with white noise
        for frame in 0..<Int(frameCount) {
            let sample = Float.random(in: -0.5...0.5)
            
            for channel in 0..<Int(channels) {
                buffer.floatChannelData?[channel][frame] = sample
            }
        }
        
        return buffer
    }
    
    private func generatePinkNoiseBuffer() -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * 5) // 5 seconds of audio
        guard let buffer = AVAudioPCMBuffer(pcmFormat: createAudioFormat(), frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        // Pink noise parameters
        var b0: Float = 0
        var b1: Float = 0
        var b2: Float = 0
        
        // Fill buffer with pink noise
        for frame in 0..<Int(frameCount) {
            let white = Float.random(in: -0.5...0.5)
            
            // Pink noise filter
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            
            let pink = b0 + b1 + b2 + white * 0.5362
            let pinkNormalized = pink * 0.25 // Scale to reasonable volume
            
            for channel in 0..<Int(channels) {
                buffer.floatChannelData?[channel][frame] = pinkNormalized
            }
        }
        
        return buffer
    }
    
    private func generateBrownNoiseBuffer() -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * 5) // 5 seconds of audio
        guard let buffer = AVAudioPCMBuffer(pcmFormat: createAudioFormat(), frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        // Brown noise parameters
        var lastSample: Float = 0
        
        // Fill buffer with brown noise
        for frame in 0..<Int(frameCount) {
            let white = Float.random(in: -0.5...0.5)
            
            // Brown noise filter (leaky integrator)
            lastSample = (lastSample + (0.02 * white)) / 1.02
            let brown = lastSample * 3.5 // Amplify
            
            for channel in 0..<Int(channels) {
                buffer.floatChannelData?[channel][frame] = brown
            }
        }
        
        return buffer
    }
    
    private func generateBinauralBeatBuffers(baseFrequency: Double, beatFrequency: Double) {
        let frameCount = AVAudioFrameCount(sampleRate * 5) // 5 seconds of audio
        
        // Create buffers
        binauralLeftBuffer = AVAudioPCMBuffer(pcmFormat: createAudioFormat(), frameCapacity: frameCount)
        binauralRightBuffer = AVAudioPCMBuffer(pcmFormat: createAudioFormat(), frameCapacity: frameCount)
        
        guard let leftBuffer = binauralLeftBuffer, let rightBuffer = binauralRightBuffer else {
            return
        }
        
        leftBuffer.frameLength = frameCount
        rightBuffer.frameLength = frameCount
        
        // Calculate frequencies for each ear
        let leftFrequency = baseFrequency
        let rightFrequency = baseFrequency + beatFrequency
        
        // Generate sine waves
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            
            // Generate sine waves with the specified frequencies
            let leftSample = Float(sin(2.0 * .pi * leftFrequency * time)) * 0.5
            let rightSample = Float(sin(2.0 * .pi * rightFrequency * time)) * 0.5
            
            // Assign to left buffer (both channels get the same sound)
            for channel in 0..<Int(channels) {
                leftBuffer.floatChannelData?[channel][frame] = leftSample
            }
            
            // Assign to right buffer (both channels get the same sound)
            for channel in 0..<Int(channels) {
                rightBuffer.floatChannelData?[channel][frame] = rightSample
            }
        }
    }
    
    private func createAudioFormat() -> AVAudioFormat {
        return AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channels)!
    }
    
    private func applyBalanceSettings() {
        // Apply pan/balance settings
        let leftGain = sqrt(0.5 * (1.0 - currentBalance))
        let rightGain = sqrt(0.5 * (1.0 + currentBalance))
        
        // Apply different volumes to left and right channels
        if currentAudioType == .binauralBeats {
            leftEarPlayer.volume = leftGain
            rightEarPlayer.volume = rightGain
        } else {
            // For noise generators, we'd apply this to a stereo panner node
            // This is a simplified version
            noisePlayer.pan = currentBalance
        }
    }
} 