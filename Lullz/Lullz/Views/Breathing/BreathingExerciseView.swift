//
//  BreathingExerciseView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI
import AVFoundation

struct BreathingExerciseView: View {
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.dismiss) private var dismiss
    let pattern: BreathingPattern
    
    @State private var isActive: Bool = false
    @State private var currentStepIndex: Int = 0
    @State private var progress: Double = 0.0
    @State private var cyclesCompleted: Int = 0
    @State private var targetCycles: Int = 5
    @State private var timer: Timer?
    @State private var showingSettings = false
    
    // Add a local mutable copy of the pattern's useAudioCues property
    @State private var localUseAudioCues: Bool = true
    
    // Audio feedback - make these @State so they can be modified in methods
    @State private var inhaleSound: AVAudioPlayer?
    @State private var exhaleSound: AVAudioPlayer?
    @State private var holdSound: AVAudioPlayer?
    
    private var currentStep: BreathStep {
        pattern.steps[currentStepIndex]
    }
    
    // Add public initializer
    init(pattern: BreathingPattern) {
        self.pattern = pattern
        self._localUseAudioCues = State(initialValue: pattern.useAudioCues)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                // Header info
                VStack {
                    HStack {
                        Button {
                            pauseExercise()
                            cleanupAudio()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .padding([.top, .leading])
                        
                        Spacer()
                    }
                    
                    Text(pattern.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(cyclesCompleted)/\(targetCycles) cycles completed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if isActive {
                        HStack(spacing: 20) {
                            Button {
                                resetExercise()
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                            }
                            
                            Button {
                                isActive.toggle()
                                if isActive {
                                    startExercise()
                                } else {
                                    pauseExercise()
                                }
                            } label: {
                                Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.accentColor)
                            }
                            
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title2)
                            }
                        }
                        .padding(.top, 10)
                    } else {
                        Button {
                            isActive.toggle()
                            startExercise()
                        } label: {
                            Text("Start Exercise")
                                .font(.headline)
                                .padding()
                                .frame(width: geometry.size.width * 0.7)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()
                
                // Main breathing circle
                BreathingCircleView(
                    phase: currentStep.phase,
                    progress: progress,
                    color: Color(hex: pattern.accentColor) ?? .blue
                )
                .frame(width: min(geometry.size.width, geometry.size.height) * 0.7,
                       height: min(geometry.size.width, geometry.size.height) * 0.7)
                .padding()
                
                // Current instruction
                Text(currentStep.phase.instruction)
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding(.bottom, 5)
                
                // Timer display
                Text(String(format: "%.1f", currentStep.durationSeconds * (1 - progress)))
                    .font(.system(size: 36, design: .monospaced))
                    .fontWeight(.bold)
                
                // Instructions - fix the property name
                Text(pattern.patternDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .task {
                // Use task instead of onAppear for better timing
                print("BreathingExerciseView task started with pattern: \(pattern.name)")
                setupAudio()
                // Initialize immediately to the first step
                currentStepIndex = 0
                progress = 0.01 // Start with a tiny bit of progress to make the animation visible
                
                // Add a small delay and then update progress to force redraw
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    print("Forcing UI update for BreathingExerciseView")
                    // Toggle a tiny bit of progress to force a UI update
                    progress = 0.02
                }
            }
            .onDisappear {
                pauseExercise()
                cleanupAudio()
            }
            .sheet(isPresented: $showingSettings) {
                BreathingSettingsView(pattern: pattern, targetCycles: $targetCycles)
            }
        }
    }
    
    private func setupAudio() {
        // Setup audio files
        if localUseAudioCues {
            do {
                var audioFilesFound = false
                
                if let inhalePath = Bundle.main.path(forResource: "inhale", ofType: "wav") {
                    self.inhaleSound = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: inhalePath))
                    self.inhaleSound?.prepareToPlay()
                    self.inhaleSound?.volume = pattern.audioVolume
                    audioFilesFound = true
                } else {
                    print("WARNING: inhale.wav audio file not found in bundle")
                }
                
                if let exhalePath = Bundle.main.path(forResource: "exhale", ofType: "wav") {
                    self.exhaleSound = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: exhalePath))
                    self.exhaleSound?.prepareToPlay()
                    self.exhaleSound?.volume = pattern.audioVolume
                    audioFilesFound = true
                } else {
                    print("WARNING: exhale.wav audio file not found in bundle")
                }
                
                if let holdPath = Bundle.main.path(forResource: "hold", ofType: "wav") {
                    self.holdSound = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: holdPath))
                    self.holdSound?.prepareToPlay()
                    self.holdSound?.volume = pattern.audioVolume
                    audioFilesFound = true
                } else {
                    print("WARNING: hold.wav audio file not found in bundle")
                }
                
                // If none of the audio files were found, disable audio cues to avoid potential issues
                if !audioFilesFound {
                    print("No breathing audio files found in bundle. Disabling audio cues.")
                    // Just disable locally, don't modify the pattern
                    localUseAudioCues = false
                }
            } catch {
                print("Error loading audio files: \(error.localizedDescription)")
                // Disable audio cues if there was an error
                localUseAudioCues = false
            }
        }
        
        // Set up background noise if desired
        if let noiseType = pattern.backgroundNoiseType, let type = AudioManager.NoiseType(rawValue: noiseType) {
            audioManager.currentNoiseType = type
            audioManager.volume = pattern.backgroundNoiseVolume
            
            if !audioManager.isPlaying {
                audioManager.playNoise()
            }
        }
    }
    
    private func cleanupAudio() {
        // Stop any playing audio
        if audioManager.isPlaying {
            audioManager.stopNoise()
        }
    }
    
    private func startExercise() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateProgress()
        }
        
        // Play sound cue for initial step
        playStepAudio()
    }
    
    private func pauseExercise() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetExercise() {
        pauseExercise()
        cyclesCompleted = 0
        currentStepIndex = 0
        progress = 0.0
    }
    
    private func updateProgress() {
        // Update progress in current step
        progress += 0.05 / currentStep.durationSeconds
        
        // Check if step is complete
        if progress >= 1.0 {
            // Move to next step
            progress = 0.0
            currentStepIndex = (currentStepIndex + 1) % pattern.steps.count
            
            // Check if a cycle is complete
            if currentStepIndex == 0 {
                cyclesCompleted += 1
                
                // Check if all cycles are complete
                if cyclesCompleted >= targetCycles {
                    pauseExercise()
                    isActive = false
                    return
                }
            }
            
            // Play audio for the new step
            playStepAudio()
        }
    }
    
    private func playStepAudio() {
        guard localUseAudioCues else { return }
        
        // Play appropriate sound based on the phase
        switch currentStep.phase {
        case .inhale:
            inhaleSound?.play()
        case .exhale:
            exhaleSound?.play()
        case .hold, .holdAfterInhale, .holdAfterExhale:
            holdSound?.play()
        }
        
        // Add haptic feedback if enabled
        if pattern.vibrationEnabled {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}

// Helper extension to convert hex string to Color
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        // Ensure we have valid input
        guard hexSanitized.count == 6 else {
            print("Invalid hex color: \(hex) - wrong length")
            return nil
        }
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            print("Invalid hex color: \(hex) - scanning failed")
            return nil
        }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    // Create a sample breathing pattern for preview
    let samplePattern = BreathingPattern(
        name: "4-7-8 Breathing",
        description: "Inhale for 4, hold for 7, exhale for 8 seconds",
        steps: [
            BreathStep(phase: .inhale, durationSeconds: 4),
            BreathStep(phase: .holdAfterInhale, durationSeconds: 7),
            BreathStep(phase: .exhale, durationSeconds: 8)
        ],
        isPreset: true
    )
    
    return BreathingExerciseView(pattern: samplePattern)
        .environmentObject(AudioManager())
} 
