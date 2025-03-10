//
//  AudioManager.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import Foundation
import AVFoundation
import Combine
import SwiftData
#if os(iOS)
import UIKit
#endif

class AudioManager: ObservableObject {
    // Noise type enum
    enum NoiseType: String, CaseIterable, Identifiable {
        case white = "White"
        case pink = "Pink"
        case brown = "Brown"
        case blue = "Blue"
        case violet = "Violet"
        case grey = "Grey"
        case green = "Green"
        case black = "Black"
        
        var id: String { self.rawValue }
        
        var description: String {
            switch self {
            case .white:
                return "Equal power across all frequencies, helpful for masking environmental sounds."
            case .pink:
                return "Power decreases as frequency increases (1/f spectrum), often described as more natural sounding."
            case .brown:
                return "Power decreases more rapidly at higher frequencies (1/f² spectrum), creating a deeper, richer sound."
            case .blue:
                return "Power increases with frequency (f¹ spectrum), emphasizing higher frequencies. May help with focus and alertness."
            case .violet:
                return "Power increases more steeply with frequency (f² spectrum), strongly emphasizing highest frequencies. Used for treating tinnitus in some studies."
            case .grey:
                return "Psychoacoustically engineered noise that sounds equally loud at all frequencies to human ears. Excellent for masking sounds across the hearing range."
            case .green:
                return "Midrange-focused noise, similar to the ambient sounds of nature. Studies suggest it may have soothing effects similar to natural environments."
            case .black:
                return "Mostly silence with random intermittent noise, creating an environment with minimal auditory stimulation for deep focus."
            }
        }
        
        var scientificBasis: String {
            switch self {
            case .white:
                return "Named after white light, which contains all visible wavelengths. Used in acoustic testing and has equal energy per frequency band."
            case .pink:
                return "Follows 1/f power density, common in natural systems like heartbeats, traffic flow, and many biological processes. Studies show potential benefits for sleep and concentration."
            case .brown:
                return "Named after Brownian motion, follows a 1/f² power spectrum. Research shows potential benefits for sleep and relaxation due to its resemblance to natural sounds like rainfall or ocean waves."
            case .blue:
                return "The spectral opposite of pink noise. Studies suggest blue noise may help with perception of high-frequency sounds and could aid concentration on detailed tasks."
            case .violet:
                return "Also called purple noise, follows an f² power density. Some research indicates potential applications in tinnitus masking and auditory system stimulation."
            case .grey:
                return "Engineered with a spectrum matching the ear's frequency response curve. Research in psychoacoustics shows it creates perceptually uniform loudness across frequencies."
            case .green:
                return "Modeled after the frequency distribution of natural environments. Environmental psychology research suggests nature-like sounds can reduce stress and improve cognitive function."
            case .black:
                return "Based on principles of sensory deprivation and minimal stimulation. Studies in cognitive psychology suggest benefits for deep concentration and meditative states."
            }
        }
    }
    
    // Add a new enum for sound categories
    enum SoundCategory: String, CaseIterable, Identifiable {
        case noise = "Noise"
        case binaural = "Binaural"
        
        var id: String { self.rawValue }
    }
    
    // Published properties for UI binding
    @Published var isPlaying = false
    @Published var volume: Float = 0.5 {
        didSet {
            audioEngine.mainMixerNode.outputVolume = volume
        }
    }
    @Published var balance: Float = 0.5 {
        didSet {
            updateBalance()
        }
    }
    @Published var leftDelay: Float = 0.0 {
        didSet {
            updateLeftDelay()
        }
    }
    @Published var rightDelay: Float = 0.0 {
        didSet {
            updateRightDelay()
        }
    }
    @Published var currentNoiseType: NoiseType = .white {
        didSet {
            if oldValue != currentNoiseType && isPlaying {
                // Just update the noise type without stopping/restarting
                updateNoiseType()
            }
        }
    }
    @Published var currentSoundCategory: SoundCategory = .noise {
        didSet {
            if oldValue != currentSoundCategory && isPlaying {
                // Need to completely rebuild the audio chain when switching categories
                stopSound()
                playSound()
            }
        }
    }
    @Published var currentBinauralPreset: BinauralBeatsGenerator.BinauralPreset = .relaxation
    @Published var binauralVolume: Float = 0.5
    @Published var carrierNoiseEnabled: Bool = false
    @Published var carrierNoiseVolume: Float = 0.2
    @Published var sleepTimerActive: Bool = false
    @Published var sleepTimerDuration: TimeInterval = 30 * 60 // Default: 30 minutes
    @Published var visualizer: SoundVisualizer?
    @Published var currentProfile: NoiseProfile?
    
