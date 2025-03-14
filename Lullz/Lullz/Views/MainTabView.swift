//
//  MainTabView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var audioManager: AudioManagerImpl
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NoiseGeneratorView()
                .tabItem {
                    Label("Noise", systemImage: "waveform")
                }
                .tag(0)
                .onAppear {
                    // Ensure sound category is set to noise when this tab is selected
                    audioManager.currentSoundCategory = AudioManagerImpl.SoundCategory.noise
                }
            
            LazyView(BinauralBeatsView())
                .tabItem {
                    Label("Binaural", systemImage: "earbuds")
                }
                .tag(1)
                .onAppear {
                    // Ensure sound category is set to binaural when this tab is selected
                    audioManager.currentSoundCategory = AudioManagerImpl.SoundCategory.binaural
                }
            
            LazyView(MixedEnvironmentView())
                .tabItem {
                    Label("Environments", systemImage: "mountain.2")
                }
                .tag(2)
            
            LazyView(BreathingPatternsView())
                .tabItem {
                    Label("Breathing", systemImage: "lungs.fill")
                }
                .tag(3)
                      
            LazyView(ProfilesView())
                .tabItem {
                    Label("Profiles", systemImage: "list.bullet")
                }
                .tag(4)
            
            LazyView(InformationView())
                .tabItem {
                    Label("Information", systemImage: "info.circle")
                }
                .tag(5)
            
            LazyView(SettingsView())
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(6)
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            // Ensure audio continues playing when switching tabs
            if audioManager.isPlaying {
                // If we're switching between Noise and Binaural tabs, handle audio state
                if (oldTab == 0 && newTab == 1) || (oldTab == 1 && newTab == 0) {
                    // Don't do anything, let the views handle their respective audio
                }
            }
        }
        .onAppear {
            // App has already initialized environments in LullzApp.swift
            // No need to create default environments here
            
            // Setup notification observers for audio state changes
            setupNotificationObservers()
        }
    }
    
    private func setupNotificationObservers() {
        // Listen for audio playback notifications to ensure UI is consistent
        NotificationCenter.default.addObserver(
            forName: Notification.Name("AudioPlaybackStarted"),
            object: nil,
            queue: .main
        ) { notification in
            // If playback started and it's binaural, switch to binaural tab
            if let category = notification.object as? AudioManagerImpl.SoundCategory,
               category == .binaural && selectedTab != 1 {
                // Only auto-switch if explicitly requested
            }
        }
    }
}

// Add a LazyView struct to delay the initialization of tab views until they're actually shown
struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}

#Preview {
    MainTabView()
        .environmentObject(AudioManagerImpl.shared)
} 
