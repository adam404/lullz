//
//  AudioManagerTypes.swift
//  Lullz
//
//  Created by Cursor on behalf of Adam Scott
//

import Foundation
import SwiftUI
import Combine

// Define the audio manager protocol to avoid ambiguity
public protocol AudioControllerProtocol {
    var volume: Double { get set }
    var isPlaying: Bool { get }
    func toggleMute()
}

// Create a type eraser for AudioManager
public final class AnyAudioController: ObservableObject {
    @Published public var volume: Double
    @Published public var isPlaying: Bool
    
    private let _toggleMute: () -> Void
    private var cancellables = Set<AnyCancellable>()
    
    public init<T: AudioControllerProtocol & ObservableObject>(_ audioController: T) {
        self.volume = audioController.volume
        self.isPlaying = audioController.isPlaying
        self._toggleMute = audioController.toggleMute
        
        // Observe the audioController
        audioController.objectWillChange
            .sink { [weak self] _ in
                self?.volume = audioController.volume
                self?.isPlaying = audioController.isPlaying
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    public func toggleMute() {
        _toggleMute()
    }
}

// Add extension to make AudioManager conform to our protocol
extension AudioManagerImpl: AudioControllerProtocol { }

// MARK: - View Modifiers and Extensions

// Add convenient extension to View for type erasure
extension View {
    func withTypeErasedAudioManager(_ audioManager: AudioManagerImpl) -> some View {
        modifier(TypeErasedAudioControllerModifier())
            .environment(\.typeErasedAudioController, AnyAudioController(audioManager))
    }
}

// Environment key for type-erased audio controller
private struct AnyAudioControllerKey: EnvironmentKey {
    static let defaultValue: AnyAudioController? = nil
}

extension EnvironmentValues {
    var typeErasedAudioController: AnyAudioController? {
        get { self[AnyAudioControllerKey.self] }
        set { self[AnyAudioControllerKey.self] = newValue }
    }
}

// A modifier that provides access to the type-erased audio controller
public struct TypeErasedAudioControllerModifier: ViewModifier {
    @Environment(\.typeErasedAudioController) private var typeErasedController
    
    public func body(content: Content) -> some View {
        if let controller = typeErasedController {
            content.environmentObject(controller)
        } else {
            content
        }
    }
} 