    // Audio engine components
    private let audioEngine = AVAudioEngine()
    private var noiseSourceNode: AVAudioSourceNode?
    private var leftDelayNode = AVAudioUnitDelay()
    private var rightDelayNode = AVAudioUnitDelay()
    private var stereoMixer = AVAudioMixerNode()
    private var stereoBalanceNode = AVAudioUnitEQ()
    
    // Add a time tracker for the binaural beats generator
    private var currentSampleTime: Int = 0
    
    // Add these properties to AudioManager
    private var sleepTimer: Timer?
    private var sleepTimerEndDate: Date?
    
    private let greyNoiseEQCurve: [Float] = [
        -11.0, -10.0, -8.5, -7.5, -6.0, -5.0, -4.0, -3.0, 
        -2.0, -1.0, 0.0, 1.0, 1.5, 1.5, 1.2, 0.0, -2.5, 
        -4.0, -5.2, -6.0, -7.0, -10.0, -14.0
    ]
    private lazy var greyNoiseBuffers = Array(repeating: [Float](repeating: 0, count: 8), count: self.greyNoiseEQCurve.count)
    private lazy var greyNoiseOutputs = [Float](repeating: 0, count: self.greyNoiseEQCurve.count)
    
    init() {
        // First initialize with minimal setup to avoid startup delays
        setupBasicAudioEngine()
        
        // Then complete the full setup in the background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.completeAudioEngineSetup()
        }
        
        // Add observer for audio route changes
        NotificationCenter.default.addObserver(
            forName: Notification.Name("AudioRouteChanged"),
            object: nil,
            queue: .main) { [weak self] _ in
                guard let self = self else { return }
                if self.isPlaying {
                    // Restart audio engine to ensure playback continues with new route
                    self.stopNoise()
                    self.playNoise()
                }
            }
        
