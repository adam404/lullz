//
//  SmartHomeIntegrationView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct SmartHomeIntegrationView: View {
    @EnvironmentObject var homeManager: HomeManager
    @EnvironmentObject var audioManager: AudioManager
    
    @State private var enableSceneActivation = false
    @State private var selectedConfiguration: SmartHomeConfiguration?
    @State private var showingSettings = false
    
    var profileId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Smart Home Integration")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
            
            if !homeManager.isAuthorized {
                authorizationRequestView
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Enable smart home control", isOn: $enableSceneActivation)
                        .onChange(of: enableSceneActivation) { _, newValue in
                            if newValue && selectedConfiguration != nil {
                                homeManager.applyConfiguration(selectedConfiguration!)
                            }
                        }
                    
                    if enableSceneActivation {
                        configurationSelectorView
                    }
                    
                    if enableSceneActivation && selectedConfiguration != nil {
                        configurationDetailView
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showingSettings) {
            SmartHomeControlView()
                .environmentObject(homeManager)
                .environmentObject(audioManager)
        }
        .onAppear {
            // Find any configuration already associated with this profile
            if let profileId = profileId {
                selectedConfiguration = homeManager.savedConfigurations
                    .first(where: { $0.associatedProfileId == profileId })
            }
        }
    }
    
    private var authorizationRequestView: some View {
        VStack(spacing: 12) {
            Text("Smart home integration requires HomeKit permission")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Request Access") {
                homeManager.checkAuthorization()
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var configurationSelectorView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Smart Home Configuration:")
                .font(.subheadline)
            
            if homeManager.savedConfigurations.isEmpty {
                Text("No configurations available. Create one in settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                Picker("Configuration", selection: $selectedConfiguration) {
                    Text("None").tag(nil as SmartHomeConfiguration?)
                    ForEach(homeManager.savedConfigurations) { config in
                        Text(config.name).tag(config as SmartHomeConfiguration?)
                    }
                }
                .onChange(of: selectedConfiguration) { _, newValue in
                    if enableSceneActivation, let config = newValue {
                        homeManager.applyConfiguration(config)
                    }
                }
            }
        }
    }
    
    private var configurationDetailView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let config = selectedConfiguration {
                if let sceneName = config.sceneName {
                    HStack {
                        Image(systemName: "theatermasks")
                            .foregroundColor(.secondary)
                        Text("Scene: \(sceneName)")
                            .font(.caption)
                    }
                }
                
                Text("Lights: \(config.lightConfigurations.count)")
                    .font(.caption)
                
                if let thermostat = config.thermostatConfiguration {
                    HStack {
                        Image(systemName: "thermometer")
                            .foregroundColor(.secondary)
                        Text("\(Int(thermostat.targetTemperature))°C")
                            .font(.caption)
                    }
                }
                
                Button("Apply Now") {
                    homeManager.applyConfiguration(config)
                }
                .font(.caption)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
} 
