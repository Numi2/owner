import SwiftUI

// NEEDS TO BE ENHANCED
struct TurfDetailView: View {
    @EnvironmentObject var gameManager: GameManager
    let turf: Turf
    
    // State for showing action sheets
    @State private var showInvestSheet = false
    @State private var showBuildSheet = false
    
    var body: some View {
        List {
            // MARK: - Header Section
            Section {
                VStack(spacing: 16) {
                    ZStack {
                        HexagonShape()
                            .fill(Color.blue.gradient)
                            .frame(width: 100, height: 100)
                            .shadow(color: .blue.opacity(0.5), radius: 10, y: 5)
                        
                        Text(String(turf.name.prefix(1)))
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text(turf.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            // MARK: - Stats Section
            Section(header: Text("Statistics")) {
                StatRow(title: "Value", value: String(format: "$%.0f", turf.value), systemImage: "dollarsign.circle.fill", color: .green)
                StatRow(title: "Vault", value: String(format: "$%.0f", turf.vaultCash), systemImage: "briefcase.fill", color: .orange)
                StatRow(title: "Defense Level", value: "Lvl \(turf.defenseLevel)", systemImage: "shield.fill", color: .blue)
                
                if turf.isUnderAttack {
                    StatRow(title: "Status", value: "Under Attack!", systemImage: "exclamationmark.triangle.fill", color: .red)
                }
            }
            
            // MARK: - Actions Section
            Section(header: Text("Actions")) {
                Button(action: { showInvestSheet = true }) {
                    Label("Invest", systemImage: "dollarsign.arrow.circlepath")
                }
                
                Button(action: { gameManager.collectFromTurf(turf) }) {
                    Label("Collect from Vault", systemImage: "banknote")
                }
                .disabled(turf.vaultCash <= 0 || !isWithinRange)
            }
            
            // MARK: - Structures Section
            Section(header: Text("Structures")) {
                ForEach(turf.structures) { structure in
                    StructureRowView(structure: structure, turf: turf)
                }
                
                Button(action: { showBuildSheet = true }) {
                    Label("Build New Structure", systemImage: "plus.circle.fill")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(turf.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showInvestSheet) {
            InvestView(turf: turf)
                .environmentObject(gameManager)
        }
        .sheet(isPresented: $showBuildSheet) {
            BuildStructureView(turf: turf)
                .environmentObject(gameManager)
        }
    }
    
    private var isWithinRange: Bool {
        // This check would ideally be in a location service accessible via GameManager
        // For now, let's assume we are always in range for owned turfs for easier debugging
        return true
    }
}

// MARK: - Stat Row Helper
struct StatRow: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundColor(color)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Structure Row Helper
struct StructureRowView: View {
    let structure: Structure
    @EnvironmentObject var gameManager: GameManager
    @State private var showingUpgradeAlert = false
    
    // We need the turf to pass to the game manager
    let turf: Turf
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(structure.type.rawValue) - Lvl \(structure.level)")
                    .font(.headline)
                
                if structure.isBuilding {
                    ProgressView(value: structure.buildProgress)
                        .progressViewStyle(.linear)
                    Text("Upgrading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Idle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            
            if !structure.isBuilding {
                Button(action: { showingUpgradeAlert = true }) {
                    Text("Upgrade")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(gameManager.walletBalance < structure.currentCost)
            }
        }
        .padding(.vertical, 4)
        .alert(isPresented: $showingUpgradeAlert) {
            Alert(
                title: Text("Upgrade Structure"),
                message: Text("Upgrade \(structure.type.rawValue) to Level \(structure.level + 1) for $\(structure.currentCost, specifier: "%.0f")?"),
                primaryButton: .destructive(Text("Upgrade")) {
                    gameManager.upgradeStructure(on: turf, structureID: structure.id)
                },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Preview

    
