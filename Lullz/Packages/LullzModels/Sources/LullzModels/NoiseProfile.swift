import Foundation
import SwiftData

@Model
public final class NoiseProfile {
    // MARK: - Properties
    
    public var name: String
    public var noiseType: String // Stored as string for persistence compatibility
    public var volume: Float
    public var balance: Float
    public var leftDelay: Float
    public var rightDelay: Float
    public var createdAt: Date
    public var profileDescription: String? // Changed from 'description' to avoid conflict
    
    // MARK: - Initialization
    
    public init(
        name: String,
        noiseType: String,
        volume: Float,
        balance: Float,
        leftDelay: Float,
        rightDelay: Float,
        noiseDescription: String? = nil
    ) {
        self.name = name
        self.noiseType = noiseType
        self.volume = volume
        self.balance = balance
        self.leftDelay = leftDelay
        self.rightDelay = rightDelay
        self.profileDescription = description // Changed parameter name mapping
        self.createdAt = Date()
    }
    
    // MARK: - Convenience Methods
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    public var displayName: String {
        name.isEmpty ? "Untitled Profile" : name
    }
    
    // Add a computed property to access the description
    public var description: String {
        profileDescription ?? "No description available"
    }
}