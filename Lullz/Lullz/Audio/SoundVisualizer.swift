//
//  SoundVisualizer.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import Foundation
import AVFoundation
import Accelerate

class SoundVisualizer: ObservableObject {
    private let fftSetup: FFTSetup
    private let log2n: Int
    private let n: Int
    private let halfN: Int
    
    @Published var amplitudes: [Float] = []
    @Published var waveformPoints: [CGPoint] = []
    
    private var audioEngine: AVAudioEngine
    private var bufferSize: AVAudioFrameCount = 1024
    private var audioBuffer: [Float] = []
    
    init(audioEngine: AVAudioEngine) {
        self.audioEngine = audioEngine
        
        // Set up FFT parameters
        self.log2n = Int(log2(Float(bufferSize)))
        self.n = Int(1 << log2n)
        self.halfN = Int(n/2)
        
        // Initialize the FFT
        self.fftSetup = vDSP_create_fftsetup(vDSP_Length(log2n), Int32(kFFTRadix2))!
        
        // Initialize with empty data
        self.amplitudes = Array(repeating: 0.0, count: halfN)
        
        setupAudioTap()
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
        
        // Use try-catch to safely remove the tap
        do {
            // Try bus 1 first, then bus 0
            if audioEngine.mainMixerNode.numberOfOutputs > 1 {
                audioEngine.mainMixerNode.removeTap(onBus: 1)
            }
            audioEngine.mainMixerNode.removeTap(onBus: 0)
        } catch {
            print("Error removing audio tap: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioTap() {
        let format = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        
        // First remove any existing tap on this bus to avoid conflicts
        audioEngine.mainMixerNode.removeTap(onBus: 0)
        
        // Try to use bus 1 if available to avoid conflicts with AudioManager
        let bus: AVAudioNodeBus = 1
        
        // Check if the node has the requested output bus
        let hasRequestedBus = audioEngine.mainMixerNode.numberOfOutputs > Int(bus)
        let useBus = hasRequestedBus ? bus : 0
        
        audioEngine.mainMixerNode.installTap(onBus: useBus, bufferSize: bufferSize, format: format) { [weak self] (buffer, _) in
            guard let self = self else { return }
            
            // Get audio buffer
            let channelData = buffer.floatChannelData?[0]
            let frameLength = buffer.frameLength
            
            // Process audio for visualization
            self.processAudioBufferToFrequencies(data: channelData!, frameLength: frameLength)
            self.processAudioBufferToWaveform(data: channelData!, frameLength: frameLength)
        }
    }
    
    private func processAudioBufferToFrequencies(data: UnsafeMutablePointer<Float>, frameLength: AVAudioFrameCount) {
        // Create a local array to hold the audio data
        var realp = [Float](repeating: 0, count: halfN)
        var imagp = [Float](repeating: 0, count: halfN)
        var output = DSPSplitComplex(realp: &realp, imagp: &imagp)
        
        // Load audio samples into buffer
        audioBuffer = Array(UnsafeBufferPointer(start: data, count: Int(frameLength)))
        
        // If buffer is smaller than expected, pad with zeros
        if audioBuffer.count < n {
            audioBuffer.append(contentsOf: [Float](repeating: 0, count: n - audioBuffer.count))
        }
        
        // Apply Hanning window to reduce spectral leakage
        var window = [Float](repeating: 0, count: n)
        vDSP_hann_window(&window, vDSP_Length(n), Int32(vDSP_HANN_NORM))
        vDSP_vmul(audioBuffer, 1, window, 1, &audioBuffer, 1, vDSP_Length(n))
        
        // Convert real audio data to split complex form for FFT
        vDSP_ctoz(UnsafeRawPointer(audioBuffer).assumingMemoryBound(to: DSPComplex.self), 2, &output, 1, vDSP_Length(halfN))
        
        // Perform forward FFT
        vDSP_fft_zrip(fftSetup, &output, 1, vDSP_Length(log2n), FFTDirection(FFT_FORWARD))
        
        // Calculate magnitude
        var magnitudes = [Float](repeating: 0, count: halfN)
        vDSP_zvmags(&output, 1, &magnitudes, 1, vDSP_Length(halfN))
        
        // Normalize and convert to dB
        var normalizedMagnitudes = [Float](repeating: 0, count: halfN)
        var scalingFactor = Float(1.0 / Double(n))
        vDSP_vsmul(magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, vDSP_Length(halfN))
        
        // Convert to dB
        for i in 0..<halfN {
            normalizedMagnitudes[i] = 10.0 * log10f(normalizedMagnitudes[i] + 1e-6)
        }
        
        // Set amplitudes with some smoothing
        DispatchQueue.main.async {
            for i in 0..<self.halfN {
                // Add some smoothing to avoid too rapid changes
                let smoothingFactor: Float = 0.2
                self.amplitudes[i] = self.amplitudes[i] * (1 - smoothingFactor) + normalizedMagnitudes[i] * smoothingFactor
            }
        }
    }
    
    private func processAudioBufferToWaveform(data: UnsafeMutablePointer<Float>, frameLength: AVAudioFrameCount) {
        // Create points for waveform visualization
        let waveformLength = min(Int(frameLength), 128) // Limit points for performance
        let stride = max(1, Int(frameLength) / waveformLength)
        
        var newPoints: [CGPoint] = []
        
        for i in 0..<waveformLength {
            let sample = data[i * stride]
            let point = CGPoint(x: CGFloat(i) / CGFloat(waveformLength - 1), y: CGFloat(sample))
            newPoints.append(point)
        }
        
        DispatchQueue.main.async {
            self.waveformPoints = newPoints
        }
    }
    
    // Helper function to get a subset of frequencies for visualization
    func getBandLevels(bands: Int) -> [Float] {
        guard bands > 0 && bands <= halfN else { return [] }
        
        var result = [Float](repeating: 0, count: bands)
        let bandsPerBin = halfN / bands
        
        for i in 0..<bands {
            let startBin = i * bandsPerBin
            let endBin = min(startBin + bandsPerBin, halfN)
            
            // Average the amplitudes in this range
            var sum: Float = 0
            for j in startBin..<endBin {
                // Normalize to 0-1 range and apply some scaling
                let normalized = (amplitudes[j] + 80) / 80 // Assuming typical dB range
                sum += max(0, min(1, normalized))
            }
            result[i] = sum / Float(endBin - startBin)
        }
        
        return result
    }
} 