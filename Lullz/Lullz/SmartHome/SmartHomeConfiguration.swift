//
//  SmartHomeConfiguration.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import Foundation

struct SmartHomeConfiguration: Identifiable, Hashable, Equatable, Codable {
    var id = UUID()
    var name: String
    var sceneName: String?
    var lightConfigurations: [LightConfiguration]
    var thermostatConfiguration: ThermostatConfiguration?
    var createdAt: Date = Date()
    
    // For association with audio profiles
    var associatedProfileId: UUID?
  
  
    static func == (lhs: SmartHomeConfiguration, rhs: SmartHomeConfiguration) -> Bool {
      return lhs.id == rhs.id
    }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

struct LightConfiguration: Identifiable, Codable {
    var id = UUID()
    var accessoryName: String
    var brightness: Int
    var hue: Double?
    var saturation: Double?
    var isOn: Bool = true
}

struct ThermostatConfiguration: Identifiable, Codable {
    var id = UUID()
    var accessoryName: String
    var targetTemperature: Double
    var mode: ThermostatMode = .auto
    
    enum ThermostatMode: String, Codable {
        case cool
        case heat
        case auto
        case off
    }
} 
