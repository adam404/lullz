//
//  NoiseGeneratorView.swift
//  Lullz
//
//  Created by Adam Scott
//

import SwiftUI
import Combine

struct NoiseGeneratorFeatureView: View {
    // Use StateObject for view model instantiation in the view
    @StateObject private var viewModel: NoiseGeneratorViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    // Dependency injection through init
    init(audioManager: AudioManagerImpl? = nil) {
        // Use the provided audio manager or the shared instance
        let manager = audioManager ?? AudioManagerImpl.shared
        // Use _StateObject for initialization in init
        _viewModel = StateObject(wrappedValue: NoiseGeneratorViewModel(audioManager: manager))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Noise type selector
                noiseTypeSelector
                
                // Description of selected noise
                noiseDescription
                
                Spacer()
                
                // Controls
                controlsSection
                
                Spacer()
                
                // Play/Pause button
                playButton
                
                // Timer indicator (if active)
                timerIndicator
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.isSaveProfileSheetPresented) {
            saveProfileSheet
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.05, green: 0.05, blue: 0.1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var headerView: some View {
        Text("Noise Generator")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.top, 20)
    }
    
    private var noiseTypeSelector: some View {
        HStack(spacing: 20) {
            ForEach(NoiseType.allCases) { noiseType in
                noiseButton(noiseType)
            }
        }
        .padding(.vertical)
    }
    
    private func noiseButton(_ type: NoiseType) -> some View {
        Button(action: {
            viewModel.selectNoiseType(type)
        }) {
            VStack {
                ZStack {
                    Circle()
                        .fill(viewModel.selectedNoiseType == type ? Color.white.opacity(0.2) : Color.clear)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                
                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.top, 5)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 5)
    }
    
    private var noiseDescription: some View {
        Text(viewModel.selectedNoiseType.description)
            .font(.body)
            .foregroundColor(.white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.bottom, 10)
            .frame(height: 60)
    }
    
    private var controlsSection: some View {
        VStack(spacing: 30) {
            // Volume slider
            VStack(spacing: 10) {
                HStack {
                    Text("Volume")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(viewModel.volume * 100))%")
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Slider(value: Binding(
                    get: { viewModel.volume },
                    set: { viewModel.updateVolume($0) }
                ), in: 0...1, step: 0.01)
                .accentColor(.white)
            }
            
            // Balance slider
            VStack(spacing: 10) {
                HStack {
                    Text("Balance")
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack {
                    Text("L")
                        .foregroundColor(.white.opacity(0.8))
                    
                    Slider(value: Binding(
                        get: { viewModel.balance },
                        set: { viewModel.updateBalance($0) }
                    ), in: 0...1, step: 0.01)
                    .accentColor(.white)
                    
                    Text("R")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Ear delay slider
            VStack(spacing: 10) {
                HStack {
                    Text("Ear Delay")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(viewModel.leftEarDelay * 1000)) ms")
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Slider(value: Binding(
                    get: { viewModel.leftEarDelay },
                    set: { viewModel.updateEarDelay($0) }
                ), in: 0...0.3, step: 0.001)
                .accentColor(.white)
            }
            
            // Sleep timer button
            Button {
                if viewModel.isTimerActive {
                    viewModel.cancelSleepTimer()
                } else {
                    viewModel.startSleepTimer()
                }
            } label: {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 20))
                    
                    Text(viewModel.isTimerActive ? "Cancel Timer" : "Sleep Timer")
                        .font(.headline)
                }
                .foregroundColor(viewModel.isTimerActive ? .orange : .white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.15))
                .cornerRadius(10)
            }
            
            // Save profile button
            Button {
                viewModel.isSaveProfileSheetPresented = true
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 5)
                    }
                    
                    Text(viewModel.isSaving ? "Saving..." : "Save")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(viewModel.profileName.isEmpty || viewModel.isSaving)
        }
        .padding(.horizontal)
    }
    
    private var playButton: some View {
        Button {
            viewModel.togglePlayback()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, 30)
    }
    
    private var timerIndicator: some View {
        Group {
            if viewModel.isTimerActive {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    
                    Text("Sleep in \(formatTime(viewModel.remainingTime))")
                        .foregroundColor(.orange)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private var saveProfileSheet: some View {
        VStack(spacing: 20) {
            Text("Save Noise Profile")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Profile Name", text: $viewModel.profileName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button {
                viewModel.saveProfile()
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 5)
                    }
                    
                    Text(viewModel.isSaving ? "Saving..." : "Save")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(viewModel.profileName.isEmpty || viewModel.isSaving)
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    // Preview with mock audio manager
    NoiseGeneratorFeatureView()
} 