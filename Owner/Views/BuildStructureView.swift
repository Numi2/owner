import SwiftUI

struct BuildStructureView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameManager: GameManager
    
    let turf: Turf
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Structure.StructureType.allCases, id: \.self) { type in
                    Section(header: Text(type.rawValue)) {
                        StructureBuildRow(turf: turf, type: type)
                    }
                }
            }
            .navigationTitle("Build Structure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StructureBuildRow: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameManager: GameManager
    
    let turf: Turf
    let type: Structure.StructureType
    
    private var structure: Structure {
        return Structure(type: type)
    }
    
    private var canBuild: Bool {
        // Cannot build if a structure of the same type already exists
        !turf.structures.contains(where: { $0.type == type })
    }
    
    private var canAfford: Bool {
        gameManager.walletBalance >= structure.currentCost
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(structureDescription)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Cost: $\(structure.baseCost, specifier: "%.0f")")
                    Text("Build Time: \(structure.buildTime, specifier: "%.0f")s")
                }
                .font(.subheadline)
                
                Spacer()
                
                Button(action: build) {
                    Text("Build")
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(canBuild && canAfford ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!canBuild || !canAfford)
            }
            
            if !canBuild {
                Text("A \(type.rawValue) already exists on this turf.")
                    .font(.caption)
                    .foregroundColor(.red)
            } else if !canAfford {
                Text("Insufficient funds.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical)
    }
    
    private var structureDescription: String {
        switch type {
        case .defenseTower:
            return "Increases the turf's defense and steals a small amount of cash from nearby enemy turfs."
        case .incomeGenerator:
            return "Passively generates income over time, which is added to the turf's vault."
        }
    }
    
    private func build() {
        gameManager.buildStructure(on: turf, type: type)
        dismiss()
    }
} 