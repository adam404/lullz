//
//  MixedEnvironmentView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI
import SwiftData

struct MixedEnvironmentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.modelContext) private var modelContext
    @Query private var environments: [MixedEnvironment]
    
    @State private var selectedEnvironment: MixedEnvironment?
    @State private var isPlaying = false
    @State private var showingNewEnvironmentSheet = false
    @State private var showingEditSheet = false
    @State private var isLoading = true
    @State private var showingResetAlert = false
    
    private let mixedEngine = MixedEnvironmentEngine()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.8), Color.blue.opacity(0.3), Color.purple.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Content
                contentView
            }
            .navigationTitle("Sound Environments")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.7), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewEnvironmentSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .sheet(isPresented: $showingNewEnvironmentSheet) {
                MixedEnvironmentEditorView(mode: .create)
            }
            .sheet(isPresented: $showingEditSheet, onDismiss: {
                // Refresh selected environment if needed
            }) {
                if let environment = selectedEnvironment {
                    MixedEnvironmentEditorView(mode: .edit(environment))
                }
            }
            .sheet(item: $selectedEnvironment) { environment in
                EnvironmentPlayerView(environment: environment, mixedEngine: mixedEngine)
            }
            .onAppear {
                // Add a small delay to give time for the database to load
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isLoading = false
                }
                
                print("MixedEnvironmentView appeared, environments count: \(environments.count)")
                
                // Register for database reset completed notification
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("DatabaseResetComplete"),
                    object: nil,
                    queue: .main) { _ in
                        showingResetAlert = true
                    }
            }
            .alert("Database Reset", isPresented: $showingResetAlert) {
                Button("OK") { }
            } message: {
                Text("The database has been reset. Please restart the app to complete the process.")
            }
        }
    }
    
    // Break up the body into smaller components
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            loadingView
        } else if environments.isEmpty {
            emptyStateView
        } else {
            environmentGridView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Loading environments...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            SoundWaveView()
                .opacity(0.3)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.slash")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 10)
            
            Text("No Sound Environments Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("The app should automatically create some environments for you. If none appear, there might be a database issue.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // Request app to restart database
                NotificationCenter.default.post(name: Notification.Name("RequestDatabaseReset"), object: nil)
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reset Database")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding()
    }
    
    private var environmentGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                ForEach(environments) { environment in
                    EnvironmentCard(environment: environment)
                        .onTapGesture {
                            selectedEnvironment = environment
                        }
                }
            }
            .padding()
        }
    }
    
    private func formatLayerName(_ layer: SoundLayer) -> String {
        if layer.soundType.starts(with: "binaural") {
            return "Binaural: \(layer.binauralPreset ?? "Custom")"
        } else {
            // Format "white" as "White Noise"
            let name = layer.soundType.prefix(1).uppercased() + layer.soundType.dropFirst()
            return "\(name) Noise"
        }
    }
}

// Environment card component
struct EnvironmentCard: View {
    let environment: MixedEnvironment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                // Sound wave visualization
                SoundWaveThumbnail(soundType: primarySoundType)
                    .frame(height: 80)
                
