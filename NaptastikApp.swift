import SwiftUI

@main
struct NaptastikApp: App {
    @StateObject private var timerManager = TimerManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerManager)
                .environmentObject(settingsManager)
                .preferredColorScheme(.dark) // Enforcing dark mode as per requirements
        }
    }
} 