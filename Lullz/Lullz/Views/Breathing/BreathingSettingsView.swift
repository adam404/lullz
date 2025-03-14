//
//  BreathingSettingsView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct BreathingSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let pattern: BreathingPattern
    @Binding var targetCycles: Int
    
    @State private var useAudioCues: Bool
    @State private var audioVolume: Float
    @State private var vibrationEnabled: Bool
    @State private var voiceGuidanceEnabled: Bool
    @State private var accentColor: Color
    
    // For background sound
    @State private var backgroundNoiseEnabled: Bool
    @State private var backgroundNoiseType: String
    @State private var backgroundNoiseVolume: Float
    
    init(pattern: BreathingPattern, targetCycles: Binding<Int>) {
        self.pattern = pattern
        self._targetCycles = targetCycles
        
        // Initialize state from pattern
        self._useAudioCues = State(initialValue: pattern.useAudioCues)
        self._audioVolume = State(initialValue: pattern.audioVolume)
        self._vibrationEnabled = State(initialValue: pattern.vibrationEnabled)
        self._voiceGuidanceEnabled = State(initialValue: pattern.voiceGuidanceEnabled)
        
        // Safely convert the accent color with a fallback to blue
        let parsedColor = Color(hex: pattern.accentColor)
        if parsedColor == nil {
            print("Could not parse color from hex: \(pattern.accentColor), using default blue")
        }
        self._accentColor = State(initialValue: parsedColor ?? .blue)
        
        self._backgroundNoiseEnabled = State(initialValue: pattern.backgroundNoiseType != nil)
        self._backgroundNoiseType = State(initialValue: pattern.backgroundNoiseType ?? AudioManagerImpl.NoiseType.brown.rawValue)
        self._backgroundNoiseVolume = State(initialValue: pattern.backgroundNoiseVolume)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Settings")) {
                    Stepper("Target Cycles: \(targetCycles)", value: $targetCycles, in: 1...20)
                }
                
                Section(header: Text("Audio Settings")) {
                    Toggle("Audio Cues", isOn: $useAudioCues)
                    
                    if useAudioCues {
                        HStack {
                            Text("Volume")
                            Slider(value: $audioVolume, in: 0...1)
                            Text("\(Int(audioVolume * 100))%")
                                .frame(width: 40)
                        }
                    }
                    
                    Toggle("Vibration", isOn: $vibrationEnabled)
                    Toggle("Voice Guidance", isOn: $voiceGuidanceEnabled)
                }
                
                Section(header: Text("Background Sound")) {
                    Toggle("Enable Background Noise", isOn: $backgroundNoiseEnabled)
                    
                    if backgroundNoiseEnabled {
                        Picker("Noise Type", selection: $backgroundNoiseType) {
                            ForEach(AudioManagerImpl.NoiseType.allCases) { type in
                                Text(type.rawValue).tag(type.rawValue)
                            }
                        }
                        
                        HStack {
                            Text("Volume")
                            Slider(value: $backgroundNoiseVolume, in: 0...0.5)
                            Text("\(Int(backgroundNoiseVolume * 100))%")
                                .frame(width: 40)
                        }
                    }
                }
                
                Section(header: Text("Visual Settings")) {
                    ColorPicker("Accent Color", selection: $accentColor)
                }
                
                if !pattern.isPreset {
                    Section {
                        Button("Save as Default for This Pattern") {
                            saveSettings()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    // Apply settings temporarily without saving to model
                    applySettings()
                    dismiss()
                }
            )
        }
    }
    
    private func applySettings() {
        // Update the pattern in memory (won't persist)
        pattern.useAudioCues = useAudioCues
        pattern.audioVolume = audioVolume
        pattern.vibrationEnabled = vibrationEnabled
        pattern.voiceGuidanceEnabled = voiceGuidanceEnabled
        
        // Convert color to hex
        if let components = accentColor.cgColor?.components, components.count >= 3 {
            let r = Int(components[0] * 255.0)
            let g = Int(components[1] * 255.0)
            let b = Int(components[2] * 255.0)
            pattern.accentColor = String(format: "#%02X%02X%02X", r, g, b)
        }
        
        // Update background sound settings
        pattern.backgroundNoiseType = backgroundNoiseEnabled ? backgroundNoiseType : nil
        pattern.backgroundNoiseVolume = backgroundNoiseVolume
    }
    
    private func saveSettings() {
        // Apply the settings
        applySettings()
        
        // Only save if this isn't a preset pattern
        if !pattern.isPreset {
            try? modelContext.save()
        }
    }
} 