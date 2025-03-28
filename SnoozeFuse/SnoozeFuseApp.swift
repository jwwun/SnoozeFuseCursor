import SwiftUI

@main
struct SnoozeFuseApp: App {
    @StateObject private var timerManager = TimerManager()
    
    var body: some Scene {
        WindowGroup {
            NapScreen()
                .environmentObject(timerManager)
                .preferredColorScheme(.dark) // Enforcing dark mode as per requirements
        }
    }
} 