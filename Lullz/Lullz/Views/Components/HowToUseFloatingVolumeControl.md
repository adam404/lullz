# How to Use FloatingVolumeControl

The `FloatingVolumeControl` component provides a floating volume slider and mute button UI that can be easily added to any view in your app. It resolves the ambiguity issues with multiple `AudioManager` implementations by using a type-erased approach.

## Setup

1. Add the `withTypeErasedAudioManager()` modifier after the `environmentObject(_:)` modifier in your view hierarchy:

```swift
MainTabView()
    .environmentObject(audioManager)  // First provide the AudioManager
    .withTypeErasedAudioManager()     // Then wrap it in the type-erased container
    .withFloatingVolumeControl()      // Then add the floating control
    // Other modifiers...
```

## Implementation Details

The solution uses a type-eraser pattern:

1. `AudioControllerProtocol` - Defines the minimal interface needed for audio control (volume, isPlaying, toggleMute)
2. `AnyAudioController` - A type-erased wrapper that can contain any `AudioManager`
3. `AudioManagerTypeEraserModifier` - A view modifier that wraps the AudioManager in an AnyAudioController

## Benefits

- Resolves the ambiguity between different `AudioManager` implementations
- Provides a clean, well-defined interface for audio controls
- Avoids having to modify the existing `AudioManager` classes
- Follows Swift best practices for type erasure

## Usage Example

```swift
struct ContentView: View {
    @StateObject var audioManager = AudioManager()

    var body: some View {
        TabView {
            // Tab content here
        }
        .environmentObject(audioManager)
        .withTypeErasedAudioManager()
        .withFloatingVolumeControl()
    }
}
```
