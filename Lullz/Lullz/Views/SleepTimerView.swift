//
//  SleepTimerView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct SleepTimerView: View {
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDuration: TimeInterval
    @State private var timeRemaining: TimeInterval?
    @State private var timer: Timer?
    
    // Preset durations
    private let durations: [TimeInterval] = [
        5 * 60,    // 5 minutes
        15 * 60,   // 15 minutes
        30 * 60,   // 30 minutes
        45 * 60,   // 45 minutes
        60 * 60,   // 1 hour
        90 * 60,   // 1.5 hours
        120 * 60,  // 2 hours
        180 * 60,  // 3 hours
        240 * 60,  // 4 hours
        480 * 60   // 8 hours
    ]
    
    init() {
        // Initialize with the audio manager's current duration setting
        _selectedDuration = State(initialValue: AudioManager().sleepTimerDuration)
        _timeRemaining = State(initialValue: nil)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Display active timer or duration selection
                if let remaining = timeRemaining, audioManager.sleepTimerActive {
                    activeTimerView(remaining: remaining)
                } else {
                    durationSelectionView()
                }
                
                // Timer controls
                if audioManager.sleepTimerActive {
                    Button(action: {
                        audioManager.cancelSleepTimer()
                        timeRemaining = nil
                    }) {
                        Text("Cancel Timer")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    Button(action: {
                        audioManager.sleepTimerDuration = selectedDuration
                        audioManager.startSleepTimer()
                        updateTimeRemaining()
                        startUpdateTimer()
                    }) {
                        Text("Start Timer")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                // Fade effects explanation
                Group {
                    Divider()
                    
                    Text("Sleep Timer Behavior")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("The sleep timer will automatically stop audio playback after the selected duration. Perfect for falling asleep without worrying about turning off the app manually.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sleep Timer")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .onAppear {
                // Check if timer is already active
                updateTimeRemaining()
                startUpdateTimer()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func activeTimerView(remaining: TimeInterval) -> some View {
        VStack(spacing: 20) {
            Text("Timer Active")
                .font(.headline)
                .foregroundColor(.accentColor)
            
            Text(formatTimeInterval(remaining))
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit()
            
            Text("Remaining")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Sound will stop playing at \(formatTime(Date().addingTimeInterval(remaining)))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)
    }
    
    private func durationSelectionView() -> some View {
        VStack(spacing: 15) {
            Text("Select Duration")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(durations, id: \.self) { duration in
                    Button {
                        selectedDuration = duration
                    } label: {
                        Text(formatTimeInterval(duration))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(duration == selectedDuration 
                                          ? Color.accentColor 
                                          : Color.secondary.opacity(0.2))
                            )
                            .foregroundColor(duration == selectedDuration ? .white : .primary)
                    }
                }
            }
        }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = audioManager.timeRemainingOnSleepTimer()
    }
    
    private func startUpdateTimer() {
        timer?.invalidate()
        
        if audioManager.sleepTimerActive {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateTimeRemaining()
            }
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SleepTimerView_Previews: PreviewProvider {
    static var previews: some View {
        SleepTimerView()
            .environmentObject(AudioManager())
    }
} 