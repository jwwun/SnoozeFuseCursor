import SwiftUI
import UIKit
import UserNotifications
import AVFoundation
import AudioToolbox

// Version tracking for app updates
fileprivate let appVersionKey = "appVersion"
fileprivate let currentAppVersion = "1.0.2" // Increment when making orientation fixes
fileprivate let orientationFixVersion = "1.0.2" // Only change this when making orientation fixes

// App delegate to handle orientation
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register for remote notifications if needed
        application.registerForRemoteNotifications()
        
        // Configure notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Remove automatic permission request
        // requestNotificationPermissions()
        
        // Check if we're launching from a notification
        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject],
           let aps = notification["aps"] as? [String: AnyObject],
           let _ = aps["alert"] {
            // Was launched from a notification, check if it's an alarm
            print("App launched from notification")
            
            // Will play sound when the notification handler is called
        }

        // Check if this is a new version of the app that needs settings reset
        let lastRunVersion = UserDefaults.standard.string(forKey: appVersionKey) ?? ""
        let isNewVersion = lastRunVersion != currentAppVersion
        
        // If this is a specific version with orientation fixes, reset settings
        let needsOrientationReset = lastRunVersion.isEmpty || (!lastRunVersion.isEmpty &&
                                     lastRunVersion != orientationFixVersion &&
                                     currentAppVersion == orientationFixVersion)
        
        if needsOrientationReset {
            // Clear any problematic saved settings only when we have orientation fixes
            print("Orientation fix version detected, resetting orientation settings")
            OrientationManager.shared.resetSavedOrientationSettings()
        }
        
        // Always save current version
        if isNewVersion {
            UserDefaults.standard.set(currentAppVersion, forKey: appVersionKey)
            UserDefaults.standard.synchronize()
            
            print("App updated to version \(currentAppVersion)")
        }
        
        // Force portrait orientation at launch
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                do {
                    try windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                    windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                } catch {
                    print("Could not update to portrait orientation: \(error)")
                }
            }
        } else {
            // Fallback for older iOS versions
            UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        }
        
        // Reset first launch flag after a longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            OrientationManager.shared.isFirstLaunch = false
            print("First launch flag set to false")
        }
        
        // Register for background modes
        application.beginReceivingRemoteControlEvents()
        
        // Setup basic audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Apply audio output settings from user preferences
            AudioOutputManager.shared.applyAudioOutputSetting()
            
            print("Initial audio session setup succeeded with output route: \(AudioOutputManager.shared.useSpeaker ? "Speaker" : "Default/Bluetooth")")
        } catch {
            print("Warning: Failed to set up initial audio session: \(error)")
        }
        
        return true
    }
    
    // Request permissions for notifications
    private func requestNotificationPermissions() {
        // Request both regular and critical alert permissions
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { success, error in
            if success {
                print("Notification authorization granted")
                
                // Register for actions
                self.registerNotificationActions()
            } else if let error = error {
                print("Notification authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    // Add a public method to request permissions when appropriate
    func requestNotificationsPermissionWhenNeeded() {
        // Check current status before requesting
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    self.requestNotificationPermissions()
                }
            }
        }
    }
    
    // Register notification actions and categories
    private func registerNotificationActions() {
        // Define the snooze action
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 5 Minutes",
            options: .foreground
        )
        
        // Define the view action
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "Open App",
            options: .foreground
        )
        
        // Create a category for alarm notifications with actions
        let alarmCategory = UNNotificationCategory(
            identifier: "alarmCategory",
            actions: [snoozeAction, viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Register the category with the notification center
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
    
    // Handle application termination
    func applicationWillTerminate(_ application: UIApplication) {
        print("🚨 Application will terminate")
        
        // Emergency stop all vibrations at system level
        AudioPlayerManager.emergencyStopAllVibrations()
        
        // Also use notification manager directly
        NotificationManager.shared.stopVibrationAlarm()
        
        // Clean up any other audio resources
        AudioPlayerManager.shared.cleanupOnExit()
        
        // One final direct call to system APIs
        AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate)
        
        print("🔔 All cleanup complete before termination")
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
    
    // Handle notification response when user taps on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        // Check if this is our alarm notification
        if response.notification.request.identifier == "alarmNotification" {
            let actionIdentifier = response.actionIdentifier
            
            if actionIdentifier == "SNOOZE_ACTION" {
                // Snooze the alarm
                NotificationManager.shared.scheduleAlarmNotification(after: 300)
                TimerManager.shared.stopAlarmSound() // Stop current sound
            } else if actionIdentifier == UNNotificationDismissActionIdentifier {
                // User dismissed (swiped away)
                TimerManager.shared.stopAlarmSound() // Stop current sound
            } else {
                // For default action (tap body) or VIEW_ACTION ("Open App")
                // Just ensure any existing TimerManager sound is stopped.
                // The system's UNNotificationSound.defaultCritical should have played upon delivery.
                // We won't restart the custom loop here.
                print("🔔 Handling notification tap/open action. Stopping any existing TimerManager sound.")
                TimerManager.shared.stopAlarmSound() // <<< Ensure sound stops, but DO NOT call playAlarmSound() here anymore
                
                // Clear the badge count when handling notifications
                try? UNUserNotificationCenter.current().setBadgeCount(0)
            }
        }
        
        completionHandler()
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // If this is our immediate alarm notification or regular alarm notification,
        // do NOT show it in the foreground as the app UI already handles it
        if notification.request.identifier == "immediateAlarmNotification" ||
           notification.request.identifier == "alarmNotification" ||
           notification.request.identifier.starts(with: "immediateAlarm_") {
            // Pass empty options to prevent alert/sound/badge in foreground
            completionHandler([])
            
            print("🔔 Foreground alarm notification received but suppressed - app is already displaying alarm UI")
        } else {
            // For other notifications, allow standard presentation (banner, sound, badge)
            completionHandler([.banner, .sound, .badge])
        }
    }
}

