//
//  LullzApp.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI
import SwiftData
import AVFoundation

// Create a setup manager class to handle App initialization
class AppSetupManager: ObservableObject {
    var audioManager: AudioManager
    private var isInitialized = false
    
    init(audioManager: AudioManager) {
        self.audioManager = audioManager
        
        // Setup basic audio session
        setupAudioSession()
        
        // Listen for database reset requests
        NotificationCenter.default.addObserver(
            forName: Notification.Name("RequestDatabaseReset"),
            object: nil,
            queue: .main) { _ in
                print("Database reset requested")
            }
    }
    
    func completeSetup() {
        if !isInitialized {
            // Register for audio interruptions
            registerForNotifications()
            isInitialized = true
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, 
                                                          options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main) { [weak self] notification in
                guard let self = self,
                      let info = notification.userInfo,
                      let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
                
                if type == .began {
                    // Audio session interrupted, pause playback
                    self.audioManager.pausePlayback()
                } else if type == .ended {
                    guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        // Interruption ended, resume playback
                        self.audioManager.resumePlayback()
                    }
                }
            }
    }
    
    func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active
            if oldPhase == .background {
                setupAudioSession()
            }
        case .background:
            // App went to background, ensure audio continues
            print("App moved to background - audio continues playing")
        case .inactive:
            // App is inactive but might still be visible
            print("App became inactive")
        @unknown default:
            print("Unknown scene phase")
        }
    }
    
    private func resetDatabase() {
        // Try to delete the database file
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if let applicationSupportURL = urls.first {
            let storeURL = applicationSupportURL.appendingPathComponent("default.store")
            
            do {
                // Delete the database file
                try FileManager.default.removeItem(at: storeURL)
                print("Database file deleted successfully")
                
                // Post notification to inform the app to restart
                NotificationCenter.default.post(name: Notification.Name("DatabaseResetComplete"), object: nil)
                
                // Show alert or message to user that they need to restart the app
                DispatchQueue.main.async {
                    // Force restart the app (or show an alert asking the user to restart)
                    print("App needs to be restarted to use the new database")
                    // In a production app, you would show an alert here
                }
            } catch {
                print("Failed to delete database file: \(error.localizedDescription)")
            }
        }
    }
}

@main
struct LullzApp: App {
    // App state manager to handle audio session
    @StateObject private var audioManager = AudioManager()
    
    // Setup manager to handle initialization and state
    @StateObject private var setupManager: AppSetupManager
    
    // Scene phase for handling app lifecycle
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            NoiseProfile.self,
            MixedEnvironment.self,
            SoundLayer.self,
            BreathingPattern.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            // First, try to create a new container with the updated schema
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // After successfully creating a container, check if we need to add default environments
            Task { @MainActor in
                // Check if there are any environments
                let context = container.mainContext
                let envDescriptor = FetchDescriptor<MixedEnvironment>()
                if let count = try? context.fetchCount(envDescriptor), count == 0 {
                    // No environments found, add the default ones
                    LullzApp.createDefaultEnvironments(in: context)
                }
            }
            
