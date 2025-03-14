//
//  AudioManagerShim.swift
//  Lullz
//
//  Created by Cursor on behalf of Adam Scott
//

// This file serves as a bridge to explicitly import the correct AudioManager implementation
// and re-export it with a clear name to avoid ambiguity issues

import Foundation
import SwiftUI

// This class provides standardized access to the AudioManagerImpl
class AudioManagerShim {
    static let shared = AudioManagerShim()
    
    // Provide a method to access the actual AudioManager
    static func getAudioManager() -> AudioManagerImpl {
        return AudioManagerImpl.shared
    }
} 