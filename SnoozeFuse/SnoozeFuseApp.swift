import SwiftUI
import UIKit

// App delegate to handle orientation
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Force portrait orientation on app launch
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        
        // Ensure we start in portrait, regardless of saved settings
        OrientationManager.shared.orientation = .portrait
        
        return true
    }
    
    // Support all orientations by default
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Always start in portrait on first launch
        if OrientationManager.shared.isFirstLaunch {
            return .portrait
        }
        
        // Use orientation manager setting
        return OrientationManager.shared.isLockEnabled ?
            OrientationManager.shared.orientation.orientationMask : .all
    }
}

@main
struct SnoozeFuseApp: App {
    @StateObject private var timerManager = TimerManager()
    @StateObject private var orientationManager = OrientationManager.shared
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            SettingsScreen()
                .environmentObject(timerManager)
                .preferredColorScheme(.dark) // Enforcing dark mode as per requirements
                .lockToOrientation(orientationManager)
                .onAppear {
                    // Start in portrait mode first
                    orientationManager.orientation = .portrait
                    orientationManager.lockOrientation()
                    
                    // Apply saved orientation setting after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        // No longer on first launch
                        orientationManager.isFirstLaunch = false
                        
                        // Only apply saved orientation if lock is enabled and not first launch
                        if orientationManager.isLockEnabled {
                            // Explicitly load settings from UserDefaults
                            if let savedSettings = orientationManager.loadSettingsFromDefaults() {
                                orientationManager.orientation = savedSettings.orientation
                                orientationManager.lockOrientation()
                                
                                // Force a save to ensure settings persist
                                orientationManager.saveSettingsToDefaults()
                            }
                        }
                    }
                }
        }
    }
}
