//
//  FloatingVolumeControlViewModel.swift
//  Lullz
//
//  Created by Cursor on behalf of Adam Scott
//

import Foundation
import SwiftUI
import Combine

// Create a dedicated ViewModel for FloatingVolumeControl
// This avoids the ambiguity issues with AudioManager
class FloatingVolumeControlViewModel: ObservableObject {
    // Published properties for UI binding
    @Published var volume: Float = 0.5
    @Published var isPlaying: Bool = false
    
    // Change to internal instead of private for access from extension
    internal var audioManager: Any? // We'll use Any to avoid the type ambiguity
    private var cancellables = Set<AnyCancellable>()
    
    init(audioManager: Any) {
        self.audioManager = audioManager
        
        // If the audioManager is the one with volume property, set up binding
        setupBindings()
    }
    
    // Change to internal instead of private for access from extension
    internal func setupBindings() {
        // We'll use Swift's dynamic features to check if methods exist
        if let manager = audioManager as? any ObservableObject {
            // Try to access volume property using Mirror
            let mirror = Mirror(reflecting: manager)
            
            // Check if volume property exists and set up observation
            guard let _ = mirror.children.first(where: { $0.label == "volume" }) else {
                return // Exit if volume property doesn't exist
            }
            
            // Set up observation if volume property exists
            if let publisher = manager.objectWillChange as? ObservableObjectPublisher {
                publisher
                    .sink { [weak self] _ in
                        // When manager changes, update our local properties
                        if let manager = self?.audioManager,
                           let mirror = Mirror(reflecting: manager).children.first(where: { $0.label == "volume" }),
                           let vol = mirror.value as? Float {
                            self?.volume = vol
                        }
                        
                        if let manager = self?.audioManager,
                           let mirror = Mirror(reflecting: manager).children.first(where: { $0.label == "isPlaying" }),
                           let playing = mirror.value as? Bool {
                            self?.isPlaying = playing
                        }
                    }
                    .store(in: &cancellables)
            }
        }
    }
    
    // Volume control methods
    func setVolume(_ newVolume: Float) {
        volume = newVolume
        
        // Use reflection to set volume on actual AudioManager
        if let manager = audioManager {
            // We need to use runtime features to set the property
            Mirror(reflecting: manager).children.forEach { child in
                if child.label == "volume" {
                    // Try to set the volume using performSelector: or setValue:forKey:
                    // This is a simplified example
                    if let obj = manager as? NSObject {
                        obj.setValue(newVolume, forKey: "volume")
                    }
                }
            }
        }
    }
    
    // Toggle mute
    func toggleMute() {
        if volume > 0 {
            // Store current volume and mute
            let oldVolume = volume
            setVolume(0)
            UserDefaults.standard.set(oldVolume, forKey: "lastVolumeLevel")
        } else {
            // Restore from last volume
            let lastVolume = UserDefaults.standard.float(forKey: "lastVolumeLevel")
            setVolume(lastVolume > 0 ? lastVolume : 0.5)
        }
    }
    
    // Update the audioManager reference
    func updateAudioManager(_ manager: Any) {
        self.audioManager = manager
        setupBindings()
    }
} 