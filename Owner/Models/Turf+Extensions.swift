import Foundation

// MARK: - Convenience extensions for Turf used by UI layers
extension Turf {
    /// Monetary value of the turf currently stored in its vault.
    public var value: Double {
        vaultCash
    }

    /// Convenience numeric level representing the turf's defense multiplier.
    public var defenseLevel: Int {
        defenseMultiplier
    }
}
