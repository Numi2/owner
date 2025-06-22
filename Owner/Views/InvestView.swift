import SwiftUI

struct InvestView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameManager: GameManager
    
    let turf: Turf
    
    @State private var investmentAmount: String = ""
    @State private var amount: Double = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Invest in \(turf.name)")) {
                    HStack {
                        Text("$")
                        TextField("Amount", text: $investmentAmount)
                            .keyboardType(.decimalPad)
                            .onChange(of: investmentAmount) {
                                amount = Double(investmentAmount) ?? 0
                            }
                    }
                }
                
                Section {
                    Button(action: invest) {
                        Text("Confirm Investment")
                    }
                    .disabled(!isValidAmount)
                }
            }
            .navigationTitle("Invest")
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
    
    private var isValidAmount: Bool {
        return amount > 0 && amount <= gameManager.walletBalance
    }
    
    private func invest() {
        gameManager.investInTurf(turf, amount: amount)
        dismiss()
    }
} 
