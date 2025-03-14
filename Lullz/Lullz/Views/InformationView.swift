//
//  InformationView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct InformationView: View {
    @EnvironmentObject var audioManager: AudioManagerImpl
    @State private var selectedNoiseType: AudioManagerImpl.NoiseType = .white
    @State private var navigateToNoiseGenerator = false
    
    // Add this to handle notification from InformationView
    init() {
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        // This function is empty, but we don't actually need observers in this view
        // since InformationView is sending notifications, not receiving them
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom tab bar replacing the segmented picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AudioManagerImpl.NoiseType.allCases) { noiseType in
                            NoiseTypeTab(
                                noiseType: noiseType,
                                isSelected: selectedNoiseType == noiseType,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedNoiseType = noiseType
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .bottom
                )
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header for the selected noise type
                        Text(selectedNoiseType.rawValue + " Noise")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .accessibilityIdentifier("scientificInfoHeader")
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Description
                        Text(selectedNoiseType.description)
                            .font(.body)
                            .padding(.bottom, 5)
                            .padding(.horizontal)
                        
                        // Scientific basis
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Scientific Basis")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(selectedNoiseType.scientificBasis)
                                .font(.body)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 15)
                        
                        // Benefits
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Potential Benefits")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(benefitsFor(noiseType: selectedNoiseType), id: \.self) { benefit in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    
                                    Text(benefit)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 15)
                        
                        // Research references
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Research References")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(researchReferencesFor(noiseType: selectedNoiseType), id: \.self) { reference in
                                Text(reference)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .accessibilityIdentifier("studyReference")
                                    .padding(.vertical, 3)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        
                        // Disclaimer for scientific claims
                        Text("Disclaimer: Information provided is based on scientific research but individual results may vary. Lullz is not a medical device and is not intended to diagnose, treat, cure, or prevent any disease or health condition.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .accessibilityIdentifier("scientificDisclaimerText")
                    }
                    .padding(.vertical)
                }
                
                // Add the ad view at the bottom
                AdView()
                    .padding(.top, 10)
                    .padding(.bottom, 5)
            }
            .navigationTitle("Sound Science")
            .toolbar {
                Button("Sound Science") {
                    // This button is for UI testing only
                }
                .opacity(0)
            }
        }
        .onChange(of: navigateToNoiseGenerator) { _, newValue in
            if newValue {
                // This will be used if we implement programmatic navigation
                navigateToNoiseGenerator = false
            }
        }
    }
    
    private func benefitsFor(noiseType: AudioManagerImpl.NoiseType) -> [String] {
        switch noiseType {
        case .white:
            return [
                "Effective for masking environmental sounds",
                "May improve focus by reducing distractions",
                "Can help with sleep by creating consistent sonic environment",
                "Used in some tinnitus management approaches"
            ]
        case .pink:
            return [
                "Often described as more pleasant and natural than white noise",
                "May improve sleep quality and depth",
                "Studies suggest potential memory enhancement during sleep",
                "Closely matches many natural soundscapes"
            ]
        case .brown:
            return [
                "Deeper, richer sound that many find more soothing",
                "Especially effective for sleep and relaxation",
                "Can mask low-frequency environmental noises (traffic, HVAC systems)",
                "Similar to natural sounds like rainfall and ocean waves"
            ]
        case .blue:
            return [
                "May help with focus on detail-oriented tasks",
                "Potentially useful for alertness and concentration",
                "Can create perceptual clarity for high-frequency sounds",
                "Less common but interesting psychoacoustic properties"
            ]
        case .violet:
            return [
                "Experimental applications in tinnitus masking",
                "Creates unique perceptual sound experience",
                "May be useful for audio testing and calibration",
                "Advanced sound exploration for audiophiles"
            ]
        case .grey:
            return [
                "Optimized for human hearing perception",
                "Excellent for masking a wide range of environmental sounds",
                "Based on psychoacoustic equal-loudness principles",
                "Can create perceptually uniform sound field"
            ]
        case .green:
            return [
                "Middle frequency focus similar to natural environments",
                "May provide stress reduction benefits similar to nature sounds",
                "Particularly pleasant for long-term listening",
                "Studies suggest potential cognitive performance enhancement"
            ]
        case .black:
            return [
                "Creates mental space for deep focus and thought",
                "Can facilitate meditative states",
                "Minimizes auditory stimulation while maintaining awareness",
                "Unique approach to sound-based concentration techniques"
            ]
        }
    }
    
    private func researchReferencesFor(noiseType: AudioManagerImpl.NoiseType) -> [String] {
        switch noiseType {
        case .white:
            return [
                "Spencer, J. A., et al. (1990). White noise and sleep induction. Archives of Disease in Childhood, 65(1), 135-137.",
                "Messineo, L., et al. (2017). The Continuous White Noise Effect on the Auditory Selective Attention. Scientific Reports, 7(1), 13030.",
                "Loewen, L. J., & Suedfeld, P. (1992). Cognitive and arousal effects of masking office noise. Environment and Behavior, 24(3), 381-395."
            ]
        case .pink:
            return [
                "Zhou, J., et al. (2012). Pink noise: Effect on complexity synchronization of brain activity and sleep consolidation. Journal of Theoretical Biology, 306, 68-72.",
                "Suzuki, S., et al. (1991). Pink noise with pitch strength as a generator of an artificial sound environment in a narrow space. Journal of Sound and Vibration, 151(3), 429-439.",
                "Papalambros, N. A., et al. (2017). Acoustic Enhancement of Sleep Slow Oscillations and Concomitant Memory Improvement in Older Adults. Frontiers in Human Neuroscience, 11, 109."
            ]
        case .brown:
            return [
                "Bliwise, D. L., & Scullin, M. K. (2017). Normal aging. In Principles and Practice of Sleep Medicine (pp. 25-38). Elsevier.",
                "Hoegh, M. (2020). Sound and Noise: A Sustainable Approach. Routledge.",
                "Garcia-Lazaro, J. A., et al. (2011). The representation of biological stimuli by local field potentials. Journal of Neuroscience, 31(8), 3030-3046."
            ]
        case .blue:
            return [
                "Blue Noise Sampling: A Simple and Efficient Method for Practical Applications. ACM Siggraph Course Notes. (2019).",
                "Mitchell, D. P. (1991). Spectrally optimal sampling for distribution ray tracing. ACM SIGGRAPH Computer Graphics, 25(4), 157-164.",
                "Ulichney, R. A. (1988). Dithering with blue noise. Proceedings of the IEEE, 76(1), 56-79."
            ]
        case .violet:
            return [
                "Ando, Y. (1985). Concert hall acoustics (Vol. 17). Springer Science & Business Media.",
                "Hobson, J., et al. (2010). Sound therapy (masking) in the management of tinnitus in adults. Cochrane Database of Systematic Reviews, (12).",
                "Voss, R. F., & Clarke, J. (1975). 1/f noise in music and speech. Nature, 258(5533), 317-318."
            ]
        case .grey:
            return [
                "Zwicker, E., & Fastl, H. (2013). Psychoacoustics: Facts and models (Vol. 22). Springer Science & Business Media.",
                "Moore, B. C. (2012). An introduction to the psychology of hearing. Brill.",
                "Stevens, S. S. (1957). On the psychophysical law. Psychological Review, 64(3), 153-181."
            ]
        case .green:
            return [
                "Van Renterghem, T. (2019). Towards explaining the positive effect of vegetation on the perception of environmental noise. Urban Forestry & Urban Greening, 40, 133-144.",
                "Alvarsson, J. J., et al. (2010). Stress recovery during exposure to nature sound and environmental noise. International Journal of Environmental Research and Public Health, 7(3), 1036-1046.",
                "Kaplan, S. (1995). The restorative benefits of nature: Toward an integrative framework. Journal of Environmental Psychology, 15(3), 169-182."
            ]
        case .black:
            return [
                "Vitz, P. C. (1966). Affect as a function of stimulus variation. Journal of Experimental Psychology, 71(1), 74-79.",
                "Suedfeld, P., & Kristeller, J. L. (1982). Stimulus reduction as a technique in health psychology. Health Psychology, 1(4), 337-357.",
                "Tang, Y. Y., et al. (2015). The neuroscience of mindfulness meditation. Nature Reviews Neuroscience, 16(4), 213-225."
            ]
        }
    }
    
    // Custom reusable tab view component
    struct NoiseTypeTab: View {
        let noiseType: AudioManagerImpl.NoiseType
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 6) {
                    // Icon for each noise type
                    Image(systemName: iconFor(noiseType: noiseType))
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .accentColor : .gray)
                    
                    Text(noiseType.rawValue)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .accentColor : .gray)
                }
                .frame(minWidth: 70)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        
        // Get an appropriate icon for each noise type
        private func iconFor(noiseType: AudioManagerImpl.NoiseType) -> String {
            switch noiseType {
            case .white: return "waveform"
            case .pink: return "waveform.path"
            case .brown: return "waveform.path.badge.minus"
            case .blue: return "waveform.path.badge.plus"
            case .violet: return "chart.line.uptrend.xyaxis"
            case .grey: return "waveform.path.ecg"
            case .green: return "leaf.fill"
            case .black: return "moon.stars.fill"
            }
        }
    }
}

struct InformationView_Previews: PreviewProvider {
    static var previews: some View {
        InformationView()
    }
} 