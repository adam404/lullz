//
//  HomeManager.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import Foundation
import HomeKit
import Combine

class HomeManager: NSObject, ObservableObject, HMHomeManagerDelegate {
    private var homeManager = HMHomeManager()
    
    @Published var homes: [HMHome] = []
    @Published var selectedHome: HMHome?
    @Published var isAuthorized = false
    @Published var authorizationStatus: Bool = false  // Changed from HMHomeManagerAuthorizationStatus
    
    // Smart device collections
    @Published var availableLights: [HMAccessory] = []
    @Published var availableSpeakers: [HMAccessory] = []
    @Published var availableThermostats: [HMAccessory] = []
    
    // Scenes for quick activation
    @Published var availableScenes: [SceneWrapper] = []  // Changed from HMScene
    
    // Saved configurations
    @Published var savedConfigurations: [SmartHomeConfiguration] = []
    
    override init() {
        super.init()
        homeManager.delegate = self
        
        // Load saved configurations
        loadSavedConfigurations()
    }
    
    // Wrapper for HomeKit scenes to avoid direct HMScene references
    struct SceneWrapper: Identifiable {
        let actionSet: HMActionSet  // Changed from HMAction to HMActionSet
        let name: String
        let uniqueIdentifier: UUID
        
        var id: UUID { uniqueIdentifier }
        
        init(actionSet: HMActionSet) {
            self.actionSet = actionSet
            self.name = actionSet.name  // HMActionSet has a name property
            self.uniqueIdentifier = UUID()
        }
    }
    
    func checkAuthorization() {
        // HomeKit authorization is handled through usage description in Info.plist
        // and is prompted automatically when HomeKit APIs are accessed
        DispatchQueue.main.async {
            self.authorizationStatus = true
            self.isAuthorized = true
        }
    }
    
    // Find all available devices of certain types
    func findAllLights() {
        guard let home = selectedHome else { return }
        
        self.availableLights = home.accessories.filter { accessory in
            return accessory.services.contains { service in
                return service.serviceType == HMServiceTypeLightbulb
            }
        }
    }
    
    func findAllSpeakers() {
        guard let home = selectedHome else { return }
        
        self.availableSpeakers = home.accessories.filter { accessory in
            return accessory.services.contains { service in
                // Use a standard service type instead of AudioStreamManagement
                return service.serviceType == HMServiceTypeSwitch
            }
        }
    }
    
    func findAllThermostats() {
        guard let home = selectedHome else { return }
        
        self.availableThermostats = home.accessories.filter { accessory in
            return accessory.services.contains { service in
                return service.serviceType == HMServiceTypeThermostat
            }
        }
    }
    
    func findAllScenes() {
        guard let home = selectedHome else { return }
        
        // Updated to use HMActionSet directly
        let allActionSets = home.actionSets
        
        self.availableScenes = allActionSets.map { actionSet in
            return SceneWrapper(actionSet: actionSet)  // Pass the actionSet directly
        }
    }
    
