//
//  ActiveTimerIndicatorView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct ActiveTimerIndicatorView: View {
    @EnvironmentObject var audioManager: AudioManagerImpl
    
    // Since AudioManagerImpl doesn't have sleep timer functionality built-in,
    // we'll use these properties to control the timer from outside
    var isTimerActive: Bool
    var remainingTime: TimeInterval
    var onTimerUpdate: (() -> Void)?
    
    @State private var timer: Timer?
    
    var body: some View {
        Group {
            if isTimerActive {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption)
                    Text(formatTime(remainingTime))
                        .font(.caption)
                        .monospacedDigit()
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(12)
                .onAppear {
                    startTimer()
                }
                .onDisappear {
                    timer?.invalidate()
                }
            }
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            onTimerUpdate?()
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct ActiveTimerIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveTimerIndicatorView(
            isTimerActive: true,
            remainingTime: 305, // 5 minutes and 5 seconds
            onTimerUpdate: nil
        )
        .environmentObject(AudioManagerImpl())
        .previewLayout(.sizeThatFits)
        .padding()
    }
} 