        // Initialize the visualizer
        visualizer = SoundVisualizer(audioEngine: audioEngine)
    }
    
    // Split setup into two parts - basic for immediate use and detailed for background
    private func setupBasicAudioEngine() {
        // Set initial volume - this is a quick operation
        audioEngine.mainMixerNode.outputVolume = volume
    }
    
    private func completeAudioEngineSetup() {
        // Configure delay nodes initial settings
        leftDelayNode.delayTime = 0.0
        rightDelayNode.delayTime = 0.0
        
        // Create balance EQ (using a simple EQ as a makeshift balance control)
        let stereoBalanceFilter = AVAudioUnitEQ(numberOfBands: 2)
        stereoBalanceFilter.bands[0].bypass = false
        stereoBalanceFilter.bands[0].filterType = .parametric
        stereoBalanceFilter.bands[0].frequency = 1000
        stereoBalanceFilter.bands[0].bandwidth = 1.0
        stereoBalanceFilter.bands[0].gain = 0.0
        
        stereoBalanceFilter.bands[1].bypass = false
        stereoBalanceFilter.bands[1].filterType = .parametric
        stereoBalanceFilter.bands[1].frequency = 1000
        stereoBalanceFilter.bands[1].bandwidth = 1.0
        stereoBalanceFilter.bands[1].gain = 0.0
        
        stereoBalanceNode = stereoBalanceFilter
    }
    
    // Balance control (simple implementation)
    private func updateBalance() {
        // Convert 0-1 balance to dB gain values for left/right channels
        // This is a simplified implementation; a real app would use more sophisticated spatial audio
        let leftGain = balance <= 0.5 ? 0.0 : -((balance - 0.5) * 2) * 40
        let rightGain = balance >= 0.5 ? 0.0 : -((0.5 - balance) * 2) * 40
        
        stereoBalanceNode.bands[0].gain = leftGain
        stereoBalanceNode.bands[1].gain = rightGain
    }
    
    private func updateLeftDelay() {
        // Convert normalized 0-1 delay to 0-500ms
        leftDelayNode.delayTime = Double(leftDelay * 0.5)
    }
    
    private func updateRightDelay() {
        // Convert normalized 0-1 delay to 0-500ms
        rightDelayNode.delayTime = Double(rightDelay * 0.5)
    }
    
    func playNoise() {
        // Run intensive audio setup in background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.stopNoise() // Clear any existing playback
            
            // Create stereo format (2 channels)
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
            
            // Create noise generator node
            self.noiseSourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
                let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                
                for frame in 0..<Int(frameCount) {
                    // Generate noise based on selected type
                    var sample: Float = 0.0
                    
                    switch self.currentNoiseType {
                    case .white:
                        sample = self.generateWhiteNoise()
                    case .pink:
                        sample = self.generatePinkNoise()
                    case .brown:
                        sample = self.generateBrownNoise()
                    case .blue:
                        sample = self.generateBlueNoise()
                    case .violet:
                        sample = self.generateVioletNoise()
                    case .grey:
                        sample = self.generateGreyNoise()
                    case .green:
                        sample = self.generateGreenNoise()
                    case .black:
                        sample = self.generateBlackNoise()
                    }
                    
                    // Fill both channels with the same sample for now
                    for buffer in ablPointer {
                        let bufferPointer = UnsafeMutableBufferPointer<Float>(buffer)
                        bufferPointer[frame] = sample
                    }
                }
                
                return noErr
            }
            
            // Connect and start on main thread
            DispatchQueue.main.async {
                do {
                    // Configure the rest of the audio processing chain
                    self.configureAudioProcessingChain(format: format)
                    
                    // Start the audio engine
                    try self.audioEngine.start()
                    self.isPlaying = true
                } catch {
                    print("Error starting audio engine: \(error)")
                }
            }
        }
    }
    
    // Split out configuration from playback to make the code more maintainable
    private func configureAudioProcessingChain(format: AVAudioFormat) {
        guard let noiseSourceNode = self.noiseSourceNode else { return }
        
        // Attach all the nodes to the engine
        audioEngine.attach(noiseSourceNode)
        audioEngine.attach(leftDelayNode)
        audioEngine.attach(rightDelayNode)
        audioEngine.attach(stereoMixer)
        audioEngine.attach(stereoBalanceNode)
        
        // Connect noise source to both delay nodes
        audioEngine.connect(noiseSourceNode, to: leftDelayNode, format: format)
        audioEngine.connect(noiseSourceNode, to: rightDelayNode, format: format)
        
        // Connect leftDelay and rightDelay to stereoMixer on separate input buses
        audioEngine.connect(leftDelayNode, to: stereoMixer, fromBus: 0, toBus: 0, format: format)
        audioEngine.connect(rightDelayNode, to: stereoMixer, fromBus: 0, toBus: 1, format: format)
        
        // Connect stereoMixer output (stereo signal) to stereoBalanceNode (single input)
        audioEngine.connect(stereoMixer, to: stereoBalanceNode, format: format)
        
        // Connect stereoBalanceNode to the main mixer
        audioEngine.connect(stereoBalanceNode, to: audioEngine.mainMixerNode, format: format)
        
        // Update processing parameters
        updateBalance()
        updateLeftDelay()
        updateRightDelay()
        
        // First remove any existing tap to avoid the crash
        audioEngine.mainMixerNode.removeTap(onBus: 0)
        
        // Then install a new tap
        audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { (buffer, _) in
            // Tap to keep processing active
        }
    }
    
    func stopNoise() {
        // Remove the tap if it exists
        do {
            audioEngine.mainMixerNode.removeTap(onBus: 0)
        } catch {
            print("Error removing audio tap: \(error.localizedDescription)")
            // Continue with cleanup even if tap removal fails
        }
        
        if let sourceNode = noiseSourceNode {
            audioEngine.detach(sourceNode)
            self.noiseSourceNode = nil
        }
        
        audioEngine.stop()
        isPlaying = false
    }
    
    // Update togglePlayback to provide immediate UI feedback
    func togglePlayback() {
        if isPlaying {
            stopSound()
        } else {
            playSound()
        }
    }
    
    func pausePlayback() {
        if isPlaying {
            audioEngine.pause()
            isPlaying = false
        }
    }
    
    func resumePlayback() {
        if !isPlaying {
            do {
                try audioEngine.start()
                isPlaying = true
            } catch {
                print("Could not resume audio engine: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Noise Generation Algorithms
    
    private func generateWhiteNoise() -> Float {
        // Simple white noise generator
        return Float.random(in: -0.5...0.5)
    }
    
    private var pinkNoiseBuffer = [Float](repeating: 0.0, count: 7)
    private func generatePinkNoise() -> Float {
        // Pink noise approximation using Voss algorithm
        var white = Float.random(in: -0.5...0.5)
        var pink = white
        
        for i in 0..<pinkNoiseBuffer.count {
            if UInt.random(in: 0...UInt(1 << i)) == 0 {
                pinkNoiseBuffer[i] = white
            }
            pink += pinkNoiseBuffer[i]
        }
        
        // Normalize
        return pink / 8.0
    }
    
    private var brownNoiseLastValue: Float = 0.0
    private func generateBrownNoise() -> Float {
        // Brown noise approximation
        let white = Float.random(in: -0.5...0.5)
        brownNoiseLastValue = (brownNoiseLastValue + (0.02 * white)) / 1.02
        return brownNoiseLastValue * 3.0 // Amplify the signal a bit
    }
    
    private var blueNoiseState: Float = 0.0
    private func generateBlueNoise() -> Float {
        // Blue noise has increasing power with frequency
        // This is a simplified implementation using differentiation of white noise
        let white = generateWhiteNoise()
        let blue = white - blueNoiseState
        blueNoiseState = white
        return blue * 0.5 // Normalize amplitude
    }
    
    private var violetNoiseState1: Float = 0.0
    private var violetNoiseState2: Float = 0.0
    private func generateVioletNoise() -> Float {
        // Violet noise increases power with frequency more steeply (f²)
        // Implemented as double differentiation of white noise
        let white = generateWhiteNoise()
        let temp = white - violetNoiseState1
        violetNoiseState1 = white
        let violet = temp - violetNoiseState2
        violetNoiseState2 = temp
        return violet * 0.25 // Normalize amplitude
    }
    
    private func generateGreyNoise() -> Float {
        // Grey noise applies psychoacoustic equal-loudness curve to white noise
        // This is a multi-band filtered approach
        let white = generateWhiteNoise()
        
        // Run white noise through simulated filter bank
        for band in 0..<greyNoiseEQCurve.count {
            // Simple 1-pole filter simulation for each band
            greyNoiseBuffers[band].removeFirst()
            greyNoiseBuffers[band].append(white)
            
            // Apply the equal loudness contour for this band
            let gain = pow(10, greyNoiseEQCurve[band] / 20.0)
            greyNoiseOutputs[band] = greyNoiseBuffers[band].reduce(0, +) / Float(greyNoiseBuffers[band].count) * gain
        }
        
        // Sum all bands
        return greyNoiseOutputs.reduce(0, +) / Float(greyNoiseOutputs.count) * 2.0
    }
    
    private let greenNoiseFilters = (0..<6).map { _ in (state: Float(0), coeff: Float.random(in: 0.15...0.35)) }
    private var greenNoiseState = Float(0)
    private func generateGreenNoise() -> Float {
        // Green noise emphasizes the middle frequency range like natural environments
        // Implemented as band-passed noise focused on 500Hz-2kHz region
        var white = generateWhiteNoise()
        
        // Apply bandpass filtering
        for i in 0..<greenNoiseFilters.count {
            let coeff = greenNoiseFilters[i].coeff
            greenNoiseState = (1-coeff) * greenNoiseState + coeff * white
            white = greenNoiseState
        }
        
        return greenNoiseState * 2.0 // Compensate for filter attenuation
    }
    
    private var blackNoiseCounter = 0
    private func generateBlackNoise() -> Float {
        // Black noise is mostly silence with occasional random sounds
        // This implementation produces brief noise bursts in otherwise silent audio
        blackNoiseCounter += 1
        
        // Create occasional random bursts (roughly once every 2-4 seconds at 44.1kHz)
        if blackNoiseCounter >= Int.random(in: 88200...176400) {
            blackNoiseCounter = 0
            return generateWhiteNoise() * Float.random(in: 0.05...0.2)
        }
        
        // Add extremely quiet noise floor to avoid complete digital silence
        return generateWhiteNoise() * 0.001
    }
    
    // Helper function to generate the appropriate noise type
    private func generateNoiseForCurrentType() -> Float {
        switch currentNoiseType {
        case .white:
            return generateWhiteNoise()
        case .pink:
            return generatePinkNoise()
        case .brown:
            return generateBrownNoise()
        case .blue:
            return generateBlueNoise()
        case .violet:
            return generateVioletNoise()
        case .grey:
            return generateGreyNoise()
        case .green:
            return generateGreenNoise()
        case .black:
            return generateBlackNoise()
        }
    }
    
    // Modify the playNoise function to handle binaural beats
    func playSound() {
        stopSound() // Clear any existing playback
        
        // Create stereo format (2 channels)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        
        // Reset sample time counter
        currentSampleTime = 0
        
        // Create audio source node based on the current sound category
        switch currentSoundCategory {
        case .noise:
            createNoiseSourceNode(format: format)
        case .binaural:
            createBinauralSourceNode(format: format)
        }
        
        // Configure the rest of the audio chain and start playback
        if let sourceNode = noiseSourceNode {
            configureAudioProcessingChain(format: format)
            
            do {
                try audioEngine.start()
                isPlaying = true
                
                // Ensure we don't have an existing tap before installing a new one
                // Do NOT install tap here, it's already done in configureAudioProcessingChain
                // This is likely causing the crash
                
            } catch {
                print("Could not start audio engine: \(error.localizedDescription)")
                isPlaying = false
            }
        }
    }
    
    // Create a dedicated method for creating a noise source node
    private func createNoiseSourceNode(format: AVAudioFormat) {
        // Create noise generator node
        self.noiseSourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            for frame in 0..<Int(frameCount) {
                // Generate noise based on selected type
                let sample = self.generateNoiseForCurrentType()
                
                // Fill both channels with the same sample for now
                for buffer in ablPointer {
                    let bufferPointer = UnsafeMutableBufferPointer<Float>(buffer)
                    bufferPointer[frame] = sample
                }
            }
            
            return noErr
        }
    }
    
    // Create a dedicated method for creating a binaural source node
    private func createBinauralSourceNode(format: AVAudioFormat) {
        // Create binaural beats generator node
        self.noiseSourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            for frame in 0..<Int(frameCount) {
                var leftSample: Float = 0.0
                var rightSample: Float = 0.0
                
                // Generate binaural beat samples
                let time = Double(self.currentSampleTime + frame) / 44100.0
                let binauralSamples = BinauralBeatsGenerator.generateBinauralSamples(
                    leftFreq: self.currentBinauralPreset.leftFrequency,
                    rightFreq: self.currentBinauralPreset.rightFrequency,
                    sampleRate: 44100.0,
                    time: time
                )
                
                leftSample = binauralSamples.left * self.binauralVolume
                rightSample = binauralSamples.right * self.binauralVolume
                
                // If carrier noise is enabled, mix in some noise
                if self.carrierNoiseEnabled {
                    let noiseSample = self.generateNoiseForCurrentType() * self.carrierNoiseVolume
                    leftSample += noiseSample
                    rightSample += noiseSample
                }
                
                // Fill channels with appropriate samples
                if ablPointer.count >= 2 {
                    let leftBufferPointer = UnsafeMutableBufferPointer<Float>(ablPointer[0])
                    let rightBufferPointer = UnsafeMutableBufferPointer<Float>(ablPointer[1])
                    
                    leftBufferPointer[frame] = leftSample
                    rightBufferPointer[frame] = rightSample
                } else if ablPointer.count >= 1 {
                    let bufferPointer = UnsafeMutableBufferPointer<Float>(ablPointer[0])
                    bufferPointer[frame] = (leftSample + rightSample) * 0.5
                }
            }
            
            // Increment sample time for continuous phase
            self.currentSampleTime += Int(frameCount)
            
            return noErr
        }
    }
    
    // Rename these functions to match the new naming convention
    func stopSound() {
        // Same as the old stopNoise() function
        stopNoise()
    }
    
    // Add these functions to AudioManager
    func startSleepTimer() {
        guard !sleepTimerActive else { return }
        
        // Set the end date
        sleepTimerEndDate = Date().addingTimeInterval(sleepTimerDuration)
        
        // Create and schedule the timer
        sleepTimer = Timer.scheduledTimer(
            withTimeInterval: sleepTimerDuration,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.isPlaying {
                self.stopSound()
            }
            self.sleepTimerActive = false
            self.sleepTimerEndDate = nil
            // Post notification that timer completed
            NotificationCenter.default.post(
                name: Notification.Name("SleepTimerCompleted"),
                object: nil
            )
        }
        
        sleepTimerActive = true
        // Post notification that timer started
        NotificationCenter.default.post(
            name: Notification.Name("SleepTimerStarted"),
            object: sleepTimerDuration
        )
    }

    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerEndDate = nil
        sleepTimerActive = false
        // Post notification that timer was canceled
        NotificationCenter.default.post(
            name: Notification.Name("SleepTimerCanceled"),
            object: nil
        )
    }

    func timeRemainingOnSleepTimer() -> TimeInterval? {
        guard sleepTimerActive, let endDate = sleepTimerEndDate else {
            return nil
        }
        let remaining = endDate.timeIntervalSinceNow
        return remaining > 0 ? remaining : 0
    }
    
    // Add this to the deinit method (or create it if it doesn't exist)
    deinit {
        sleepTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // Add this method to AudioManager
    func createDefaultEnvironments() {
        // Use a background thread to handle this work
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            let modelContext = SwiftDataModel.shared.modelContainer.mainContext
            
            // Check if we already have presets - do this check on the main thread
            let descriptor = FetchDescriptor<MixedEnvironment>(predicate: #Predicate { $0.isPreset })
            
            // Fetch on main thread to avoid SwiftData threading issues
            Task { @MainActor in
                let existingPresets = try? modelContext.fetch(descriptor)
                
                if existingPresets?.isEmpty ?? true {
                    // Create environments in the background
                    let environments = self.buildDefaultEnvironments()
                    
                    // Insert them on the main thread
                    Task { @MainActor in
                        // Add presets to the model context
                        for environment in environments {
                            modelContext.insert(environment)
                        }
                    }
                }
            }
        }
    }

    // Create a separate method to build the environments (CPU-intensive part)
    private func buildDefaultEnvironments() -> [MixedEnvironment] {
        var environments: [MixedEnvironment] = []
        
        // Create Rainy Night preset
        let rainyNight = MixedEnvironment(
            name: "Rainy Night",
            description: "A soothing combination of rain sounds and deep brown noise"
        )
        rainyNight.isPreset = true
        rainyNight.layers = [
            SoundLayer(
                soundType: "brown",
                volume: 0.4,
                balance: 0.5,
                isActive: true
            ),
            SoundLayer(
                soundType: "white",
                volume: 0.2,
                balance: 0.5,
                isActive: true,
                modulation: .amplitude,
                modulationRate: 0.2,
                modulationDepth: 0.4
            ),
            SoundLayer(
                soundType: "pink",
                volume: 0.15,
                balance: 0.35,
                isActive: true
            )
        ]
        environments.append(rainyNight)
        
        // Create Ocean Waves preset
        let oceanWaves = MixedEnvironment(
            name: "Ocean Waves",
            description: "Gentle ocean waves with subtle spatial movement"
        )
        oceanWaves.isPreset = true
        oceanWaves.layers = [
            SoundLayer(
                soundType: "brown",
                volume: 0.5,
                balance: 0.5,
                isActive: true,
                modulation: .spatial,
                modulationRate: 0.07,
                modulationDepth: 0.3
            ),
            SoundLayer(
                soundType: "white",
                volume: 0.2,
                balance: 0.5,
                isActive: true,
                modulation: .amplitude,
                modulationRate: 0.1,
                modulationDepth: 0.7
            )
        ]
        environments.append(oceanWaves)
        
        // Create Meditation Space preset
        let meditationSpace = MixedEnvironment(
            name: "Meditation Space",
            description: "A blend of binaural beats and gentle background noise"
        )
        meditationSpace.isPreset = true
        meditationSpace.layers = [
            SoundLayer(
                soundType: "binaural",
                volume: 0.5,
                balance: 0.5,
                isActive: true,
                binauralPreset: "meditation"
            ),
            SoundLayer(
                soundType: "pink",
                volume: 0.15,
                balance: 0.5,
                isActive: true
            )
        ]
        environments.append(meditationSpace)
        
        // Create Forest Morning preset
        let forestMorning = MixedEnvironment(
            name: "Forest Morning",
            description: "The peaceful ambient sounds of a forest at dawn"
        )
        forestMorning.isPreset = true
        forestMorning.layers = [
            SoundLayer(
                soundType: "green",
                volume: 0.45,
                balance: 0.5,
                isActive: true
            ),
            SoundLayer(
                soundType: "pink",
                volume: 0.2,
                balance: 0.6,
                isActive: true,
                modulation: .amplitude,
                modulationRate: 0.12,
                modulationDepth: 0.2
            ),
            SoundLayer(
                soundType: "white",
                volume: 0.1,
                balance: 0.4,
                isActive: true,
                modulation: .amplitude,
                modulationRate: 0.3,
                modulationDepth: 0.5
            )
        ]
        environments.append(forestMorning)
        
        return environments
    }
    
    // Add this method to AudioManager
    func activateSmartHomeConfig(for profile: NoiseProfile) {
        // Access HomeManager through the environment or DI mechanism
        // This will be set by the app when initializing AudioManager
        NotificationCenter.default.post(name: Notification.Name("ActivateSmartHomeConfig"), 
                                       object: nil, 
                                       userInfo: ["profileId": profile.id])
    }

    // Also add this to the playProfile method
    func playProfile(_ profile: NoiseProfile) {
        // Existing code...
        
        // If smart home integration is enabled, apply the associated configuration
        if UserDefaults.standard.bool(forKey: "enableSmartHomeIntegration") {
            activateSmartHomeConfig(for: profile)
        }
    }

    @MainActor
    func saveCurrentProfile() {
        // Use SwiftDataModel instead of persistentContainer
        let mainContext = SwiftDataModel.shared.modelContainer.mainContext
        // ... existing code ...
    }

    func showLegalAlert(for documentType: LegalDocumentType) {
        #if os(iOS)
        // iOS implementation
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // ... existing code ...
        }
        #else
        // macOS implementation
        // Add appropriate macOS alert code here or use a platform-agnostic approach
        print("Legal alert showing not implemented for this platform")
        #endif
    }

    // Add this method to update noise type without completely restarting playback
    private func updateNoiseType() {
        // Only use this optimized method for switching between noise types
        // within the same sound category
        guard currentSoundCategory == .noise else {
            // For category changes, use the full restart approach
            stopSound()
            playSound()
            return
        }
        
        // Update noise generation without completely stopping the engine
        // This is more efficient than stopping and restarting
        
        // If the audio engine isn't running, don't do anything
        guard audioEngine.isRunning else { return }
        
        // Detach the old source node if it exists
        if let sourceNode = noiseSourceNode {
            audioEngine.detach(sourceNode)
            self.noiseSourceNode = nil
        }
        
        // Create a new source node with the current noise type
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        
        // Create noise generator node
        self.noiseSourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            for frame in 0..<Int(frameCount) {
                // Generate noise based on selected type
                let sample = self.generateNoiseForCurrentType()
                
                // Fill both channels with the same sample for now
                for buffer in ablPointer {
                    let bufferPointer = UnsafeMutableBufferPointer<Float>(buffer)
                    bufferPointer[frame] = sample
                }
            }
            
            return noErr
        }
        
        // Attach and connect the new source node
        guard let sourceNode = noiseSourceNode else { return }
        audioEngine.attach(sourceNode)
        
        // Connect to delay nodes
        audioEngine.connect(sourceNode, to: leftDelayNode, format: format)
        audioEngine.connect(sourceNode, to: rightDelayNode, format: format)
    }
} 