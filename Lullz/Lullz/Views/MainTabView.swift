//
//  MainTabView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        TabView {
            NoiseGeneratorView()
                .tabItem {
                    Label("Noise", systemImage: "waveform")
                }
            
            LazyView(BinauralBeatsView())
                .tabItem {
                    Label("Binaural", systemImage: "earbuds")
                }
            
            LazyView(MixedEnvironmentView())
                .tabItem {
                    Label("Environments", systemImage: "mountain.2")
                }
            
            LazyView(BreathingPatternsView())
                .tabItem {
                    Label("Breathing", systemImage: "lungs.fill")
                }
            
            LazyView(SmartHomeControlView())
                .tabItem {
                    Label("Smart Home", systemImage: "homekit")
                }
            
            LazyView(ProfilesView())
                .tabItem {
                    Label("Profiles", systemImage: "list.bullet")
                }
            
            LazyView(InformationView())
                .tabItem {
                    Label("Information", systemImage: "info.circle")
                }
            
            LazyView(SettingsView())
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            // App has already initialized environments in LullzApp.swift
            // No need to create default environments here
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
        .environmentObject(AudioManager())
} 