                // Environment icon based on primary sound type
                HStack {
                    Image(systemName: iconForSoundType)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(environment.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(environment.layers.count) sound \(environment.layers.count == 1 ? "layer" : "layers")")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: colorForSoundType.0, saturation: colorForSoundType.1, brightness: 0.3),
                            Color(hue: colorForSoundType.0, saturation: colorForSoundType.1, brightness: 0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // Determine the primary sound type for this environment
    private var primarySoundType: String {
        let activeLayers = environment.layers.filter { $0.isActive }
        if let firstActive = activeLayers.first {
            return firstActive.soundType
        } else if let first = environment.layers.first {
            return first.soundType
        }
        return "white" // Default
    }
    
    // Choose icon based on sound type
    private var iconForSoundType: String {
        if primarySoundType.starts(with: "binaural") {
            return "waveform.path.ecg"
        }
        
        switch primarySoundType {
        case "white": return "cloud.fill"
        case "pink": return "leaf.fill"
        case "brown": return "water.waves"
        case "blue": return "sparkles"
        case "violet": return "hurricane"
        case "grey": return "cloud.rain.fill"
        case "green": return "leaf.circle.fill"
        case "black": return "moon.stars.fill"
        default: return "waveform"
        }
    }
    
    // Choose color based on sound type
    private var colorForSoundType: (Double, Double) { // (hue, saturation)
        if primarySoundType.starts(with: "binaural") {
            return (0.7, 0.7) // Purple
        }
        
        switch primarySoundType {
        case "white": return (0.6, 0.15) // Light blue/neutral
        case "pink": return (0.9, 0.6) // Pink
        case "brown": return (0.1, 0.6) // Brown/amber
        case "blue": return (0.55, 0.8) // Blue
        case "violet": return (0.8, 0.7) // Violet
        case "grey": return (0.0, 0.0) // Grey
        case "green": return (0.35, 0.7) // Green
        case "black": return (0.15, 0.3) // Dark
        default: return (0.5, 0.5) // Default blue
        }
    }
}

// Sound wave thumbnail for cards
struct SoundWaveThumbnail: View {
    let soundType: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(0.3)
            
            // Simple wave lines
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                        .offset(y: CGFloat(i * 5 - 5))
                }
            }
        }
    }
}

// Simple replacement for SoundWaveView
struct SoundWaveView: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(0.3)
    }
}

// Simple non-animated wave component
struct WaveLine: View {
    let index: Int
    
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.3))
            .frame(height: 1)
    }
}

// Button scale animation style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Editor view for creating and editing mixed environments
struct MixedEnvironmentEditorView: View {
    enum Mode {
        case create
        case edit(MixedEnvironment)
    }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let mode: Mode
    
