import SwiftUI
import SwiftData
import LullzCore

public class SwiftDataModel {
    public static let shared = SwiftDataModel()
    
    public let modelContainer: ModelContainer
    
    private init() {
        let schema = Schema([
            NoiseProfile.self,
            BreathingPattern.self,
            MixedEnvironment.self,
            SoundLayer.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // Helper method to get a model context
    public func createContext() -> ModelContext {
        return ModelContext(modelContainer)
    }
} 