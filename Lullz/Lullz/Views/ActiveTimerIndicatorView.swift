//
//  ActiveTimerIndicatorView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct ActiveTimerIndicatorView: View {
    @EnvironmentObject var audioManager: AudioManager
    @State private var timeRemaining: String = ""
    @State private var timer: Timer?
    
    var body: some View {
        Group {
            if audioManager.sleepTimerActive {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption)
                    Text(timeRemaining)
                        .font(.caption)
                        .monospacedDigit()
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(12)
                .onAppear {
                    updateTimeRemaining()
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
            updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        if let remaining = audioManager.timeRemainingOnSleepTimer() {
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            let seconds = Int(remaining) % 60
            
            if hours > 0 {
                timeRemaining = String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                timeRemaining = String(format: "%d:%02d", minutes, seconds)
            }
        }
    }
}

struct ActiveTimerIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        let audioManager = AudioManager()
        audioManager.sleepTimerActive = true
        audioManager.sleepTimerDuration = 30 * 60
        
        return ActiveTimerIndicatorView()
            .environmentObject(audioManager)
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 