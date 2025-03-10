import HomeKit

extension HMAccessory: Identifiable {
    public var id: ObjectIdentifier {
        return ObjectIdentifier(self)
    }
} 