            return container
        } catch {
            // If there was an error with the database, it might be corrupted or have schema issues
            print("Error creating model container: \(error.localizedDescription)")
            
            // Try to recreate the database by deleting it first
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let applicationSupportURL = urls.first {
                let storeURL = applicationSupportURL.appendingPathComponent("default.store")
                
                do {
                    // Delete the corrupted database
                    try FileManager.default.removeItem(at: storeURL)
                    print("Deleted corrupted database file")
                    
                    // Create a new container
                    let newContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                    
                    // Populate with default data
                    Task { @MainActor in
                        LullzApp.createDefaultEnvironments(in: newContainer.mainContext)
                    }
                    
                    return newContainer
                } catch {
                    print("Failed to recreate database: \(error.localizedDescription)")
                }
            }
            
            // If all else fails, create an in-memory database
            print("Creating in-memory database as fallback")
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                let fallbackContainer = try ModelContainer(for: schema, configurations: [fallbackConfig])
                
                // Add default environments to the in-memory database
                Task { @MainActor in
                    LullzApp.createDefaultEnvironments(in: fallbackContainer.mainContext)
                }
                
                return fallbackContainer
            } catch {
                fatalError("Could not create ModelContainer: \(error.localizedDescription)")
            }
        }
    }()
    
    // Make this a static method so it can be called from the property initializer
    private static func createDefaultEnvironments(in context: ModelContext) {
        // 1. Deep Sleep Sanctuary
        let deepSleep = MixedEnvironment(
            name: "Deep Sleep Sanctuary",
            description: "A soothing blend of brown noise and gentle binaural waves to help you drift into deep, restorative sleep.",
            layers: [
                SoundLayer(
                    soundType: "brown",
                    volume: 0.6,
                    balance: 0.5,
                    isActive: true
                ),
                SoundLayer(
                    soundType: "binaural",
                    volume: 0.4,
                    balance: 0.5,
                    isActive: true,
                    binauralPreset: "sleep",
                    modulation: .amplitude,
                    modulationRate: 0.1,
                    modulationDepth: 0.3
                )
            ]
        )
        deepSleep.isPreset = true
        
        // 2. Ocean Waves
        let oceanWaves = MixedEnvironment(
            name: "Ocean Waves",
            description: "Gentle ocean waves with subtle spatial movement",
            layers: [
                SoundLayer(
                    soundType: "brown",
                    volume: 0.5,
                    balance: 0.5,
                    isActive: true,
                    modulation: .spatial,
                    modulationRate: 0.07,
                    modulationDepth: 0.3
                ),
                SoundLayer(
                    soundType: "white",
                    volume: 0.2,
                    balance: 0.5,
                    isActive: true,
                    modulation: .amplitude,
                    modulationRate: 0.1,
                    modulationDepth: 0.7
                )
            ]
        )
        oceanWaves.isPreset = true
        
        // 3. Meditation Space
        let meditationSpace = MixedEnvironment(
            name: "Meditation Space",
            description: "A blend of binaural beats and gentle background noise",
            layers: [
                SoundLayer(
                    soundType: "binaural",
                    volume: 0.5,
                    balance: 0.5,
                    isActive: true,
                    binauralPreset: "meditation"
                ),
                SoundLayer(
                    soundType: "pink",
                    volume: 0.15,
                    balance: 0.5,
                    isActive: true
                )
            ]
        )
        meditationSpace.isPreset = true
        
        // 4. Focus Flow
        let focusFlow = MixedEnvironment(
            name: "Focus Flow",
            description: "Engineered to enhance concentration and cognitive performance with precision-tuned frequencies.",
            layers: [
                SoundLayer(
                    soundType: "white",
                    volume: 0.35,
                    balance: 0.5,
                    isActive: true
                ),
                SoundLayer(
                    soundType: "pink",
                    volume: 0.25,
                    balance: 0.5,
                    isActive: true
                ),
                SoundLayer(
                    soundType: "binaural",
                    volume: 0.5,
                    balance: 0.5,
                    isActive: true,
                    binauralPreset: "focus"
                )
            ]
        )
        focusFlow.isPreset = true
        
        // 5. Forest Morning
        let forestMorning = MixedEnvironment(
            name: "Forest Morning",
            description: "The peaceful ambient sounds of a forest at dawn",
            layers: [
                SoundLayer(
                    soundType: "green",
                    volume: 0.45,
                    balance: 0.5,
                    isActive: true
                ),
                SoundLayer(
                    soundType: "pink",
                    volume: 0.2,
                    balance: 0.6,
                    isActive: true,
                    modulation: .amplitude,
                    modulationRate: 0.12,
                    modulationDepth: 0.2
                ),
                SoundLayer(
                    soundType: "white",
                    volume: 0.1,
                    balance: 0.4,
                    isActive: true,
                    modulation: .amplitude,
                    modulationRate: 0.3,
                    modulationDepth: 0.5
                )
            ]
        )
        forestMorning.isPreset = true
        
        // Insert environments into the database
        context.insert(deepSleep)
        context.insert(oceanWaves)
        context.insert(meditationSpace)
        context.insert(focusFlow)
        context.insert(forestMorning)
        
        // Try to save the changes
        do {
            try context.save()
            print("Successfully created default environments")
        } catch {
            print("Failed to save default environments: \(error)")
        }
    }

    init() {
        // Initialize the setup manager with our managers
        _setupManager = StateObject(wrappedValue: AppSetupManager(
            audioManager: AudioManager()
        ))
    }
    
    @State private var showingLegalTerms = false
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(audioManager)
                .sheet(isPresented: $showingLegalTerms) {
                    LegalSectionView()
                        .interactiveDismissDisabled()
                }
                .onAppear {
                    // Complete initialization here after view has appeared
                    setupManager.completeSetup()
                    
                    // Check if the user has already acknowledged the legal terms
                    let hasAcknowledged = UserDefaults.standard.bool(forKey: "hasAcknowledgedLegalTerms")
                    showingLegalTerms = !hasAcknowledged
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            setupManager.handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
}

// Add this extension to make sure audio loops continuously
extension LullzApp {
    // This delegate will be called when we need to try a sound from the Information view
    class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            // Set up continuous looping flag for audio session
            do {
                // This ensures that the audio will continuously loop without gaps
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, options: [.mixWithOthers, .duckOthers])
                try audioSession.setActive(true)
                
                // Register for audio route changes
                NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification,
                                                      object: nil,
                                                      queue: .main) { notification in
                    guard let userInfo = notification.userInfo,
                          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                        return
                    }
                    
                    // Handle route changes (e.g., headphones connected/disconnected)
                    // This helps ensure continuous playback when audio routes change
                    if reason == .newDeviceAvailable || reason == .oldDeviceUnavailable {
                        // Notify AudioManager to update if needed
                        NotificationCenter.default.post(name: Notification.Name("AudioRouteChanged"), 
                                                      object: nil)
                    }
                }
            } catch {
                print("Failed to configure audio session for continuous playback: \(error)")
            }
            
            return true
        }
    }
}
