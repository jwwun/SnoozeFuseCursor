import SwiftUI
import UIKit
import UserNotifications

// Version tracking for app updates
fileprivate let appVersionKey = "appVersion"
fileprivate let currentAppVersion = "1.0.2" // Increment when making orientation fixes

// App delegate to handle orientation
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
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
            UserDefaults.standard.synchronize()
            
            print("App updated to version \(currentAppVersion), orientation settings reset")
        }
        
        // Force portrait orientation at launch
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        
        // Reset first launch flag after a longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            OrientationManager.shared.isFirstLaunch = false
            print("First launch flag set to false")
        }
        
        // Setup notification handling
        UNUserNotificationCenter.current().delegate = self
        
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
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification with sound and banner even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification response when user taps on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the notification tap (could navigate to specific screen if needed)
        completionHandler()
    }
}

@main
struct SnoozeFuseApp: App {
    @StateObject private var timerManager = TimerManager()
    @StateObject private var orientationManager = OrientationManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            SettingsScreen()
                .environmentObject(timerManager)
                .preferredColorScheme(.dark) // Enforcing dark mode as per requirements
                .lockToOrientation(orientationManager)
                .onAppear {
                    // Force portrait orientation immediately
                    UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
                    
                    // Check notification permission on startup
                    notificationManager.checkNotificationPermission()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        // Refresh notification permission status when app becomes active
                        notificationManager.checkNotificationPermission()
                    }
                }
        }
    }
}
