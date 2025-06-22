//
//  ActionSheetView.swift
//  Owner
//
//  Created by T on 6/21/25.
//

import SwiftUI

struct ActionSheetView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var locationService: LocationService
    @Environment(\.dismiss) private var dismiss
    
    let turf: Turf
    
    @State private var investAmount: String = ""
    @State private var selectedWeapon: WeaponPack = WeaponPack.basic
    @State private var showingInvestAlert = false
    @State private var showingAttackConfirmation = false
    @State private var reinforceAmount: Double = 10.0
    
    private var isPlayerOwned: Bool {
        turf.ownerID == gameManager.currentPlayer?.id
    }
    
    private var isInRange: Bool {
        locationService.isWithinRange(of: turf.coordinate)
    }
    
    private var distanceText: String {
        if let distance = locationService.distanceFromCurrentLocation(to: turf.coordinate) {
            return "\(Int(distance))m away"
        }
        return "Distance unknown"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Turf Info Header
                VStack(spacing: 8) {
                    Text("Turf")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Lat: \(turf.latitude, specifier: "%.6f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Lon: \(turf.longitude, specifier: "%.6f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(distanceText)
                        .font(.caption)
                        .foregroundColor(isInRange ? .green : .red)
                        .fontWeight(.medium)
                }
                .glassCard()
                
                // Turf Status
                VStack(spacing: 8) {
                    HStack {
                        Text("Owner:")
                        Spacer()
                        Text(turf.isNeutral ? "Neutral" : (isPlayerOwned ? "You" : "Enemy"))
                            .fontWeight(.medium)
                            .foregroundColor(turf.isNeutral ? .gray : (isPlayerOwned ? .blue : .red))
                    }
                    
                    HStack {
                        Text("Vault Cash:")
                        Spacer()
                        Text("$\(turf.vaultCash, specifier: "%.2f")")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    if !turf.isNeutral {
                        HStack {
                            Text("Defense Value:")
                            Spacer()
                            Text("\(turf.defenseValue, specifier: "%.0f")")
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if turf.isUnderAttack {
                        VStack(alignment: .leading) {
                            Text("🔥 Under Attack!")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text("Attacker: \(turf.attackerID ?? "Unknown")")
                                .font(.subheadline)
                            // Display attack progress
                            ProgressView(value: turf.currentDefenseHealth, total: turf.defenseValue) {
                                Text("Defense Health")
                            } currentValueLabel: {
                                Text("\(turf.currentDefenseHealth, specifier: "%.0f") / \(turf.defenseValue, specifier: "%.0f")")
                            }
                            .progressViewStyle(.linear)
                            .tint(.red)
                            
                            // Time remaining
                            if let attackStart = turf.attackStartAt {
                                Text("Time Remaining: \(max(0, turf.attackTTL - Date().timeIntervalSince(attackStart)), specifier: "%.0f")s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    
                    // New: Structures Section
                    if isPlayerOwned {
                        VStack(alignment: .leading) {
                            Text("Structures")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            if turf.structures.isEmpty {
                                Text("No structures built on this turf yet.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(turf.structures.sorted(by: { $0.type.rawValue < $1.type.rawValue }), id: \.id) { structure in
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text("\(structure.type.rawValue) (Lv\(structure.level))")
                                                .font(.subheadline)
                                            Spacer()
                                            if structure.isBuilding {
                                                ProgressView(value: structure.buildProgress) {
                                                    Text("Building")
                                                } currentValueLabel: {
                                                    Text("\(structure.buildProgress * 100, specifier: "%.0f")%")
                                                }
                                                .progressViewStyle(.linear)
                                                .tint(.orange)
                                            } else {
                                                Text("Active")
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        if !structure.isBuilding {
                                            Button("Upgrade (\(structure.type.rawValue)) - $\(structure.currentCost, specifier: "%.0f")") {
                                                gameManager.upgradeStructure(on: turf, structureID: structure.id)
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(.blue)
                                            .disabled(gameManager.walletBalance < structure.currentCost)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            
                            // Build new structures
                            VStack {
                                ForEach(Structure.StructureType.allCases, id: \.self) { type in
                                    let newStructure = Structure(type: type)
                                    let alreadyHasStructure = turf.structures.contains(where: { $0.type == type })
                                    
                                    Button("Build \(type.rawValue) - $\(newStructure.baseCost, specifier: "%.0f")") {
                                        gameManager.buildStructure(on: turf, type: type)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.purple)
                                    .disabled(gameManager.walletBalance < newStructure.baseCost || alreadyHasStructure)
                                }
                            }
                            .padding(.top, 5)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                }
                .glassCard()
                
                // Actions
                VStack(spacing: 12) {
                    if turf.isNeutral && isInRange {
                        // Capture Action
                        Button(action: {
                            HapticManager.shared.success()
                            gameManager.captureTurf(turf)
                            dismiss()
                        }) {
                            Label("Capture Turf", systemImage: "flag.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    if isPlayerOwned && isInRange {
                        // Player-owned actions
                        if turf.vaultCash > 0 {
                            Button(action: {
                                HapticManager.shared.success()
                                gameManager.collectFromTurf(turf)
                                dismiss()
                            }) {
                                Label("Collect $\(turf.vaultCash, specifier: "%.2f")", systemImage: "arrow.down.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        
                        Button(action: {
                            HapticManager.shared.impact()
                            showingInvestAlert = true
                        }) {
                            Label("Invest Cash", systemImage: "arrow.up.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // New: Reinforce Button
                        if turf.isUnderAttack && turf.ownerID == gameManager.currentPlayer?.id {
                            VStack {
                                Slider(value: $reinforceAmount, in: 10.0...min(gameManager.walletBalance, turf.defenseValue - turf.currentDefenseHealth), step: 10.0) {
                                    Text("Reinforce Amount: $\(reinforceAmount, specifier: "%.0f")")
                                }
                                .tint(.green)
                                
                                Button("Reinforce ($\(reinforceAmount, specifier: "%.0f"))") {
                                    gameManager.reinforceTurf(turf, amount: reinforceAmount)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .disabled(gameManager.walletBalance < reinforceAmount || reinforceAmount == 0)
                            }
                            .padding(.top, 5)
                        }
                    }
                    
                    if !isPlayerOwned && !turf.isNeutral && isInRange && !turf.isUnderAttack {
                        // Attack actions
                        VStack(spacing: 8) {
                            Text("Choose Weapon Pack")
                                .font(.headline)
                            
                            ForEach(WeaponPack.all) { weapon in
                                Button(action: {
                                    selectedWeapon = weapon
                                    showingAttackConfirmation = true
                                    HapticManager.shared.impact()
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(weapon.name)
                                                .fontWeight(.medium)
                                            Text("AV: \(weapon.attackValue, specifier: "%.0f")")
                                                .font(.caption)
                                        }
                                        Spacer()
                                        Text("$\(weapon.cost, specifier: "%.0f")")
                                            .fontWeight(.bold)
                                        Image(systemName: "crosshair")
                                    }
                                    .padding()
                                    .background(gameManager.walletBalance >= weapon.cost ? Color.red.opacity(0.8) : Color.gray.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .disabled(gameManager.walletBalance < weapon.cost)
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    
                    if !isInRange {
                        Text("Move closer to interact with this turf")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Turf Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Invest in Turf", isPresented: $showingInvestAlert) {
            TextField("Amount", text: $investAmount)
                .keyboardType(.decimalPad)
            Button("Invest") {
                if let amount = Double(investAmount), amount > 0 {
                    gameManager.investInTurf(turf, amount: amount)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("How much cash do you want to invest? (Available: $\(gameManager.walletBalance, specifier: "%.0f"))")
        }
        .alert("Confirm Attack", isPresented: $showingAttackConfirmation) {
            Button("Attack") {
                gameManager.attackTurf(turf, weaponPack: selectedWeapon)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Attack with \(selectedWeapon.name) for $\(selectedWeapon.cost, specifier: "%.0f")?\n\nYour AV: \(selectedWeapon.attackValue, specifier: "%.0f")\nTheir DV: \(turf.defenseValue, specifier: "%.0f")")
        }
        .onAppear {
            reinforceAmount = 10.0
        }
    }
}