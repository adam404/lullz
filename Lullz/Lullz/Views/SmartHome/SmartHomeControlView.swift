//
//  SmartHomeControlView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI
import HomeKit

struct SmartHomeControlView: View {
    @EnvironmentObject var homeManager: HomeManager
    @EnvironmentObject var audioManager: AudioManager
    
    @State private var selectedTab = 0
    @State private var showingAuthAlert = false
    @State private var isEditingConfiguration = false
    @State private var configName = ""
    @State private var selectedScene: HomeManager.SceneWrapper?
    
    // Light control states
    @State private var selectedLights: Set<HMAccessory> = []
    @State private var lightBrightness: [String: Double] = [:]
    @State private var lightHue: [String: Double] = [:]
    @State private var lightSaturation: [String: Double] = [:]
    
    // Thermostat control state
    @State private var selectedThermostat: HMAccessory?
    @State private var targetTemperature: Double = 21.0
    
    var body: some View {
        NavigationView {
            VStack {
                if !homeManager.isAuthorized {
                    unauthorizedView
                } else if homeManager.homes.isEmpty {
                    noHomesView
                } else {
                    TabView(selection: $selectedTab) {
                        scenesView
                            .tabItem {
                                Label("Scenes", systemImage: "theatermasks")
                            }
                            .tag(0)
                        
                        lightsView
                            .tabItem {
                                Label("Lights", systemImage: "lightbulb")
                            }
                            .tag(1)
                        
                        temperatureView
                            .tabItem {
                                Label("Temperature", systemImage: "thermometer")
                            }
                            .tag(2)
                        
                        configurationsView
                            .tabItem {
                                Label("Configs", systemImage: "gear")
                            }
                            .tag(3)
                    }
                }
            }
            .navigationTitle("Smart Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if homeManager.isAuthorized && !homeManager.homes.isEmpty {
                        Button("Save Config") {
                            isEditingConfiguration = true
                        }
                    }
                }
            }
            .alert("HomeKit Access Required", isPresented: $showingAuthAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable HomeKit access in Settings to use smart home features.")
            }
            .sheet(isPresented: $isEditingConfiguration) {
                saveConfigurationSheet
            }
            .onAppear {
                // Initialize brightness dictionary for all lights
                for light in homeManager.availableLights {
                    if let lightService = light.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }),
                       let brightnessChar = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
                        
