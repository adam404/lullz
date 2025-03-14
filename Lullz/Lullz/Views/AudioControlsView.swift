import SwiftUI

struct AudioControlsView: View {
    @EnvironmentObject var audioManager: AudioManagerImpl
    var isPlaying: Bool
    var volume: Double
    var isMuted: Bool
    
    var onPlayPause: () -> Void
    var onVolumeChange: (Double) -> Void
    var onMuteToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Play/Pause Button
            Button(action: onPlayPause) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 44, height: 44)
                        .shadow(radius: 2)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Volume Slider with distinctive styling
            HStack {
                // Mute button
                Button(action: onMuteToggle) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.fill")
                        .foregroundColor(isMuted ? .secondary : .primary)
                        .frame(width: 24)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Volume slider with visual feedback
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)
                    
                    // Filled portion
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: max(0, CGFloat(volume) * UIScreen.main.bounds.width * 0.45), height: 6)
                }
                .frame(height: 20)
                .overlay(
                    Slider(value: Binding(get: {
                        volume
                    }, set: { newValue in
                        onVolumeChange(newValue)
                    }), in: 0...1)
                    .accentColor(.clear)
                    .opacity(0.01) // Make the slider invisible but functional
                )
                
                // Visual volume level indicator that doesn't look like a pause button
                Text("\(Int(volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// Usage example
#Preview {
    AudioControlsView(
        isPlaying: true,
        volume: 0.7,
        isMuted: false,
        onPlayPause: {},
        onVolumeChange: {_ in},
        onMuteToggle: {}
    )
    .environmentObject(AudioManagerImpl())
    .padding()
} 