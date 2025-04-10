import Foundation
import UserNotifications
import SwiftUI
import AVFoundation
import AudioToolbox  // Add this import for system sounds

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationAuthorized = false
    @Published var isCheckingPermission = false
    @Published var isHiddenFromMainSettings = false
    
    // Keep a reference to the scheduled alarm sound timer
    private var alarmSoundTimer: Timer?
    
    private enum UserDefaultsKeys {
        static let hasCheckedNotificationPermission = "hasCheckedNotificationPermission"
        static let isHiddenFromMainSettings = "isHiddenFromMainSettings"
    }
    
    init() {
        checkNotificationPermission()
        loadSettings()
    }
    
    func checkNotificationPermission() {
        isCheckingPermission = true
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self?.isNotificationAuthorized = true
                case .denied, .notDetermined:
                    self?.isNotificationAuthorized = false
                @unknown default:
                    self?.isNotificationAuthorized = false
                }
                self?.isCheckingPermission = false
                
                // Save that we've checked
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasCheckedNotificationPermission)
            }
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        isCheckingPermission = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isNotificationAuthorized = granted
                self?.isCheckingPermission = false
                completion(granted)
            }
        }
    }
    
    func hideFromMainSettings() {
        isHiddenFromMainSettings = true
        saveSettings()
    }
    
    func resetHiddenState() {
        isHiddenFromMainSettings = false
        saveSettings()
    }
    
    // Function to open app settings
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // Function to schedule alarm notification
    func scheduleAlarmNotification(after timeInterval: TimeInterval) {
        // Make sure we have permission first
        guard isNotificationAuthorized else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Wake Up!"
        content.body = "Your nap time is over."
        
        // Use critical alert for maximum volume
        content.sound = UNNotificationSound.defaultCritical
        
        // Important: set this category
        content.categoryIdentifier = "alarmCategory"
        
        // Set badge
        content.badge = 1
        
        // Create trigger (time-based)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "alarmNotification",
            content: content,
            trigger: trigger
        )
        
        // Add request to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully for \(timeInterval) seconds from now")
            }
        }
    }
    
    // Function to cancel pending notifications
    func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Cancel any timer
        alarmSoundTimer?.invalidate()
        alarmSoundTimer = nil
    }
    
    // Function to clear the app badge count
    func clearBadgeCount() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error clearing badge count: \(error.localizedDescription)")
            }
        }
    }
    
    // Register the alarm notification category with actions
    func registerNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 5 Minutes",
            options: UNNotificationActionOptions.foreground
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "Open App",
            options: UNNotificationActionOptions.foreground
        )
        
        let alarmCategory = UNNotificationCategory(
            identifier: "alarmCategory",
            actions: [snoozeAction, viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
    
    // Load settings from UserDefaults
    private func loadSettings() {
        let defaults = UserDefaults.standard
        isHiddenFromMainSettings = defaults.bool(forKey: UserDefaultsKeys.isHiddenFromMainSettings)
    }
    
    // Save settings to UserDefaults
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isHiddenFromMainSettings, forKey: UserDefaultsKeys.isHiddenFromMainSettings)
    }
    
    // Function to trigger an immediate notification with vibration
    func triggerImmediateAlarmWithVibration() {
        // Use the system's vibration pattern with AudioServices
        // This will vibrate the device even if sound is muted
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // For a stronger alarm-like continuous vibration pattern, we alternate between
        // system sounds and vibrations at short intervals
        
        // Start a repeating timer that alternates vibrations
        let vibrateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // First vibration (stronger)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            
            // After a short delay, add another vibration for a pattern effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
        
        // Store the timer for later cancellation
        alarmSoundTimer = vibrateTimer
        
        // Also schedule an immediate notification to use both mechanisms
        let content = UNMutableNotificationContent()
        content.title = "Wake Up!"
        content.body = "Your nap time is over."
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = "alarmCategory"
        
        // Create trigger for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request with unique ID
        let request = UNNotificationRequest(
            identifier: "immediateAlarmNotification",
            content: content,
            trigger: trigger
        )
        
        // Add request to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling immediate notification: \(error.localizedDescription)")
            } else {
                print("Immediate notification scheduled for system vibration")
            }
        }
    }
    
    // MARK: - Authorization
    func requestNotificationAuthorization() {
        // Create authorization options array
        var options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        // Add critical alerts option - requires special entitlement from Apple
        options.insert(.criticalAlert)
        
        // Request authorization
        UNUserNotificationCenter.current().requestAuthorization(options: options) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isNotificationAuthorized = true
                    print("Notification authorization granted, including critical alerts if available")
                    
                    // Register notification categories
                    self?.registerNotificationCategories()
                } else if let error = error {
                    print("Notification authorization denied: \(error.localizedDescription)")
                    self?.isNotificationAuthorized = false
                }
            }
        }
    }
    
    // Published property to track critical alerts status
    @Published var isCriticalAlertsAuthorized: Bool = false
    
    func checkCriticalAlertsAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isCriticalAlertsAuthorized = settings.criticalAlertSetting == .enabled
                print("Critical alerts authorization status: \(settings.criticalAlertSetting == .enabled ? "enabled" : "disabled")")
            }
        }
    }
    
    func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isNotificationAuthorized = settings.authorizationStatus == .authorized
                
                // Also check critical alerts authorization while we're at it
                self?.isCriticalAlertsAuthorized = settings.criticalAlertSetting == .enabled
                print("Critical alerts authorized: \(settings.criticalAlertSetting == .enabled)")
            }
        }
    }
    
    // Function to stop the vibration alarm
    func stopVibrationAlarm() {
        // Stop the vibration timer if it exists
        alarmSoundTimer?.invalidate()
        alarmSoundTimer = nil
        
        // Remove any delivered notifications
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        print("🔔 Stopped vibration alarm")
    }
}

// SwiftUI View component for notification warning
struct NotificationPermissionWarning: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @State private var isShowingPermissionAlert = false
    var showHideButton: Bool = true
    
    var body: some View {
        if !notificationManager.isNotificationAuthorized && !notificationManager.isCheckingPermission {
            VStack(alignment: .center, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications Disabled")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Enabling lets you receive alerts when your nap ends when out of app. It does not notify for anything else.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                HStack(spacing: 8) {
                    Button(action: {
                        isShowingPermissionAlert = true
                    }) {
                        HStack {
                            Image(systemName: "bell.badge")
                            Text("Enable Notifications")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                    }
                    
                    if showHideButton {
                        Button(action: {
                            notificationManager.hideFromMainSettings()
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.right.circle")
                                Text("Hide This")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [Color.gray, Color.gray.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                            )
                        }
                    }
                }
                .alert(isPresented: $isShowingPermissionAlert) {
                    Alert(
                        title: Text("Enable Notifications"),
                        message: Text("Would you like to enable notifications for alarm alerts?"),
                        primaryButton: .default(Text("Enable")) {
                            notificationManager.requestPermission { granted in
                                if !granted {
                                    // If user denied, show option to open settings
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        notificationManager.openAppSettings()
                                    }
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(15)
            .padding(.horizontal, 8)
        } else {
            EmptyView()
        }
    }
}
