import SwiftUI
import Combine
// Import the Donor model
@_exported import struct SnoozeFuse.Donor

// Manager class for handling donation shoutouts
class DonorShoutoutManager: ObservableObject {
    @Published var showShoutout = false
    @Published var selectedDonor: Donor?
    @Published var verticalPosition: CGFloat = 0
    
    // Current donors - can be updated as new donations come in
    private var donors: [Donor] = [
        Donor(name: "Jeffrey Le", amount: 91.52)
        // Add more donors here as they come in
    ]
    
    // Display a random donor shoutout
    func showRandomDonorShoutout() {
        // Don't show if already showing
        guard !showShoutout, !donors.isEmpty else { return }
        
        // 50% chance to show a shoutout
        let shouldShow = Double.random(in: 0..<1) < 0.5
        guard shouldShow else { return }
        
        // Select a random donor weighted by their donation amount
        let totalWeight = donors.reduce(0) { $0 + $1.selectionWeight }
        var randomValue = Double.random(in: 0..<totalWeight)
        
        var selectedDonorTemp: Donor? = nil
        
        for donor in donors {
            randomValue -= donor.selectionWeight
            if randomValue < 0 {
                // Found our donor
                selectedDonorTemp = donor
                break
            }
        }
        
        // If we didn't find a donor, use the first one
        if selectedDonorTemp == nil, let firstDonor = donors.first {
            selectedDonorTemp = firstDonor
        }
        
        // Set the selected donor
        self.selectedDonor = selectedDonorTemp
        
        // Pick a random vertical position (avoid top and bottom edges)
        let screenHeight = UIScreen.main.bounds.height
        verticalPosition = CGFloat.random(in: 100..<(screenHeight - 100))
        
        // Show the message
        withAnimation {
            showShoutout = true
        }
        
        // Reset after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) { // Animation + buffer time
            withAnimation {
                self.showShoutout = false
            }
            self.selectedDonor = nil
        }
    }
    
    // Add a new donor
    func addDonor(name: String, amount: Double) {
        donors.append(Donor(name: name, amount: amount))
    }
} 