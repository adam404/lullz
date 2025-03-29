//
//  InformationView.swift
//  Lullz
//
//  Created by Adam Scott on 3/9/25.
//

import SwiftUI

struct InformationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Break down complex expressions into smaller parts
                    aboutSection
                    
                    noiseTypesSection
                    
                    featuresSection
                    
                    creditsSection
                }
                .padding()
            }
            .navigationTitle("About Lullz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Break down the complex view into smaller components
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About Lullz")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Lullz is a noise generator app designed to help you focus, relax, or sleep better. It generates various types of noise that can mask distracting sounds in your environment.")
                .font(.body)
        }
    }
    
    private var noiseTypesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Noise Types")
                .font(.title2)
                .fontWeight(.bold)
            
            Group {
                noiseTypeDescription(
                    title: "White Noise",
                    description: "Equal energy across all frequencies. Good for masking a variety of sounds."
                )
                
                noiseTypeDescription(
                    title: "Pink Noise",
                    description: "Energy decreases as frequency increases. Sounds more natural and is often preferred for sleep."
                )
                
                noiseTypeDescription(
                    title: "Brown Noise",
                    description: "Energy decreases more rapidly at higher frequencies. Deep, rich sound similar to rainfall or ocean waves."
                )
                
                noiseTypeDescription(
                    title: "Blue Noise",
                    description: "Energy increases with frequency. Can help with focus and concentration."
                )
                
                noiseTypeDescription(
                    title: "Violet Noise",
                    description: "Energy increases more rapidly with frequency. May help with tinnitus masking."
                )
            }
            
            Group {
                noiseTypeDescription(
                    title: "Grey Noise",
                    description: "Psychoacoustically flat noise, engineered to sound equally loud at all frequencies to human ears."
                )
                
                noiseTypeDescription(
                    title: "Green Noise",
                    description: "Focuses on the middle of the audible spectrum. Resembles the ambient sounds of nature."
                )
                
                noiseTypeDescription(
                    title: "Black Noise",
                    description: "Minimal noise with occasional random sounds. Good for deep focus and meditation."
                )
            }
        }
    }
    
    private func noiseTypeDescription(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Features")
                .font(.title2)
                .fontWeight(.bold)
            
            featureItem("Multiple noise types for different needs")
            featureItem("Timer functionality for auto-shutdown")
            featureItem("Background audio playback")
            featureItem("Customizable volume and balance")
            featureItem("Save and load favorite settings")
        }
    }
    
    private func featureItem(_ text: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(text)
                .font(.body)
        }
    }
    
    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Credits")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Developed by Adam Scott")
                .font(.body)
            
            Text("Version 1.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    InformationView()
}
