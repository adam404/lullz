//
//  MixedEnvironmentEngine.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import Foundation
import AVFoundation
import AVFAudio
import CoreAudioTypes // Add this import for AUValue

class MixedEnvironmentEngine {
    private let audioEngine = AVAudioEngine()
    private var sourceNodes: [UUID: AVAudioSourceNode] = [:]
    private var balanceNodes: [UUID: AVAudioUnitEQ] = [:]
    private var gainNodes: [UUID: AVAudioUnitEQ] = [:]
    private var modulationNodes: [UUID: AVAudioUnitEffect] = [:]
    private var currentLayers: [SoundLayer] = []
    private var isPlaying = false
    private var sampleTime: Int = 0
    private var isPaused = false
    private var _currentEnvironment: UUID? = nil
    
    // Public property to access the current environment ID
    var currentEnvironment: UUID? {
        return _currentEnvironment
    }
    
    // Init and setup basic audio engine
    init() {
        // Perform setup in the background to avoid blocking the UI thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupAudioEngine()
        }
    }
    
    private func setupAudioEngine() {
        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, options: [.mixWithOthers, .duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    // Load and play a mixed environment
    func playEnvironment(_ environment: MixedEnvironment) {
        // Stop existing playback first (quick operation)
        stopAllSounds()
        
        // Store the current environment ID
        _currentEnvironment = environment.id
        
        // Perform the heavy loading work in a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Store active layers
            self.currentLayers = environment.layers.filter { $0.isActive }
            
            // Create nodes for each layer (heavy operation)
            for layer in self.currentLayers {
                self.createLayerNodes(layer)
            }
            
            // Start the engine on the main thread
            DispatchQueue.main.async {
                do {
                    try self.audioEngine.start()
                    self.isPlaying = true
                    self.isPaused = false
                } catch {
                    print("Could not start audio engine: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Stop all sounds
    func stopAllSounds() {
        if isPlaying {
            audioEngine.stop()
            
            // Clean up all nodes
            for (id, node) in sourceNodes {
                audioEngine.detach(node)
                sourceNodes.removeValue(forKey: id)
            }
            
            for (id, node) in balanceNodes {
                audioEngine.detach(node)
                balanceNodes.removeValue(forKey: id)
            }
            
            for (id, node) in gainNodes {
                audioEngine.detach(node)
                gainNodes.removeValue(forKey: id)
            }
            
            for (id, node) in modulationNodes {
                audioEngine.detach(node)
                modulationNodes.removeValue(forKey: id)
            }
            
            isPlaying = false
            isPaused = false
            currentLayers = []
            _currentEnvironment = nil // Clear the current environment
        }
    }
    
    // Add pause functionality
    func pausePlayback() {
        if isPlaying && !isPaused {
            audioEngine.pause()
            isPaused = true
            isPlaying = false
        }
    }
    
    // Add resume functionality
    func resumePlayback() {
        if isPaused {
            do {
                try audioEngine.start()
                isPlaying = true
                isPaused = false
            } catch {
                print("Could not resume audio engine: \(error.localizedDescription)")
            }
        }
    }
    
    // Create the audio processing chain for a layer
    private func createLayerNodes(_ layer: SoundLayer) {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        
        // Create source node based on sound type
        let sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            // Generate samples for this layer
            for frame in 0..<Int(frameCount) {
                var leftSample: Float = 0.0
                var rightSample: Float = 0.0
                
                // Generate appropriate sound type
                if layer.soundType.starts(with: "binaural") {
                    // Generate binaural beat samples
                    let binauralSamples = self.generateBinauralSample(for: layer, frame: frame)
                    leftSample = binauralSamples.left
                    rightSample = binauralSamples.right
                } else {
                    // Generate noise samples
                    let noiseSample = self.generateNoiseSample(for: layer, frame: frame)
                    leftSample = noiseSample
                    rightSample = noiseSample
                }
                
                // Apply modulation if present
                if let modType = layer.modulation, modType != .none,
                   let rate = layer.modulationRate,
                   let depth = layer.modulationDepth {
                    (leftSample, rightSample) = self.applyModulation(
                        type: modType,
                        to: (leftSample, rightSample),
                        rate: rate,
                        depth: depth,
                        time: Double(self.sampleTime + frame) / 44100.0
                    )
                }
                
                // Fill stereo channels
                if ablPointer.count >= 2 {
                    // True stereo
                    let leftBufferPointer = UnsafeMutableBufferPointer<Float>(ablPointer[0])
                    let rightBufferPointer = UnsafeMutableBufferPointer<Float>(ablPointer[1])
                    
                    leftBufferPointer[frame] = leftSample
                    rightBufferPointer[frame] = rightSample
                } else if ablPointer.count >= 1 {
                    // Mono fallback
                    let bufferPointer = UnsafeMutableBufferPointer<Float>(ablPointer[0])
                    bufferPointer[frame] = (leftSample + rightSample) * 0.5
                }
            }
            
            // Update sample time for continuous phase
            self.sampleTime += Int(frameCount)
            
            return noErr
        }
        
        // Create balance node (pan)
        let balanceNode = createBalanceNode(for: layer)
        
        // Create gain node (volume)
        let gainNode = createGainNode(for: layer)
        
        // Add nodes to engine
        audioEngine.attach(sourceNode)
        audioEngine.attach(balanceNode)
        audioEngine.attach(gainNode)
        
        // Connect nodes
        audioEngine.connect(sourceNode, to: balanceNode, format: format)
        audioEngine.connect(balanceNode, to: gainNode, format: format)
        audioEngine.connect(gainNode, to: audioEngine.mainMixerNode, format: format)
        
        // Store nodes by layer ID for later access
        sourceNodes[layer.id] = sourceNode
        balanceNodes[layer.id] = balanceNode
        gainNodes[layer.id] = gainNode
    }
    
    // Helper methods to generate appropriate samples
    private func generateNoiseSample(for layer: SoundLayer, frame: Int) -> Float {
        switch layer.soundType {
        case "white":
            return Float.random(in: -0.5...0.5)
        case "pink":
            // Pink noise generation (simplified)
            return generatePinkNoise()
        case "brown":
            // Brown noise generation (simplified)
            return generateBrownNoise()
        // Add other noise types...
        default:
            return Float.random(in: -0.5...0.5) // Default to white noise
        }
    }
    
    // Noise generators (simplified versions)
    private var pinkNoiseBuffer = [Float](repeating: 0.0, count: 7)
    private func generatePinkNoise() -> Float {
        let white = Float.random(in: -0.5...0.5)
        var pink: Float = 0.0
        
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
        let white = Float.random(in: -0.5...0.5)
        brownNoiseLastValue = (brownNoiseLastValue + (0.02 * white)) / 1.02
        return brownNoiseLastValue * 3.0
    }
    
    // Generate binaural beats
    private func generateBinauralSample(for layer: SoundLayer, frame: Int) -> (left: Float, right: Float) {
        // Extract preset info from layer.soundType or binauralPreset
        var leftFreq: Float = 200.0
        var rightFreq: Float = 204.0
        
        // Determine frequencies based on preset
        if let preset = layer.binauralPreset {
            switch preset {
            case "relaxation":
                leftFreq = 200.0
                rightFreq = 204.0 // 4Hz difference
            case "focus":
                leftFreq = 315.0
                rightFreq = 325.0 // 10Hz difference
            // Add more presets...
            default:
                break
            }
        }
        
        // Generate binaural beat
        let time = Double(sampleTime + frame) / 44100.0
        let leftPhase = Float(2.0 * Double.pi * Double(leftFreq) * time)
        let rightPhase = Float(2.0 * Double.pi * Double(rightFreq) * time)
        
        let leftSample = sin(leftPhase)
        let rightSample = sin(rightPhase)
        
        return (leftSample, rightSample)
    }
    
    // Apply various modulation effects
    private func applyModulation(
        type: ModulationType,
        to samples: (left: Float, right: Float),
        rate: Float,
        depth: Float,
        time: Double
    ) -> (left: Float, right: Float) {
        
        let modulator = sin(Float(2.0 * Double.pi * Double(rate) * time))
        let modulationAmount = modulator * depth
        
        switch type {
        case .amplitude:
            // Amplitude modulation
            let amplitudeScale = 1.0 + modulationAmount
            return (samples.left * amplitudeScale, samples.right * amplitudeScale)
            
        case .frequency:
            // Simple frequency modulation approximation
            // (In a real implementation, this would need more sophisticated time-domain manipulation)
            let phaseOffset = modulationAmount * 0.1
            let time = time + Double(phaseOffset)
            let newLeftPhase = Float(2.0 * Double.pi * Double(200) * time)
            let newRightPhase = Float(2.0 * Double.pi * Double(204) * time)
            return (sin(newLeftPhase), sin(newRightPhase))
            
        case .spatial:
            // Spatial modulation (panning)
            let panPosition = (modulationAmount + 1.0) / 2.0 // Map from [-1,1] to [0,1]
            let leftGain = sqrt(1.0 - panPosition)
            let rightGain = sqrt(panPosition)
            return (samples.left * leftGain, samples.right * rightGain)
            
        case .none:
            return samples
        }
    }
    
    // Create audio processing nodes
    private func createBalanceNode(for layer: SoundLayer) -> AVAudioUnitEQ {
        let balanceNode = AVAudioUnitEQ(numberOfBands: 1)
        
        // Convert balance value (0-1) to pan value (-1 to 1)
        let panValue = (layer.balance * 2.0) - 1.0
        
        // Set pan parameter
        if let parameterTree = balanceNode.auAudioUnit.parameterTree,
           let panParameter = parameterTree.allParameters.first {
            panParameter.value = AUValue(panValue)
        }
        
        return balanceNode
    }
    
    private func createGainNode(for layer: SoundLayer) -> AVAudioUnitEQ {
        let gainNode = AVAudioUnitEQ(numberOfBands: 1)
        
        // Convert linear volume to dB gain (0 = -∞dB, 1 = 0dB)
        let gainValue = max(-80.0, 20.0 * log10(layer.volume))
        
        // Set gain parameter
        if let parameterTree = gainNode.auAudioUnit.parameterTree,
           let gainParameter = parameterTree.allParameters.first {
            gainParameter.value = AUValue(gainValue)
        }
        
        return gainNode
    }
    
    // Update parameters for a specific layer
    func updateLayer(_ layer: SoundLayer) {
        guard let balanceNode = balanceNodes[layer.id],
              let gainNode = gainNodes[layer.id] else {
            return
        }
        
        // Update balance
        let panValue = (layer.balance * 2.0) - 1.0
        if let parameterTree = balanceNode.auAudioUnit.parameterTree,
           let panParameter = parameterTree.allParameters.first {
            panParameter.value = AUValue(panValue)
        }
        
        // Update volume
        let gainValue = max(-80.0, 20.0 * log10(layer.volume))
        if let parameterTree = gainNode.auAudioUnit.parameterTree,
           let gainParameter = parameterTree.allParameters.first {
            gainParameter.value = AUValue(gainValue)
        }
    }
    
    // Toggle a layer on/off
    func toggleLayer(id: UUID, active: Bool) {
        if let _ = sourceNodes[id],
           let _ = balanceNodes[id],
           let gainNode = gainNodes[id] {
            
            if !active {
                // Disable by setting volume to zero
                if let parameterTree = gainNode.auAudioUnit.parameterTree,
                   let gainParameter = parameterTree.allParameters.first {
                    gainParameter.value = -80.0 // -80dB ~= silence
                }
            } else {
                // Find the layer and restore its volume
                if let layer = currentLayers.first(where: { $0.id == id }) {
                    let gainValue = max(-80.0, 20.0 * log10(layer.volume))
                    if let parameterTree = gainNode.auAudioUnit.parameterTree,
                       let gainParameter = parameterTree.allParameters.first {
                        gainParameter.value = AUValue(gainValue)
                    }
                }
            }
        }
    }
} 