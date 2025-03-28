import SwiftUI

@main
struct SnoozeFuseApp: App {
    @StateObject private var timerManager = TimerManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerManager)
                .preferredColorScheme(.dark) // Dark mode UI per requirements
        }
    }
} 