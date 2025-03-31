import SwiftUI
import UIKit

// Version tracking for app updates
fileprivate let appVersionKey = "appVersion"
fileprivate let currentAppVersion = "1.0.1" // Increment when making orientation fixes

// App delegate to handle orientation
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Check if this is a new version of the app that needs settings reset
        let lastRunVersion = UserDefaults.standard.string(forKey: appVersionKey) ?? ""
        let isNewVersion = lastRunVersion != currentAppVersion
        
        // If this is a new version with orientation fixes, reset settings
        if isNewVersion {
            // Clear any problematic saved settings
            OrientationManager.shared.resetSavedOrientationSettings()
            
            // Save current version
            UserDefaults.standard.set(currentAppVersion, forKey: appVersionKey)
        }
        
        // Force portrait orientation at launch
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        
        // Reset first launch flag after a longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            OrientationManager.shared.isFirstLaunch = false
        }
        
        return true
    }
    
    // Support all orientations by default
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Always start in portrait during first launch or when forcedInitialPortrait is true
        if OrientationManager.shared.isFirstLaunch || OrientationManager.shared.forcedInitialPortrait {
            return .portrait
        }
        
        // Use orientation manager setting after initial launch
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
                    // Force portrait orientation immediately
                    UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
                    
                    // Apply saved orientation setting after a longer delay to ensure portrait on first launch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if orientationManager.isLockEnabled && !orientationManager.isFirstLaunch && !orientationManager.forcedInitialPortrait {
                            orientationManager.lockOrientation()
                        }
                    }
                }
        }
    }
}
