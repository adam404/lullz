//
//  SettingsView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("visualizerType") private var visualizerType = "Spectrum"
    @AppStorage("showVisualizerInLockScreen") private var showVisualizerInLockScreen = false
    
    // Replace the direct Color AppStorage with a string storage and computed property
    @AppStorage("visualizerColorHex") private var visualizerColorHex = "#0000FF" // Default blue in hex
    
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("showAdsEnabled") private var showAdsEnabled = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .onChange(of: darkModeEnabled) { _, newValue in
                            setAppAppearance(darkMode: newValue)
                        }
                    
                    Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                } header: {
                    Text("Appearance")
                }
                
                Section {
                    Picker("Visualizer Style", selection: $visualizerType) {
                        ForEach(["Spectrum", "Waveform", "Circular", "Bars"], id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    Toggle("Show on Lock Screen", isOn: $showVisualizerInLockScreen)
                    
                    ColorPicker("Visualizer Color", selection: Binding(
                        get: { Color(hex: visualizerColorHex) ?? .blue },
                        set: { newColor in
                            if let hex = newColor.toHex() {
                                visualizerColorHex = hex
                            }
                        }
                    ))
                } header: {
                    Text("Visualizer")
                }
                
                Section {
                    Toggle("Background Audio", isOn: .constant(true))
                        .disabled(true)
                        .foregroundColor(.secondary)
                    
                    Toggle("High Quality Audio", isOn: .constant(true))
                        .disabled(true)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Audio")
                }
                
                Section {
                    NavigationLink {
                        LegalSectionView()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.accentColor)
                            Text("Terms & Privacy")
                        }
                    }
                    
                    if let acknowledgmentDate = UserDefaults.standard.object(forKey: "legalTermsAcknowledgmentDate") as? Date {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Terms Acknowledged")
                                    .font(.subheadline)
                                Text(acknowledgmentDate, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Legal Information")
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: Text("Thank you for using Lullz App!\n\nDeveloped by Adam Scott").padding()) {
                        Text("About Lullz")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func setAppAppearance(darkMode: Bool) {
        // Set the app appearance based on dark mode preference
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = darkMode ? .dark : .light
            }
        }
    }
}

// Only include toHex() since the init(hex:) is already defined elsewhere
extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AudioManager())
    }
}