    // MARK: - Home Manager Delegate
    
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        DispatchQueue.main.async {
            self.homes = manager.homes
            
            // Use first home instead of primaryHome if available
            if let firstHome = manager.homes.first {
                self.selectedHome = firstHome
                
                // Find available devices in this home
                self.findAllLights()
                self.findAllSpeakers()
                self.findAllThermostats()
                self.findAllScenes()
            } else {
                self.selectedHome = nil
            }
        }
    }
    
    // MARK: - Scene Control
    
    func activateScene(_ scene: SceneWrapper) {
        guard let home = selectedHome else {
            print("Cannot activate scene: No home selected")
            return
        }
        
        let actionSet = scene.actionSet
        
        // Use the correct method for executing action sets via the home
        home.executeActionSet(actionSet) { error in
            if let error = error {
                print("Failed to activate scene: \(error.localizedDescription)")
            } else {
                print("Scene activated successfully")
            }
        }
    }
    
    // MARK: - Configuration Management
    
    func saveConfiguration(name: String, sceneName: String?, lights: [LightConfiguration], thermostat: ThermostatConfiguration?) {
        let config = SmartHomeConfiguration(
            name: name,
            sceneName: sceneName,
            lightConfigurations: lights,
            thermostatConfiguration: thermostat,
            associatedProfileId: nil
        )
        savedConfigurations.append(config)
        saveToDisk()
    }
    
    private func loadSavedConfigurations() {
        if let data = UserDefaults.standard.data(forKey: "savedSmartHomeConfigurations") {
            do {
                let configs = try JSONDecoder().decode([SmartHomeConfiguration].self, from: data)
                self.savedConfigurations = configs
            } catch {
                print("Failed to load saved configurations: \(error)")
            }
        }
    }
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(savedConfigurations)
            UserDefaults.standard.set(data, forKey: "savedSmartHomeConfigurations")
        } catch {
            print("Failed to save configurations: \(error)")
        }
    }
    
    func deleteConfiguration(_ config: SmartHomeConfiguration) {
        savedConfigurations.removeAll { $0.id == config.id }
        saveToDisk()
    }
    
    func applyConfiguration(_ config: SmartHomeConfiguration) {
        // First apply any scene if available
        if let sceneName = config.sceneName {
            if let scene = availableScenes.first(where: { $0.name == sceneName }) {
                activateScene(scene)
            }
        }
        
        // Apply light configurations
        for lightConfig in config.lightConfigurations {
            if let light = availableLights.first(where: { $0.name == lightConfig.accessoryName }) {
                // Find the lightbulb service
                if let lightService = light.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) {
                    // Set power state
                    if let powerCharacteristic = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {
                        powerCharacteristic.writeValue(lightConfig.isOn) { error in
                            if let error = error {
                                print("Failed to set power state: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    // Set brightness if light is on
                    if lightConfig.isOn, 
                       let brightnessCharacteristic = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
                        brightnessCharacteristic.writeValue(lightConfig.brightness) { error in
                            if let error = error {
                                print("Failed to set brightness: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    // Set hue and saturation if available
                    if lightConfig.isOn, let hue = lightConfig.hue,
                       let hueCharacteristic = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeHue }) {
                        hueCharacteristic.writeValue(hue) { error in
                            if let error = error {
                                print("Failed to set hue: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    if lightConfig.isOn, let saturation = lightConfig.saturation,
                       let saturationCharacteristic = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeSaturation }) {
                        saturationCharacteristic.writeValue(saturation) { error in
                            if let error = error {
                                print("Failed to set saturation: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
        
        // Apply thermostat configuration if available
        if let thermostatConfig = config.thermostatConfiguration,
           let thermostat = availableThermostats.first(where: { $0.name == thermostatConfig.accessoryName }) {
            // Find the thermostat service
            if let thermostatService = thermostat.services.first(where: { $0.serviceType == HMServiceTypeThermostat }) {
                // Set target temperature
                if let targetTempCharacteristic = thermostatService.characteristics.first(where: { 
                    $0.characteristicType == HMCharacteristicTypeTargetTemperature 
                }) {
                    targetTempCharacteristic.writeValue(thermostatConfig.targetTemperature) { error in
                        if let error = error {
                            print("Failed to set target temperature: \(error.localizedDescription)")
                        }
                    }
                }
                
                // Set thermostat mode if available
                if let modeCharacteristic = thermostatService.characteristics.first(where: { 
                    $0.characteristicType == HMCharacteristicTypeTargetHeatingCooling 
                }) {
                    let modeValue: Int
                    switch thermostatConfig.mode {
                    case .off: modeValue = 0
                    case .heat: modeValue = 1
                    case .cool: modeValue = 2
                    case .auto: modeValue = 3
                    }
                    
                    modeCharacteristic.writeValue(modeValue) { error in
                        if let error = error {
                            print("Failed to set thermostat mode: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        
        print("Smart home configuration '\(config.name)' applied successfully")
    }
    
    // MARK: - Device Control Methods
    
    func updateLightBrightness(for light: HMAccessory, brightness: Int) {
        guard let lightService = light.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }),
              let brightnessCharacteristic = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
        else {
            print("Light service or brightness characteristic not found")
            return
        }
        brightnessCharacteristic.writeValue(brightness) { error in
            if let error = error {
                print("Failed to update brightness: \(error.localizedDescription)")
            }
        }
    }
    
    func updateTemperature(for thermostat: HMAccessory, temperature: Double) {
        guard let thermostatService = thermostat.services.first(where: { $0.serviceType == HMServiceTypeThermostat }),
              let targetTempCharacteristic = thermostatService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetTemperature })
        else {
            print("Thermostat service or target temperature characteristic not found")
            return
        }
        targetTempCharacteristic.writeValue(temperature) { error in
            if let error = error {
                print("Failed to set temperature: \(error.localizedDescription)")
            }
        }
    }
} 