    @State private var name: String = ""
    @State private var layers: [SoundLayer] = []
    @State private var showingAddLayerSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Environment Details")) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Sound Layers")) {
                    if layers.isEmpty {
                        Text("No layers added yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(layers.indices, id: \.self) { index in
                            HStack {
                                Toggle("", isOn: $layers[index].isActive)
                                
                                VStack(alignment: .leading) {
                                    Text(formatLayerName(layers[index]))
                                        .font(.headline)
                                    
                                    // Volume slider
                                    HStack {
                                        Image(systemName: "speaker.fill")
                                            .font(.caption)
                                        Slider(value: $layers[index].volume, in: 0...1)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    layers.remove(at: index)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    
                    Button {
                        showingAddLayerSheet = true
                    } label: {
                        Label("Add Sound Layer", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(mode.isCreate ? "New Environment" : "Edit Environment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEnvironment()
                        dismiss()
                    }
                    .disabled(name.isEmpty || layers.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddLayerSheet) {
                LayerSelectorView { newLayer in
                    layers.append(newLayer)
                }
            }
            .onAppear {
                if case .edit(let environment) = mode {
                    // Load existing environment data
                    name = environment.name
                    layers = environment.layers
                }
            }
        }
    }
    
    private func saveEnvironment() {
        switch mode {
        case .create:
            let newEnvironment = MixedEnvironment(
                name: name,
                description: "",
                layers: layers
            )
            modelContext.insert(newEnvironment)
            
        case .edit(let environment):
            environment.name = name
            environment.layers = layers
        }
    }
    
    private func formatLayerName(_ layer: SoundLayer) -> String {
        if layer.soundType.starts(with: "binaural") {
            return "Binaural: \(layer.binauralPreset ?? "Custom")"
        } else {
            let name = layer.soundType.prefix(1).uppercased() + layer.soundType.dropFirst()
            return "\(name) Noise"
        }
    }
}

extension MixedEnvironmentEditorView.Mode {
    var isCreate: Bool {
        if case .create = self { return true }
        return false
    }
}

// Layer selector for adding new sound layers
struct LayerSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    var onLayerSelected: (SoundLayer) -> Void
    
    @State private var selectedType = "noise"
    @State private var selectedNoiseType = "white"
    @State private var selectedBinauralPreset = "relaxation"
    @State private var volume: Float = 0.5
    @State private var balance: Float = 0.5
    @State private var selectedModulation: ModulationType = .none
    @State private var modulationRate: Float = 0.5
    @State private var modulationDepth: Float = 0.3
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Layer Type")) {
                    Picker("Sound Type", selection: $selectedType) {
                        Text("Noise").tag("noise")
                        Text("Binaural Beat").tag("binaural")
                    }
                    .pickerStyle(.segmented)
                }
                
                if selectedType == "noise" {
                    Section(header: Text("Noise Type")) {
                        Picker("Select", selection: $selectedNoiseType) {
                            Text("White").tag("white")
                            Text("Pink").tag("pink")
                            Text("Brown").tag("brown")
                            Text("Blue").tag("blue")
                            Text("Violet").tag("violet")
                            Text("Grey").tag("grey")
                            Text("Green").tag("green")
                            Text("Black").tag("black")
                        }
                        .pickerStyle(.wheel)
                    }
                } else {
                    Section(header: Text("Binaural Preset")) {
                        Picker("Select", selection: $selectedBinauralPreset) {
                            Text("Deep Relaxation").tag("relaxation")
                            Text("Enhanced Focus").tag("focus")
                            Text("Meditation").tag("meditation")
                            Text("Sleep Aid").tag("sleep")
                            Text("Creativity").tag("creativity")
                            Text("Hemi-Sync").tag("hemisync")
                        }
                        .pickerStyle(.wheel)
                    }
                }
                
                Section(header: Text("Volume & Balance")) {
                    VStack {
                        Text("Volume: \(Int(volume * 100))%")
                        Slider(value: $volume, in: 0...1)
                    }
                    
                    VStack {
                        Text("Balance: \(balance < 0.5 ? "Left" : balance > 0.5 ? "Right" : "Center") \(Int(abs(balance - 0.5) * 200))%")
                        Slider(value: $balance, in: 0...1)
                    }
                }
                
                Section(header: Text("Modulation Effects")) {
                    Picker("Effect Type", selection: $selectedModulation) {
                        Text("None").tag(ModulationType.none)
                        Text("Amplitude (Volume)").tag(ModulationType.amplitude)
                        Text("Frequency").tag(ModulationType.frequency)
                        Text("Spatial (Pan)").tag(ModulationType.spatial)
                    }
                    
                    if selectedModulation != .none {
                        VStack {
                            Text("Rate: \(String(format: "%.1f", modulationRate)) Hz")
                            Slider(value: $modulationRate, in: 0.05...2)
                        }
                        
                        VStack {
                            Text("Depth: \(Int(modulationDepth * 100))%")
                            Slider(value: $modulationDepth, in: 0.1...0.9)
                        }
                    }
                }
            }
            .navigationTitle("Add Sound Layer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let layer = createLayer()
                        onLayerSelected(layer)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createLayer() -> SoundLayer {
        let soundType: String
        var binauralPreset: String? = nil
        
        if selectedType == "noise" {
            soundType = selectedNoiseType
        } else {
            soundType = "binaural"
            binauralPreset = selectedBinauralPreset
        }
        
        return SoundLayer(
            soundType: soundType,
            volume: volume,
            balance: balance,
            isActive: true,
            binauralPreset: binauralPreset,
            modulation: selectedModulation == .none ? nil : selectedModulation,
            modulationRate: selectedModulation == .none ? nil : modulationRate,
            modulationDepth: selectedModulation == .none ? nil : modulationDepth
        )
    }
}

// Add a player view to handle playback
struct EnvironmentPlayerView: View {
    let environment: MixedEnvironment
    let mixedEngine: MixedEnvironmentEngine
    @State private var isPlaying = false
    @State private var animationActive = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.9),
                    Color(hue: colorForEnvironment.0, saturation: colorForEnvironment.1, brightness: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Animated sound waves (only when playing)
            if isPlaying {
                SoundWaveAnimationView()
                    .opacity(0.4)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 20) {
                // Title area
                VStack(spacing: 10) {
                    Text(environment.name)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if !environment.environmentDescription.isEmpty {
                        Text(environment.environmentDescription)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 30)
                
                // Environment icon
                Image(systemName: iconForEnvironment)
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 100, height: 100)
                    .background(
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hue: colorForEnvironment.0, saturation: colorForEnvironment.1, brightness: 0.6),
                                        Color(hue: colorForEnvironment.0, saturation: colorForEnvironment.1, brightness: 0.3)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 10)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .scaleEffect(animationActive ? 1.05 : 1.0)
                    .animation(
                        isPlaying ?
                            Animation.easeInOut(duration: 2).repeatForever(autoreverses: true) :
                            .default,
                        value: animationActive
                    )
                    .onAppear {
                        if isPlaying {
                            animationActive = true
                        }
                    }
                    .onChange(of: isPlaying) { newValue in
                        animationActive = newValue
                    }
                
                Spacer()
                
                // Layer list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(environment.layers) { layer in
                            LayerCard(layer: layer, isPlaying: isPlaying)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 300)
                
                Spacer()
                
                // Play button
                Button(action: {
                    if isPlaying {
                        mixedEngine.stopAllSounds()
                    } else {
                        mixedEngine.playEnvironment(environment)
                    }
                    isPlaying.toggle()
                }) {
                    ZStack {
                        // Breaking up the complex expression into simpler parts
                        let gradientColors: [Color] = [
                            Color.accentColor,
                            Color.accentColor.opacity(0.7)
                        ]
                        
                        let shadowColor = isPlaying ? 
                            Color.accentColor.opacity(0.5) : 
                            Color.black.opacity(0.3)
                        
                        let shadowRadius = isPlaying ? 15.0 : 5.0
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: gradientColors,
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
                        
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.bottom, 40)
            }
            .padding()
        }
        .onDisappear {
            // Stop playback when view disappears
            if isPlaying {
                mixedEngine.stopAllSounds()
                isPlaying = false
            }
        }
    }
    
    // Get primary sound type for the environment
    private var primarySoundType: String {
        let activeLayers = environment.layers.filter { $0.isActive }
        if let firstActive = activeLayers.first {
            return firstActive.soundType
        } else if let first = environment.layers.first {
            return first.soundType
        }
        return "white" // Default
    }
    
    // Choose icon based on environment's primary sound type
    private var iconForEnvironment: String {
        if primarySoundType.starts(with: "binaural") {
            return "waveform.path.ecg"
        }
        
        switch primarySoundType {
        case "white": return "cloud.fill"
        case "pink": return "leaf.fill"
        case "brown": return "water.waves"
        case "blue": return "sparkles"
        case "violet": return "hurricane"
        case "grey": return "cloud.rain.fill"
        case "green": return "leaf.circle.fill"
        case "black": return "moon.stars.fill"
        default: return "waveform"
        }
    }
    
    // Choose color based on environment's primary sound type
    private var colorForEnvironment: (Double, Double) { // (hue, saturation)
        if primarySoundType.starts(with: "binaural") {
            return (0.7, 0.7) // Purple
        }
        
        switch primarySoundType {
        case "white": return (0.6, 0.15) // Light blue/neutral
        case "pink": return (0.9, 0.6) // Pink
        case "brown": return (0.1, 0.6) // Brown/amber
        case "blue": return (0.55, 0.8) // Blue
        case "violet": return (0.8, 0.7) // Violet
        case "grey": return (0.0, 0.0) // Grey
        case "green": return (0.35, 0.7) // Green
        case "black": return (0.15, 0.3) // Dark
        default: return (0.5, 0.5) // Default blue
        }
    }
    
    private func formatLayerName(_ layer: SoundLayer) -> String {
        if layer.soundType.starts(with: "binaural") {
            return "Binaural: \(layer.binauralPreset ?? "Custom")"
        } else {
            let name = layer.soundType.prefix(1).uppercased() + layer.soundType.dropFirst()
            return "\(name) Noise"
        }
    }
}

