import SwiftUI
import SwiftData

struct ProfilesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [NoiseProfile]
    @EnvironmentObject private var audioManager: AudioManager
    
    @State private var showingAddProfile = false
    @State private var selectedProfile: NoiseProfile?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(profiles) { profile in
                    Button {
                        selectedProfile = profile
                        audioManager.playProfile(profile)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                    .font(.headline)
                                Text(profile.noiseType)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if let current = audioManager.currentProfile, current.id == profile.id {
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            deleteProfile(profile)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        NavigationLink {
                            ProfileDetailView(profile: profile)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("Noise Profiles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddProfile = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                Text("Add Profile View")
                    .presentationDetents([.medium])
            }
        }
    }
    
    private func deleteProfile(_ profile: NoiseProfile) {
        modelContext.delete(profile)
        
        if let current = audioManager.currentProfile, current.id == profile.id {
            audioManager.stopNoise()
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