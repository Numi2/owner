import Foundation

// MARK: - Convenience extensions for Turf used by UI layers
extension Turf {
    /// A readable display name generated from the turf identifier (lat/lon)
    public var name: String {
        // Take the first component of the id up to the first ':' and format nicely
        // Example id: "37.3349:-122.009"  ->  "37.3349"
        let latString = id.split(separator: ":").first ?? Substring("")
        return "Turf \(latString)"
    }

    /// Monetary value of the turf currently stored in its vault.
    public var value: Double {
        vaultCash
    }

    /// Convenience numeric level representing the turf's defense multiplier.
    public var defenseLevel: Int {
        defenseMultiplier
    }
}