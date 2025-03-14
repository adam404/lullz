//
//  FloatingVolumeControl.swift
//  Lullz
//
//  Created by Adam Scott on 3/12/25.
//

import SwiftUI
import UIKit

// IMPORTANT: To use this component correctly, you must apply the .withTypeErasedAudioManager()
// modifier after applying the .environmentObject(audioManager) modifier to wrap the 
// AudioManager in an AnyAudioController.
//
// Example:
//   YourView()
//     .environmentObject(yourAudioManager)
//     .withTypeErasedAudioManager()
//
// This view expects an AnyAudioController in the environment, not a direct AudioManager

struct FloatingVolumeControl: View {
    @StateObject private var viewModel: FloatingVolumeControlViewModel
    
    @State private var isExpanded = false
    @State private var isDragging = false
    
    // Animation properties
    @State private var opacity = 0.7
    @State private var scale: CGFloat = 1.0
    
    private let buttonSize: CGFloat = 50
    private let expandedWidth: CGFloat = 200
    
    init(audioManager: Any) {
        _viewModel = StateObject(wrappedValue: FloatingVolumeControlViewModel(audioManager: audioManager))
    }
    
    var body: some View {
        HStack(spacing: 10) {
            if isExpanded {
                // Mute/unmute button
                Button(action: {
                    viewModel.toggleMute()
                    
                    // Provide haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // Auto-collapse after a delay
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        // Keep expanded if user is still adjusting
                        if !isDragging {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                if !isDragging {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        isExpanded = false
                                    }
                                }
                            }
                        }
                    }
                }) {
                    Image(systemName: viewModel.volume > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: buttonSize - 10, height: buttonSize - 10)
                }
                
                // Volume slider
                Slider(
                    value: Binding(
                        get: { Double(viewModel.volume) },
                        set: { viewModel.setVolume(Float($0)) }
                    ),
                    in: 0...1,
                    onEditingChanged: { editing in
                        isDragging = editing
                        if !editing {
                            // Auto-collapse after adjusting
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isExpanded = false
                                }
                            }
                        }
                    }
                )
                .accentColor(Color.white)
                .frame(width: expandedWidth - buttonSize - 20)
            }
            
            // Main volume button that's always visible
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isExpanded.toggle()
                }
                
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // Auto-collapse after a delay if expanded
                if isExpanded {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if !isDragging && isExpanded {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isExpanded = false
                            }
                        }
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.8))
                        .frame(width: buttonSize, height: buttonSize)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    
                    Image(systemName: viewModel.isPlaying ? 
                          (viewModel.volume <= 0 ? "speaker.slash.fill" : "speaker.wave.2.fill") : 
                          "speaker.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(scale)
            .onAppear {
                // Subtle breathing animation for discoverability
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scale = 1.05
                }
            }
        }
        .padding(isExpanded ? 10 : 0)
        .background(isExpanded ? 
                   Color.gray.opacity(0.8) : 
                   Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .frame(width: isExpanded ? expandedWidth : buttonSize)
        .opacity(opacity)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isExpanded)
        #if os(macOS)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                opacity = hovering ? 1.0 : 0.7
            }
        }
        #endif
    }
}

// Add RoundedCorner shape for nice visuals
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    // Add a custom hover effect for SwiftUI. On iOS, hover is not supported so we return self.
    func onHover(_ perform: @escaping (Bool) -> Void) -> some View {
        #if os(iOS)
        return self
        #else
        return self.onHover(perform: perform)
        #endif
    }
}

// For preview purposes only
extension AnyAudioController {
    static var preview: AnyAudioController {
        let previewController = PreviewAudioController()
        return AnyAudioController(previewController)
    }
    
    private class PreviewAudioController: AudioControllerProtocol, ObservableObject {
        var volume: Double = 0.7
        var isPlaying: Bool = false
        
        func toggleMute() {
            // Mock implementation
        }
    }
}

#Preview {
    FloatingVolumeControl(audioManager: AnyAudioController.preview)
        .padding(50)
        .background(Color.black.opacity(0.1))
} 