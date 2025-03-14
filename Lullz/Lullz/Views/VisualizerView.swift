//
//  VisualizerView.swift
//  Lullz
//
//  Created by Adam Scott on 3/9/25.
//

import SwiftUI

enum VisualizationType: String, CaseIterable, Identifiable {
    case dynamic = "Dynamic"
    case spectrum = "Spectrum"
    case waveform = "Waveform"
    case circular = "Circular"
    case none = "None"
    
    var id: String { self.rawValue }
}

struct VisualizerView: View {
    @EnvironmentObject var audioManager: AudioManagerImpl
    @AppStorage("visualizerType") private var visualizerType: VisualizationType = .dynamic
    @State private var showingVisTypeSelection = false
    
    var body: some View {
        VStack {
            if visualizerType != .none, audioManager.isPlaying {
                VStack(spacing: 5) {
                    // Visualization container with improved styling
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.8))
                            .shadow(radius: 5)
                        
                        // Visualization content
                        if visualizerType == .dynamic {
                            DynamicWaveVisualizer(noiseType: audioManager.currentNoiseType)
                                .padding(.horizontal, 10)
                        } else if let visualizer = audioManager.visualizer {
                            visualizationContent(for: visualizerType, visualizer: visualizer)
                                .padding(.horizontal, 10)
                        } else {
                            Text("Visualizer unavailable")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(height: 150)
                    .padding(.horizontal)
                    
                    // Type selector button
                    Button {
                        showingVisTypeSelection = true
                    } label: {
                        HStack {
                            Image(systemName: "waveform.circle")
                            Text(visualizerType.rawValue)
                            Image(systemName: "chevron.down.circle")
                                .font(.caption)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                        )
                    }
                    .padding(.bottom, 8)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: audioManager.isPlaying)
        .animation(.easeInOut, value: visualizerType)
        .confirmationDialog(
            "Select Visualization Type",
            isPresented: $showingVisTypeSelection
        ) {
            ForEach(VisualizationType.allCases) { type in
                Button(type.rawValue) {
                    visualizerType = type
                }
            }
        } message: {
            Text("Choose visualization style")
        }
        .onAppear {
            // Verify that AudioManagerImpl is provided
            print("VisualizerView received audioManager: \(audioManager)")
        }
    }
    
    @ViewBuilder
    private func visualizationContent(for type: VisualizationType, visualizer: SoundVisualizer) -> some View {
        switch type {
        case .dynamic:
            // This case is handled separately in the main view
            EmptyView()
        case .spectrum:
            SpectrumVisualizer(visualizer: visualizer, barCount: 64)
        case .waveform:
            WaveformVisualizer(visualizer: visualizer)
        case .circular:
            CircularVisualizer(visualizer: visualizer)
        case .none:
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        VisualizerView()
            .environmentObject(AudioManagerImpl.shared)
    }
} 