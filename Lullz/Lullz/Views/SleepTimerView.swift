//
//  SleepTimerView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct SleepTimerView: View {
    @EnvironmentObject var audioManager: AudioManagerImpl
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDuration: TimeInterval
    @State private var timeRemaining: TimeInterval?
    @State private var timer: Timer?
    @State private var isTimerActive: Bool = false
    @State private var timerStartTime: Date?
    @State private var timerEndTime: Date?
    
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
        // Use a default value
        _selectedDuration = State(initialValue: 30 * 60) // 30 minutes
        _timeRemaining = State(initialValue: nil)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Display active timer or duration selection
                if let remaining = timeRemaining, isTimerActive {
                    activeTimerView(remaining: remaining)
                } else {
                    durationSelectionView()
                }
                
                // Timer controls
                if isTimerActive {
                    Button(action: {
                        cancelSleepTimer()
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
                        startSleepTimer(duration: selectedDuration)
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
                checkExistingTimer()
            }
            .onDisappear {
                // Keep the timer running but stop our local updates
                timer?.invalidate()
            }
        }
    }
    
    private func activeTimerView(remaining: TimeInterval) -> some View {
        VStack(spacing: 20) {
            Text("Sleep Timer Active")
                .font(.headline)
            
            VStack {
                Text(formatTimeInterval(remaining))
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                if let endTime = timerEndTime {
                    Text("Music will stop at \(formatTime(endTime))")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 20)
            
            Text("The audio will automatically stop when the timer reaches zero.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private func durationSelectionView() -> some View {
        VStack(spacing: 15) {
            Text("Select Duration")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(durations, id: \.self) { duration in
                    Button(action: {
                        selectedDuration = duration
                    }) {
                        Text(formatTimeInterval(duration))
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(duration == selectedDuration 
                                          ? Color.accentColor 
                                          : Color.secondary.opacity(0.2))
                    )
                    .foregroundColor(duration == selectedDuration ? .white : .primary)
                }
            }
        }
    }
    
    // Sleep timer functionality
    private func startSleepTimer(duration: TimeInterval) {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(duration)
        
        timerStartTime = startTime
        timerEndTime = endTime
        isTimerActive = true
        
        // Calculate initial remaining time
        updateTimeRemaining()
        
        // Start the timer
        startUpdateTimer()
        
        // Schedule the actual stop action
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if self.isTimerActive {
                self.audioManager.stopSound()
                self.isTimerActive = false
                self.timeRemaining = nil
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }
    
    private func cancelSleepTimer() {
        isTimerActive = false
        timeRemaining = nil
        timerStartTime = nil
        timerEndTime = nil
        timer?.invalidate()
        timer = nil
    }
    
    private func checkExistingTimer() {
        // Since we're not using AudioManager's built-in sleep timer,
        // we just need to check our local state
        if isTimerActive {
            updateTimeRemaining()
            startUpdateTimer()
        }
    }
    
    private func updateTimeRemaining() {
        if let endTime = timerEndTime, isTimerActive {
            let now = Date()
            let remaining = endTime.timeIntervalSince(now)
            
            if remaining > 0 {
                timeRemaining = remaining
            } else {
                cancelSleepTimer()
            }
        } else {
            timeRemaining = nil
        }
    }
    
    private func startUpdateTimer() {
        timer?.invalidate()
        
        if isTimerActive {
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
            .environmentObject(AudioManagerImpl())
    }
} 