                        brightnessChar.readValue { error in
                            if error == nil, let value = brightnessChar.value as? Int {
                                self.lightBrightness[String(ObjectIdentifier(light).hashValue)] = Double(value)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Unauthorized View
    
    private var unauthorizedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("HomeKit Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("To control your smart home devices, Lullz needs permission to access your HomeKit data.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Grant Permission") {
                homeManager.checkAuthorization()
                
                // If still not authorized after check, show settings alert
                if !homeManager.isAuthorized {
                    showingAuthAlert = true
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
    }
    
    // MARK: - No Homes View
    
    private var noHomesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No HomeKit Homes Found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Set up a home in the Home app before using the smart home integration features.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Open Home App") {
                if let homeURL = URL(string: "homeapp://") {
                    UIApplication.shared.open(homeURL)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
    }
    
    // MARK: - Scenes View
    
    private var scenesView: some View {
        List {
            if homeManager.availableScenes.isEmpty {
                Text("No scenes found. Create scenes in the Home app to use them here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(homeManager.availableScenes, id: \.uniqueIdentifier) { scene in
                    HStack {
                        Image(systemName: "theatermasks.fill")
                            .foregroundColor(selectedScene?.id == scene.id ? .accentColor : .secondary)
                        
                        Text(scene.name)
                        
                        Spacer()
                        
                        if selectedScene?.id == scene.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedScene = scene
                        homeManager.activateScene(scene)
                    }
                }
            }
            
            Section(header: Text("Associate with Audio")) {
                Button("Activate with Current Audio") {
                    // TODO: Associate selected scene with current audio profile
                }
                .disabled(selectedScene == nil || !audioManager.isPlaying)
            }
        }
    }
    
    // MARK: - Lights View
    
    private var lightsView: some View {
        List {
            if homeManager.availableLights.isEmpty {
                Text("No lights found. Add HomeKit-compatible lights to your home to control them here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(selectedLights), id: \ .id) { light in
                    LightControlRow(
                        light: light,
                        isSelected: selectedLights.contains(light),
                        brightness: Binding(
                            get: { lightBrightness[String(ObjectIdentifier(light).hashValue)] ?? 100 },
                            set: { newBrightness in
                                lightBrightness[String(ObjectIdentifier(light).hashValue)] = newBrightness
                                homeManager.updateLightBrightness(for: light, brightness: Int(newBrightness))
                            }
                        ),
                        onToggle: {
                            if selectedLights.contains(light) {
                                selectedLights.remove(light)
                            } else {
                                selectedLights.insert(light)
                            }
                        },
                        onColorTap: {
                            // Open color picker
                        }
                    )
                }
            }
            
            Section(header: Text("Group Actions")) {
                Button("Turn All Off") {
                    for light in homeManager.availableLights {
                        homeManager.updateLightBrightness(for: light, brightness: 0)
                    }
                }
                .disabled(homeManager.availableLights.isEmpty)
                
                Button("Dim All Lights") {
                    for light in homeManager.availableLights {
                        homeManager.updateLightBrightness(for: light, brightness: 20)
                    }
                }
                .disabled(homeManager.availableLights.isEmpty)
            }
        }
    }
    
    // MARK: - Temperature View
    
    private var temperatureView: some View {
        List {
            if homeManager.availableThermostats.isEmpty {
                Text("No thermostats found. Add HomeKit-compatible thermostats to your home to control them here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Section(header: Text("Select Thermostat")) {
                    ForEach(homeManager.availableThermostats) { thermostat in
                        HStack {
                            Image(systemName: "thermometer")
                                .foregroundColor(selectedThermostat?.id == thermostat.id ? .accentColor : .secondary)
                            
                            Text(thermostat.name)
                            
                            Spacer()
                            
                            if selectedThermostat?.id == thermostat.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedThermostat = thermostat
                        }
                    }
                }
                
                if let thermostat = selectedThermostat {
                    Section(header: Text("Temperature Control")) {
                        VStack {
                            Text("\(Int(targetTemperature))°C")
                                .font(.title)
                                .padding()
                            
                            Slider(value: $targetTemperature, in: 16...28, step: 0.5, onEditingChanged: { changed in
                                if changed {
                                    homeManager.updateTemperature(for: thermostat, temperature: targetTemperature)
                                }
                            })
                            
                            HStack {
                                Button("Optimal Sleep (18°)") {
                                    targetTemperature = 18
                                    homeManager.updateTemperature(for: thermostat, temperature: 18)
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Comfortable (22°)") {
                                    targetTemperature = 22
                                    homeManager.updateTemperature(for: thermostat, temperature: 22)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.top)
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    // MARK: - Configurations View
    
    private var configurationsView: some View {
        List {
            if homeManager.savedConfigurations.isEmpty {
                Text("You haven't saved any smart home configurations yet. Use the scenes, lights, and temperature controls to create a setup, then tap 'Save Config'.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(homeManager.savedConfigurations) { config in
                    VStack(alignment: .leading) {
                        Text(config.name)
                            .font(.headline)
                        
                        if let sceneName = config.sceneName {
                            Text("Scene: \(sceneName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Lights: \(config.lightConfigurations.count)")
                            .font(.caption)
                        
                        if config.thermostatConfiguration != nil {
                            Text("Temperature: \(Int(config.thermostatConfiguration!.targetTemperature))°C")
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        homeManager.applyConfiguration(config)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            // Delete configuration
                            homeManager.savedConfigurations.removeAll { $0.id == config.id }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Save Configuration Sheet
    
    private var saveConfigurationSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Configuration Name")) {
                    TextField("Enter a name", text: $configName)
                }
                
                Section(header: Text("Selected Devices")) {
                    if let scene = selectedScene {
                        HStack {
                            Image(systemName: "theatermasks.fill")
                            Text("Scene: \(scene.name)")
                        }
                    }
                    
                    ForEach(Array(selectedLights)) { light in
                        HStack {
                            Image(systemName: "lightbulb.fill")
                            Text("Light: \(light.name)")
                            Spacer()
                            Text("\(Int(lightBrightness[String(ObjectIdentifier(light).hashValue)] ?? 100))%")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let thermostat = selectedThermostat {
                        HStack {
                            Image(systemName: "thermometer")
                            Text("Thermostat: \(thermostat.name)")
                            Spacer()
                            Text("\(Int(targetTemperature))°C")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Associate with Profile")) {
                    Button("Associate with Current Audio") {
                        // TODO: Link current audio settings to this configuration
                    }
                    .disabled(!audioManager.isPlaying)
                }
            }
            .navigationTitle("Save Configuration")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isEditingConfiguration = false
                },
                trailing: Button("Save") {
                    saveConfiguration()
                    isEditingConfiguration = false
                }
                .disabled(configName.isEmpty)
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveConfiguration() {
        let lightConfigs = selectedLights.map { light in
            LightConfiguration(
                accessoryName: light.name,
                brightness: Int(lightBrightness[String(ObjectIdentifier(light).hashValue)] ?? 100),
                hue: lightHue[String(ObjectIdentifier(light).hashValue)],
                saturation: lightSaturation[String(ObjectIdentifier(light).hashValue)]
            )
        }
        
        var thermostatConfig: ThermostatConfiguration?
        if let thermostat = selectedThermostat {
            thermostatConfig = ThermostatConfiguration(
                accessoryName: thermostat.name,
                targetTemperature: targetTemperature
            )
        }
        
        homeManager.saveConfiguration(
            name: configName,
            sceneName: selectedScene?.name,
            lights: lightConfigs,
            thermostat: thermostatConfig
        )
        
        // Reset state
        configName = ""
    }
}

// MARK: - Light Control Row

struct LightControlRow: View {
    let light: HMAccessory
    let isSelected: Bool
    @Binding var brightness: Double
    let onToggle: () -> Void
    let onColorTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: isSelected ? "lightbulb.fill" : "lightbulb")
                    .foregroundColor(isSelected ? .yellow : .secondary)
                
                Text(light.name)
                
                Spacer()
                
                Button(action: onToggle) {
                    Text(isSelected ? "On" : "Off")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isSelected ? Color.green.opacity(0.2) : Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            if isSelected {
                HStack {
                    Image(systemName: "sun.min")
                    Slider(value: $brightness, in: 0...100)
                    Image(systemName: "sun.max")
                }
                .padding(.top, 4)
                
                Button("Set Color") {
                    onColorTap()
                }
                .font(.caption)
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 4)
    }
} 