@main
struct SnoozeFuseApp: App {
    @StateObject private var timerManager = TimerManager()
    @StateObject private var orientationManager = OrientationManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var audioOutputManager = AudioOutputManager.shared
    @StateObject private var mediaLibraryManager = MediaLibraryManager.shared
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
                    if #available(iOS 16.0, *) {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            do {
                                try windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                                windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                            } catch {
                                print("Could not update to portrait orientation: \(error)")
                            }
                        }
                    } else {
                        // Fallback for older iOS versions
                        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
                    }
                    
                    // Check notification permission on startup
                    notificationManager.checkNotificationPermission()
                    
                    // Check media library permission on startup
                    mediaLibraryManager.checkMediaLibraryPermission()
                    
                    // Register notification categories for alarm
                    notificationManager.registerNotificationCategories()
                    
                    // Register built-in sounds for notifications
                    TimerManager.shared.registerBuiltInSoundsForNotifications()
                    
                    // Debug log for orientation settings
                    print("App appeared: Orientation Lock: \(orientationManager.isLockEnabled), Orientation: \(orientationManager.orientation.rawValue)")
                    
                    // Load audio output settings
                    let savedIsHidden = UserDefaults.standard.bool(forKey: "audioOutputUIHidden")
                    audioOutputManager.isHiddenFromMainSettings = savedIsHidden
                    
                    // Apply audio output settings
                    audioOutputManager.applyAudioOutputSetting()
                }
                .onChange(of: scenePhase) {
                    if scenePhase == .active {
                        // Refresh notification permission status when app becomes active
                        notificationManager.checkNotificationPermission()
                        
                        // Refresh media library permission status when app becomes active
                        mediaLibraryManager.checkMediaLibraryPermission()
                        
                        // Also recheck permissions specifically after returning from settings
                        mediaLibraryManager.recheckPermissionsAfterSettings()
                        
                        // Clear the app badge number when app becomes active
                        UIApplication.shared.applicationIconBadgeNumber = 0
                        
                        // Re-apply audio output settings when app becomes active
                        audioOutputManager.applyAudioOutputSetting()
                        
                        // If we're coming from background, make sure vibrations are stopped
                        AudioPlayerManager.shared.nukeSoundAndVibration()
                    }
                    
                    // Handle app going to background
                    if scenePhase == .background {
                        print("App entering background state")
                        
                        // If any timer is running, ensure background audio is properly set up
                        if timerManager.isNapTimerRunning || timerManager.isMaxTimerRunning {
                            print("Timer is active - ensuring background audio will work")
                            // Setup background audio session AND start playing silent audio
                            timerManager.setupBackgroundAudio()
                            // Actually start playing background audio to keep app alive
                            timerManager.startBackgroundAlarmSound()
                        } else {
                            // No timers running, make sure to stop all sounds and vibrations
                            print("No timers active - stopping all sounds and vibrations")
                            AudioPlayerManager.shared.nukeSoundAndVibration()
                        }
                        
                        // Save settings
                        orientationManager.saveSettings(forceOverride: true)
                    }
                    
                    // Handle app becoming inactive
                    if scenePhase == .inactive {
                        print("App entering inactive state, saving orientation settings")
                        
                        // Only stop sounds and vibrations if no timer is active
                        if !timerManager.isNapTimerRunning && !timerManager.isMaxTimerRunning {
                            print("No timers active while going inactive - stopping all sounds")
                            AudioPlayerManager.shared.nukeSoundAndVibration()
                        }
                        
                        // Save settings
                        orientationManager.saveSettings(forceOverride: true)
                    }
                }
        }
    }
}
