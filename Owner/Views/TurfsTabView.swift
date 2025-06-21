import SwiftUI

struct TurfsTabView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedSort: SortOption = .value
    @State private var searchText = ""
    
    enum SortOption: String, CaseIterable {
        case value = "Value"
        case name = "Name"
        case defenseLevel = "Defense"
        case recent = "Recent"
        
        var systemImage: String {
            switch self {
            case .value: return "dollarsign.circle"
            case .name: return "textformat"
            case .defenseLevel: return "shield"
            case .recent: return "clock"
            }
        }
    }
    
    var filteredTurfs: [Turf] {
        let turfs = gameManager.playerTurfs.filter { turf in
            searchText.isEmpty || turf.name.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedSort {
        case .value:
            return turfs.sorted { $0.value > $1.value }
        case .name:
            return turfs.sorted { $0.name < $1.name }
        case .defenseLevel:
            return turfs.sorted { $0.defenseLevel > $1.defenseLevel }
        case .recent:
            return turfs.sorted { $0.id > $1.id } // Assuming higher ID = more recent
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Summary Section
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Turfs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(gameManager.playerTurfs.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Total Value")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(gameManager.playerTurfs.reduce(0) { $0 + $1.value }, specifier: "%.0f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.horizontal)
                
                // Turfs List
                Section {
                    ForEach(filteredTurfs) { turf in
                        TurfRowView(turf: turf)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                    }
                } header: {
                    HStack {
                        Text("My Turfs")
                            .font(.headline)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { selectedSort = option }) {
                                    Label(option.rawValue, systemImage: option.systemImage)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedSort.rawValue)
                                    .font(.caption)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
                .textCase(nil)
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search turfs")
            .navigationTitle("My Turfs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Show turf statistics
                    }) {
                        Image(systemName: "chart.pie")
                    }
                }
            }
            .overlay {
                if gameManager.playerTurfs.isEmpty {
                    EmptyTurfsView()
                }
            }
        }
    }
}

// MARK: - Turf Row View
struct TurfRowView: View {
    let turf: Turf
    
    var body: some View {
        HStack(spacing: 16) {
            // Turf Icon
            ZStack {
                HexagonShape()
                    .fill(turf.isUnderAttack ? Color.red.gradient : Color.blue.gradient)
                    .frame(width: 50, height: 50)
                
                Text(String(turf.name.prefix(1)))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Turf Info
            VStack(alignment: .leading, spacing: 4) {
                Text(turf.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("$\(turf.value, specifier: "%.0f")", systemImage: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Label("Lvl \(turf.defenseLevel)", systemImage: "shield.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if turf.isUnderAttack {
                        Label("Under Attack", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            // Action Button
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .glassCard(cornerRadius: 12, shadowRadius: 6)
    }
}

// MARK: - Empty State
struct EmptyTurfsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hexagon.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No Turfs Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Visit the map to claim your first turf!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Hexagon Shape
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        
        for i in 0..<6 {
            let angle = CGFloat(i) * CGFloat.pi / 3 - CGFloat.pi / 6
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview
struct TurfsTabView_Previews: PreviewProvider {
    static var previews: some View {
        TurfsTabView()
            .environmentObject(GameManager())
    }
}