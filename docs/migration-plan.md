# MVVM Architecture Migration Plan for Lullz App

This document outlines the step-by-step plan for migrating the Lullz app to a proper MVVM (Model-View-ViewModel) architecture according to iOS best practices.

## New Directory Structure

```
Lullz/
└── Lullz/
    ├── Features/ (Feature-specific modules)
    │   ├── SoundGeneration/ (White, Pink, Brown noise generation)
    │   │   ├── Views/
    │   │   │   └── NoiseGeneratorView.swift
    │   │   ├── ViewModels/
    │   │   │   └── NoiseGeneratorViewModel.swift
    │   │   └── Models/
    │   │       └── NoiseType.swift (enum and related types)
    │   ├── BinauralBeats/
    │   │   ├── Views/
    │   │   │   └── BinauralBeatsView.swift
    │   │   ├── ViewModels/
    │   │   │   └── BinauralBeatsViewModel.swift
    │   │   └── Models/
    │   │       └── BinauralPreset.swift (enums and related types)
    │   ├── Profiles/
    │   │   ├── Views/
    │   │   │   └── ProfilesView.swift
    │   │   ├── ViewModels/
    │   │   │   └── ProfilesViewModel.swift
    │   │   └── Models/
    │   │       └── NoiseProfile.swift
    │   ├── Visualization/
    │   │   ├── Views/
    │   │   │   └── VisualizerView.swift
    │   │   └── ViewModels/
    │   │       └── VisualizerViewModel.swift
    │   ├── BreathingExercises/
    │   │   ├── Views/
    │   │   │   ├── BreathingPatternsView.swift
    │   │   │   └── BreathingPatternEditorView.swift
    │   │   ├── ViewModels/
    │   │   │   └── BreathingViewModel.swift
    │   │   └── Models/
    │   │       └── BreathingPattern.swift
    │   └── SoundMixing/
    │       ├── Views/
    │       │   └── MixedEnvironmentView.swift
    │       ├── ViewModels/
    │       │   └── MixedEnvironmentViewModel.swift
    │       └── Models/
    │           └── MixedEnvironment.swift
    ├── Core/ (Core services and business logic)
    │   ├── Services/ (Foundational services)
    │   │   ├── AudioService.swift
    │   │   ├── BinauralService.swift
    │   │   └── VisualizerService.swift
    │   ├── Managers/ (Coordinating services)
    │   │   ├── AudioManager.swift
    │   │   ├── SubscriptionManager.swift
    │   │   └── MixedEnvironmentEngine.swift
    │   ├── Models/ (Shared model objects)
    │   │   └── SwiftDataModel.swift
    │   └── Utilities/ (Helper functions and extensions)
    │       └── Extensions/
    │           ├── ColorExtensions.swift
    │           └── ViewExtensions.swift
    ├── UI/ (Reusable UI components)
    │   ├── Components/ (Shared UI components)
    │   │   ├── AudioControlsView.swift
    │   │   ├── SleepTimerView.swift
    │   │   └── ActiveTimerIndicatorView.swift
    │   ├── Styles/ (SwiftUI styles for consistency)
    │   │   ├── ButtonStyles.swift
    │   │   └── TextStyles.swift
    │   └── Modifiers/ (SwiftUI ViewModifiers)
    │       └── CommonModifiers.swift
    └── Resources/ (Assets and configuration)
        ├── Fonts/
        ├── Sounds/
        ├── Assets.xcassets/
        ├── Info.plist
        └── Lullz.entitlements
```

## Migration Steps

### Phase 1: Create the New Structure and Relocate Files

1. Create the new directory structure
2. Move models to appropriate locations
   - Move models to Features/<Feature>/Models/ when feature-specific
   - Move shared models to Core/Models/
3. Refactor View files to follow MVVM:
   - Move each view to its appropriate feature directory
   - Create corresponding ViewModels for each View

### Phase 2: Implement ViewModels

For each feature, create a dedicated ViewModel that:

- Separates business logic from view code
- Handles data operations and transformations
- Manages state for the associated view
- Communicates with core services

Example ViewModel pattern:

```swift
// NoiseGeneratorViewModel.swift
import SwiftUI
import Combine

class NoiseGeneratorViewModel: ObservableObject {
    // Dependencies
    private let audioManager: AudioManager

    // Published properties for view binding
    @Published var noiseType: NoiseType = .white
    @Published var volume: Double = 0.7
    @Published var isPlaying: Bool = false

    // Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()

    init(audioManager: AudioManager) {
        self.audioManager = audioManager
        setupBindings()
    }

    private func setupBindings() {
        // Set up Combine publishers/subscribers
    }

    // Methods that implement business logic
    func togglePlayback() {
        if isPlaying {
            stopNoise()
        } else {
            playNoise()
        }
    }

    private func playNoise() {
        audioManager.playNoise(type: noiseType)
        isPlaying = true
    }

    private func stopNoise() {
        audioManager.stopAudio()
        isPlaying = false
    }

    func updateVolume(_ newVolume: Double) {
        volume = newVolume
        audioManager.volume = Float(newVolume)
    }
}
```

### Phase 3: Core Services Refactoring

1. Move audio-related functionality to Core/Services/ and Core/Managers/
2. Ensure services have clear responsibilities and APIs
3. Implement dependency injection for services

### Phase 4: UI Components Extraction

1. Identify reusable UI components from views
2. Move them to UI/Components/
3. Ensure they accept proper parameters and bindings

### Phase 5: Update App Entry Point and Navigation

1. Update LullzApp.swift to use the new structure
2. Refactor MainTabView.swift to use ViewModels
3. Ensure proper dependency injection throughout the app

### Phase 6: Testing and Refinement

1. Test all features for proper functionality
2. Address any issues with bindings or data flow
3. Optimize performance where needed

## Benefits of This Migration

1. **Clear Separation of Concerns**:

   - Views handle only presentation logic
   - ViewModels handle business logic and state
   - Models represent data structures

2. **Improved Testability**:

   - ViewModels can be unit tested independently
   - Dependency injection facilitates testing

3. **Better Maintainability**:

   - Smaller, focused files
   - Clear responsibilities
   - Easier to understand and modify

4. **Enhanced Collaboration**:

   - Team members can work on different features simultaneously
   - Clear boundaries between components

5. **Scalability**:
   - New features can be added without affecting existing code
   - Consistent pattern for all features
