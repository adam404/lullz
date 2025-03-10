//
//  BreathingPatternEditorView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct BreathingPatternEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var steps: [BreathStep] = [
        BreathStep(phase: .inhale, durationSeconds: 4),
        BreathStep(phase: .exhale, durationSeconds: 4)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pattern Information")) {
                    TextField("Name", text: $name)
                    
                    TextField("Description", text: $description)
                        .lineLimit(3)
                }
                
                Section(header: Text("Breathing Steps")) {
                    ForEach(steps.indices, id: \.self) { index in
                        HStack {
                            Picker("", selection: $steps[index].phase) {
                                ForEach(BreathPhase.allCases, id: \.self) { phase in
                                    Text(phase.rawValue).tag(phase)
                                }
                            }
                            .frame(width: 150)
                            
                            Spacer()
                            
                            Stepper(
                                "\(Int(steps[index].durationSeconds))s",
                                value: Binding(
                                    get: { steps[index].durationSeconds },
                                    set: { steps[index].durationSeconds = $0 }
                                ),
                                in: 1...20,
                                step: 1
                            )
                        }
                    }
                    .onDelete(perform: deleteStep)
                    
                    Button("Add Step") {
                        withAnimation {
                            steps.append(BreathStep(phase: .inhale, durationSeconds: 4))
                        }
                    }
                }
                
                Section(header: Text("Preview")) {
                    VStack(alignment: .leading) {
                        Text("One cycle: \(cycleDuration) seconds")
                            .font(.callout)
                        
                        Text("Pattern: ")
                            .font(.callout) +
                        Text(patternDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Create Pattern")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    savePattern()
                    dismiss()
                }
                .disabled(name.isEmpty || steps.isEmpty)
            )
        }
    }
    
    private var cycleDuration: String {
        let totalSeconds = steps.reduce(0) { $0 + $1.durationSeconds }
        
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)"
        }
    }
    
    private var patternDescription: String {
        steps.map { "\($0.phase.rawValue.prefix(1))-\(Int($0.durationSeconds))" }.joined(separator: ", ")
    }
    
    private func deleteStep(at offsets: IndexSet) {
        // Don't allow deleting all steps
        if steps.count > offsets.count {
            steps.remove(atOffsets: offsets)
        }
    }
    
    private func savePattern() {
        let pattern = BreathingPattern(
            name: name,
            description: description,
            steps: steps
        )
        
        modelContext.insert(pattern)
    }
} 