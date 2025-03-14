# Lullz App MVVM Architecture Implementation

This document provides guidance on implementing MVVM (Model-View-ViewModel) architecture in the Lullz app according to iOS best practices.

## What is MVVM?

MVVM is an architectural pattern that separates an application into three distinct components:

1. **Model**: Represents the data and business logic of the application
2. **View**: Displays the UI and captures user input
3. **ViewModel**: Acts as an intermediary between the Model and View, handling view logic and state

## Directory Structure

The Lullz app has been structured according to the following MVVM-based organization:

```
Lullz/
└── Lullz/
    ├── Features/ (Feature-specific modules)
    │   ├── SoundGeneration/
    │   ├── BinauralBeats/
    │   ├── Profiles/
    │   ├── Visualization/
    │   ├── BreathingExercises/
    │   └── SoundMixing/
    ├── Core/ (Core services and business logic)
    │   ├── Services/
    │   ├── Managers/
    │   ├── Models/
    │   └── Utilities/
    ├── UI/ (Reusable UI components)
    │   ├── Components/
    │   ├── Styles/
    │   └── Modifiers/
    └── Resources/ (Assets and configuration)
        ├── Fonts/
        ├── Sounds/
        ├── Assets.xcassets/
        └── Configuration files
```

## Implementation Guidelines

### Models

- Models should be focused on data structure and business rules
- Use structs instead of classes when possible
- Implement Codable for serialization when needed
- Use SwiftData annotations for persistence

Example:

```swift
import SwiftData

@Model
class NoiseProfile {
    var id: UUID
    var name: String
    var noiseType: String
    var volume: Double
    var balance: Double
    var earDelay: Double
    var createdAt: Date

    init(name: String, noiseType: String, volume: Double, balance: Double, earDelay: Double) {
        self.id = UUID()
        self.name = name
        self.noiseType = noiseType
        self.volume = volume
        self.balance = balance
        self.earDelay = earDelay
        self.createdAt = Date()
    }
}
```

### ViewModels

- ViewModels should use `ObservableObject` and `@Published` properties
- Handle all business logic and data transformations
- Communicate with services via dependency injection
- Never import UIKit or access UI components directly

Example:

```swift
class NoiseGeneratorViewModel: ObservableObject {
    // Dependencies
    private let audioManager: AudioManager

    // Published properties for view binding
    @Published var selectedNoiseType: NoiseType = .white
    @Published var volume: Double = 0.7
    @Published var isPlaying: Bool = false

    // Initialization with dependency injection
    init(audioManager: AudioManager) {
        self.audioManager = audioManager
        setupBindings()
    }

    // Business logic methods
    func togglePlayback() {
        if isPlaying {
            stopNoise()
        } else {
            playNoise()
        }
    }

    // Private implementation details
    private func playNoise() {
        audioManager.playSound()
        isPlaying = true
    }
}
```

### Views

- Views should be declared using SwiftUI's struct-based approach
- Use `@StateObject` for owning ViewModels
- Use `@ObservedObject` for ViewModels passed from parent views
- Break complex views into smaller components using private properties or extracted view structs
- Views should only handle presentation logic, not business logic

Example:

```swift
struct NoiseGeneratorView: View {
    @StateObject private var viewModel: NoiseGeneratorViewModel

    init(audioManager: AudioManager? = nil) {
        let manager = audioManager ?? AudioManager.shared
        _viewModel = StateObject(wrappedValue: NoiseGeneratorViewModel(audioManager: manager))
    }

    var body: some View {
        VStack {
            headerView
            controlsSection
            playButton
        }
    }

    // Extracted view components
    private var headerView: some View {
        Text("Noise Generator")
            .font(.largeTitle)
    }
}
```

### Services and Managers

- Services should provide specific functionalities (e.g., AudioService)
- Managers coordinate between multiple services (e.g., AudioManager)
- Use protocol-based abstraction for testability
- Implement proper error handling using Result or throwing functions

Example:

```swift
protocol AudioServiceProtocol {
    func configureAudio(sampleRate: Double, channels: Int) throws
    func playSound() -> Bool
    func stopSound()
}

class AudioService: AudioServiceProtocol {
    // Implementation details
}
```

## Migration Checklist

When migrating existing code to the MVVM pattern, follow this checklist:

1. **Identify Models**:

   - ✅ What data structures represent your app's domain?
   - ✅ Are they properly encapsulated with clear interfaces?

2. **Extract ViewModels**:

   - ✅ Move business logic from views to view models
   - ✅ Ensure view models don't reference UIKit/SwiftUI directly
   - ✅ Use @Published for properties that affect the UI

3. **Refactor Views**:

   - ✅ Make views focused only on displaying UI elements
   - ✅ Use bindings to connect to view model properties
   - ✅ Break large views into smaller components

4. **Implement Dependency Injection**:

   - ✅ Avoid singletons when possible
   - ✅ Pass dependencies through initializers
   - ✅ Use protocols for service abstractions

5. **Test Your Components**:
   - ✅ Write unit tests for view models
   - ✅ Mock dependencies for isolated testing
   - ✅ Create UI tests for views

## Example Implementation

The SoundGeneration feature has been implemented as an example:

- `Features/SoundGeneration/Models/` contains noise-related models
- `Features/SoundGeneration/ViewModels/NoiseGeneratorViewModel.swift` manages state and logic
- `Features/SoundGeneration/Views/NoiseGeneratorView.swift` handles UI presentation

Use this implementation as a reference when migrating other features to MVVM.

## Best Practices

1. **State Management**:

   - Use @Published for view model properties
   - Leverage Combine for more complex state management
   - Consider using @Observable macro (iOS 17+) for simpler cases

2. **SwiftUI Integration**:

   - Use .environmentObject for shared dependencies
   - Use @StateObject for view-owned view models
   - Use @ObservedObject for view models passed from parent views

3. **Code Organization**:

   - Keep files focused and sized appropriately (< 400 lines)
   - Use MARK: comments to organize sections within files
   - Use extensions to group related functionality

4. **Performance**:
   - Minimize view updates by structuring @Published properties carefully
   - Use @MainActor for UI-related code in async contexts
   - Implement proper memory management with weak references

## Additional Resources

- [Apple's SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Data Documentation](https://developer.apple.com/documentation/swiftdata)
- [Combine Framework Documentation](https://developer.apple.com/documentation/combine)
- [iOS-Application Best Practices](docs/iOS-Application-Best-Practices.md)
