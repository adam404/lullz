//
//  BreathingPatternsView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI
import SwiftData

struct BreathingPatternsView: View {
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.modelContext) private var modelContext
    @Query private var patterns: [BreathingPattern]
    
    @State private var showingAddPattern = false
    @State private var showingExercise = false
    @State private var selectedPattern: BreathingPattern?
    
    var body: some View {
        NavigationStack {
            List {
                // Presets section
                Section(header: Text("Presets")) {
                    ForEach(patterns.filter { $0.isPreset }) { pattern in
                        patternRow(pattern)
                    }
                }
                
                // Custom patterns section
                Section(header: Text("My Patterns")) {
                    if patterns.filter({ !$0.isPreset }).isEmpty {
                        Text("You haven't created any custom breathing patterns yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(patterns.filter { !$0.isPreset }) { pattern in
                            patternRow(pattern)
                        }
                        .onDelete(perform: deletePatterns)
                    }
                }
            }
            .navigationTitle("Breathing Exercises")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddPattern = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPattern) {
                BreathingPatternEditorView()
            }
            .fullScreenCover(isPresented: $showingExercise) {
                if let pattern = selectedPattern {
                    BreathingExerciseView(pattern: pattern)
                        .environmentObject(audioManager)
                }
            }
            .onAppear {
                // Create default patterns if none exist
                if patterns.isEmpty {
                    createDefaultPatterns()
                }
            }
        }
    }
    
    private func patternRow(_ pattern: BreathingPattern) -> some View {
        Button {
            selectedPattern = pattern
            showingExercise = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.name)
                        .font(.headline)
                    
                    Text(pattern.patternDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        ForEach(pattern.steps) { step in
                            Text(step.phase.rawValue.prefix(1))
                                .font(.system(size: 10, weight: .bold))
                                .padding(4)
                                .background(Circle().fill(Color.secondary.opacity(0.2)))
                        }
                    }
                    .padding(.top, 2)
                }
                
                Spacer()
                
                Text(String(format: "%.0fs", pattern.cycleDuration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func deletePatterns(at offsets: IndexSet) {
        let customPatterns = patterns.filter { !$0.isPreset }
        for index in offsets {
            let pattern = customPatterns[index]
            modelContext.delete(pattern)
        }
    }
    
    private func createDefaultPatterns() {
        // 4-7-8 Breathing (Dr. Andrew Weil's technique)
        let fourSevenEight = BreathingPattern(
            name: "4-7-8 Breathing",
            description: "Helps reduce anxiety and aid sleep. Developed by Dr. Andrew Weil.",
            steps: [
                BreathStep(phase: .inhale, durationSeconds: 4),
                BreathStep(phase: .holdAfterInhale, durationSeconds: 7),
                BreathStep(phase: .exhale, durationSeconds: 8)
            ],
            isPreset: true
        )
        
        // Box Breathing (Navy SEAL technique)
        let boxBreathing = BreathingPattern(
            name: "Box Breathing",
            description: "Used by Navy SEALs for stress management and focus.",
            steps: [
                BreathStep(phase: .inhale, durationSeconds: 4),
                BreathStep(phase: .holdAfterInhale, durationSeconds: 4),
                BreathStep(phase: .exhale, durationSeconds: 4),
                BreathStep(phase: .holdAfterExhale, durationSeconds: 4)
            ],
            isPreset: true
        )
        
        // Relaxing Breath
        let relaxingBreath = BreathingPattern(
            name: "Relaxing Breath",
            description: "Gentle breathing pattern to promote relaxation and calm.",
            steps: [
                BreathStep(phase: .inhale, durationSeconds: 5),
                BreathStep(phase: .holdAfterInhale, durationSeconds: 2),
                BreathStep(phase: .exhale, durationSeconds: 7)
            ],
            isPreset: true
        )
        
        // Coherent Breathing
        let coherentBreathing = BreathingPattern(
            name: "Coherent Breathing",
            description: "Five breaths per minute to synchronize heart, lungs, and brain.",
            steps: [
                BreathStep(phase: .inhale, durationSeconds: 6),
                BreathStep(phase: .exhale, durationSeconds: 6)
            ],
            isPreset: true
        )
        
        // Diaphragmatic Breathing
        let diaphragmaticBreathing = BreathingPattern(
            name: "Diaphragmatic Breathing",
            description: "Deep belly breathing to activate the parasympathetic nervous system.",
            steps: [
                BreathStep(phase: .inhale, durationSeconds: 4),
                BreathStep(phase: .holdAfterInhale, durationSeconds: 1),
                BreathStep(phase: .exhale, durationSeconds: 6),
                BreathStep(phase: .holdAfterExhale, durationSeconds: 1)
            ],
            isPreset: true
        )
        
        // Add all patterns to the model context
        modelContext.insert(fourSevenEight)
        modelContext.insert(boxBreathing)
        modelContext.insert(relaxingBreath)
        modelContext.insert(coherentBreathing)
        modelContext.insert(diaphragmaticBreathing)
    }
} 