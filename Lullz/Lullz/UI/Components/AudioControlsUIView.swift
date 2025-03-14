//
//  AudioControlsUIView.swift
//  Lullz
//
//  Created by Adam Scott
//

import SwiftUI
import Combine

/// A reusable audio controls component with customizable parameters
struct AudioControlsUIComponent: View {
    // MARK: - Properties
    
    // Bindings to control audio state
    @Binding var volume: Double
    @Binding var balance: Double
    @Binding var lowPassCutoff: Double?
    @Binding var highPassCutoff: Double?
    @Binding var isPlaying: Bool
    @Binding var isMuted: Bool
    
    // Optional parameters
    var showBalanceControl: Bool = true
    var showMuteButton: Bool = true
    var tintColor: Color = .white
    var darkMode: Bool = true
    
    // Action closures
    var onPlayPause: () -> Void
    var onVolumeChange: ((Double) -> Void)?
    var onBalanceChange: ((Double) -> Void)?
    var onMuteToggle: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            // Volume control
            volumeControl
            
            // Balance control (optional)
            if showBalanceControl {
                balanceControl
            }
            
            // Play/Pause and Mute buttons
            HStack(spacing: 20) {
                // Play/Pause button
                playPauseButton
                
                // Mute button (optional)
                if showMuteButton {
                    muteButton
                }
            }
            .padding(.top, 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(darkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Subviews
    
    private var volumeControl: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "speaker.wave.1.fill")
                    .foregroundColor(tintColor)
                
                Slider(value: Binding(
                    get: { volume },
                    set: { newValue in
                        volume = newValue
                        onVolumeChange?(newValue)
                    }
                ), in: 0...1, step: 0.01)
                .accentColor(tintColor)
                
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(tintColor)
            }
            
            Text("\(Int(volume * 100))%")
                .font(.caption)
                .foregroundColor(tintColor.opacity(0.8))
        }
    }
    
    private var balanceControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("L")
                    .font(.caption)
                    .foregroundColor(tintColor)
                
                Slider(value: Binding(
                    get: { balance },
                    set: { newValue in
                        balance = newValue
                        onBalanceChange?(newValue)
                    }
                ), in: 0...1, step: 0.01)
                .accentColor(tintColor)
                
                Text("R")
                    .font(.caption)
                    .foregroundColor(tintColor)
            }
            
            Text("Balance")
                .font(.caption)
                .foregroundColor(tintColor.opacity(0.8))
        }
    }
    
    private var playPauseButton: some View {
        Button(action: onPlayPause) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 24))
                .foregroundColor(tintColor)
                .padding()
                .background(Circle().fill(tintColor.opacity(0.15)))
                .frame(width: 60, height: 60)
        }
        .buttonStyle(LullzScaleButtonStyle())
    }
    
    private var muteButton: some View {
        Button(action: {
            isMuted.toggle()
            onMuteToggle?()
        }) {
            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 20))
                .foregroundColor(isMuted ? .orange : tintColor)
                .padding()
                .background(Circle().fill(tintColor.opacity(0.15)))
                .frame(width: 50, height: 50)
        }
        .buttonStyle(LullzScaleButtonStyle())
    }
}

#Preview {
    VStack {
        AudioControlsUIComponent(
            volume: .constant(0.7),
            balance: .constant(0.5),
            lowPassCutoff: .constant(nil),
            highPassCutoff: .constant(nil),
            isPlaying: .constant(false),
            isMuted: .constant(false),
            onPlayPause: {},
            onVolumeChange: { _ in },
            onBalanceChange: { _ in },
            onMuteToggle: {}
        )
        
        AudioControlsUIComponent(
            volume: .constant(0.5),
            balance: .constant(0.5),
            lowPassCutoff: .constant(nil),
            highPassCutoff: .constant(nil),
            isPlaying: .constant(true),
            isMuted: .constant(true),
            showBalanceControl: false,
            tintColor: .blue,
            darkMode: false,
            onPlayPause: {},
            onVolumeChange: { _ in },
            onMuteToggle: {}
        )
        .padding(.top, 20)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 