//
//  SwiftDataModel.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI
import SwiftData

class SwiftDataModel {
    static let shared = SwiftDataModel()
    
    let modelContainer: ModelContainer
    
    private init() {
        let schema = Schema([
            NoiseProfile.self,
            Item.self // Keep existing Item model
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
} 