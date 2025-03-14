//
//  ProfilesView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI
import SwiftData

struct ProfilesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [NoiseProfile]
    @EnvironmentObject private var audioManager: AudioManagerImpl
    
    @State private var showingAddProfile = false
    @State private var selectedProfile: NoiseProfile?
    @State private var currentProfile: String? = nil
    @State private var savedProfiles: [String] = ["Deep Sleep", "Focus", "Meditation", "Reading"]
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Saved Profiles")) {
                    ForEach(savedProfiles, id: \.self) { profile in
                        Button(action: {
                            activateProfile(profile)
                        }) {
                            HStack {
                                Text(profile)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if currentProfile == profile {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteProfile)
                }
                
                Section {
                    Button(action: {
                        // Show create new profile UI
                        // This would be implemented separately
                    }) {
                        Label("Create New Profile", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Sound Profiles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Edit mode toggle would be implemented here
                    }) {
                        Text("Edit")
                    }
                }
            }
        }
    }
    
    private func activateProfile(_ profile: String) {
        // In a real implementation, this would load audio settings from the profile
        // For now, just update the current profile
        currentProfile = profile
        
        // Simulate loading profile settings
        // In a real implementation, this would actually configure the audio manager
    }
    
    private func deleteProfile(at offsets: IndexSet) {
        savedProfiles.remove(atOffsets: offsets)
        
        // If we deleted the current profile, deselect it
        if let currentProfile = currentProfile, !savedProfiles.contains(currentProfile) {
            self.currentProfile = nil
        }
    }
}

struct ProfileDetailView: View {
    @EnvironmentObject var audioManager: AudioManager
    let profile: NoiseProfile

    var body: some View {
        VStack {
            // Existing code...
        }
    }
} 