// Layer card in the player view
struct LayerCard: View {
    let layer: SoundLayer
    let isPlaying: Bool
    
    var body: some View {
        HStack {
            // Layer icon
            Image(systemName: iconForLayer)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(layerBackgroundColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatLayerName(layer))
                    .font(.headline)
                    .foregroundColor(layer.isActive ? .white : .gray)
                
                if layer.modulation != nil && layer.modulation != .none {
                    Text("Modulation: \(layer.modulation?.rawValue.capitalized ?? "None")")
                        .font(.caption)
                        .foregroundColor(layer.isActive ? .white.opacity(0.7) : .gray.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Volume indicator
            HStack(spacing: 2) {
                ForEach(0..<5) { i in
                    Rectangle()
                        .fill(rectangleColor(for: i))
                        .frame(width: 3, height: 8 + CGFloat(i) * 3)
                        .cornerRadius(1)
                }
            }
            .padding(.horizontal, 8)
            
            // Active indicator
            Circle()
                .fill(indicatorColor)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .overlay(
            Group {
                if layer.isActive && isPlaying {
                    LayerWaveAnimation(layer: layer)
                        .mask(
                            RoundedRectangle(cornerRadius: 12)
                        )
                        .opacity(0.3)
                }
            }
        )
    }
    
    // Helper computed property to simplify the complex expression
    private var layerBackgroundColor: Color {
        if layer.isActive {
            return Color(hue: colorForLayer.0, saturation: colorForLayer.1, brightness: 0.6)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    // Choose icon based on layer's sound type
    private var iconForLayer: String {
        if layer.soundType.starts(with: "binaural") {
            return "waveform.path.ecg"
        }
        
        switch layer.soundType {
        case "white": return "cloud.fill"
        case "pink": return "leaf.fill"
        case "brown": return "water.waves"
        case "blue": return "sparkles"
        case "violet": return "hurricane"
        case "grey": return "cloud.rain.fill"
        case "green": return "leaf.circle.fill"
        case "black": return "moon.stars.fill"
        default: return "waveform"
        }
    }
    
    // Choose color based on layer's sound type
    private var colorForLayer: (Double, Double) { // (hue, saturation)
        if layer.soundType.starts(with: "binaural") {
            return (0.7, 0.7) // Purple
        }
        
        switch layer.soundType {
        case "white": return (0.6, 0.15) // Light blue/neutral
        case "pink": return (0.9, 0.6) // Pink
        case "brown": return (0.1, 0.6) // Brown/amber
        case "blue": return (0.55, 0.8) // Blue
        case "violet": return (0.8, 0.7) // Violet
        case "grey": return (0.0, 0.0) // Grey
        case "green": return (0.35, 0.7) // Green
        case "black": return (0.15, 0.3) // Dark
        default: return (0.5, 0.5) // Default blue
        }
    }
    
    private func formatLayerName(_ layer: SoundLayer) -> String {
        if layer.soundType.starts(with: "binaural") {
            return "Binaural: \(layer.binauralPreset ?? "Custom")"
        } else {
            let name = layer.soundType.prefix(1).uppercased() + layer.soundType.dropFirst()
            return "\(name) Noise"
        }
    }
    
    // Helper computed properties to simplify complex expressions
    private func rectangleColor(for index: Int) -> Color {
        if layer.isActive && Double(index) / 5.0 <= Double(layer.volume) {
            return Color.white.opacity(0.8)
        } else {
            return Color.white.opacity(0.2)
        }
    }
    
    private var indicatorColor: Color {
        return layer.isActive ? Color.green : Color.gray.opacity(0.3)
    }
}

// Layer-specific wave animation - simplified static version
struct LayerWaveAnimation: View {
    let layer: SoundLayer
    
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
    }
}

// Simplified wave animation view
struct SoundWaveAnimationView: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(0.3)
    }
}

struct MixedEnvironmentView_Previews: PreviewProvider {
    static var previews: some View {
        MixedEnvironmentView()
    }
} 