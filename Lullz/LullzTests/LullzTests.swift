//
//  LullzTests.swift
//  LullzTests
//
//  Created by Adam Scott on 3/1/25.
//

import Testing
import AVFoundation
@testable import Lullz

struct LullzTests {
    
    @Test
    func testAudioManagerInitialization() async throws {
        let audioManager = AudioManager()
        #expect(audioManager.isPlaying == false)
        #expect(audioManager.volume == 0.5)
        #expect(audioManager.balance == 0.5)
        #expect(audioManager.leftDelay == 0.0)
        #expect(audioManager.rightDelay == 0.0)
        #expect(audioManager.currentNoiseType == .white)
    }
    
    @Test
    func testNoiseTypeDescriptions() async throws {
        // Test that all noise types have proper descriptions
        for noiseType in AudioManager.NoiseType.allCases {
            #expect(!noiseType.description.isEmpty, "Noise type \(noiseType.rawValue) should have a description")
        }
    }
    
    @Test
    func testNoiseProfileModel() async throws {
        let profile = NoiseProfile(
            name: "Test Profile",
            noiseType: "White",
            volume: 0.7,
            balance: 0.5,
            leftDelay: 0.1,
            rightDelay: 0.2
        )
        
        #expect(profile.name == "Test Profile")
        #expect(profile.noiseType == "White")
        #expect(profile.volume == 0.7)
        #expect(profile.balance == 0.5)
        #expect(profile.leftDelay == 0.1)
        #expect(profile.rightDelay == 0.2)
        #expect(profile.createdAt <= Date())
    }
    
    @Test
    func testAudioPlaybackToggle() async throws {
        let audioManager = AudioManager()
        
        // Test initial state
        #expect(audioManager.isPlaying == false)
        
        // Toggle on
        audioManager.togglePlayback()
        #expect(audioManager.isPlaying == true)
        
        // Toggle off
        audioManager.togglePlayback()
        #expect(audioManager.isPlaying == false)
        
        // Clean up
        audioManager.stopNoise()
    }
    
    @Test
    func testNoiseTypeChange() async throws {
        let audioManager = AudioManager()
        
        // Test that noise type can be changed
        audioManager.currentNoiseType = .white
        #expect(audioManager.currentNoiseType == .white)
        
        audioManager.currentNoiseType = .pink
        #expect(audioManager.currentNoiseType == .pink)
        
        audioManager.currentNoiseType = .brown
        #expect(audioManager.currentNoiseType == .brown)
        
        // Clean up
        audioManager.stopNoise()
    }
}
