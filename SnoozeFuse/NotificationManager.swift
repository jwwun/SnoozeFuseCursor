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
    @Published var isCriticalAlertsAuthorized: Bool = false
    @Published var criticalAlertsStatus: CriticalAlertStatus = .pendingApproval
    
    // Keep a reference to the scheduled alarm sound timer
    private var alarmSoundTimer: Timer?
    
    // Flag to track if notification sound is playing
    private var isNotificationSoundPlaying = false
    private var lastNotificationTime: Date?
    private var currentSoundDuration: TimeInterval = 30.0 // Default to 30s if we can't detect
    
    private enum UserDefaultsKeys {
        static let hasCheckedNotificationPermission = "hasCheckedNotificationPermission"
        static let isHiddenFromMainSettings = "isHiddenFromMainSettings"
        static let criticalAlertsStatus = "criticalAlertsStatus"
    }
    
    // Enum for critical alert status
    enum CriticalAlertStatus: String, Codable {
        case notRequested // Initial state, not yet requested
        case pendingApproval // Requested but waiting for Apple approval
        case approved // Approved and available
        case denied // Denied by Apple or user
        
        var displayString: String {
            switch self {
            case .notRequested:
                return "Not yet requested"
            case .pendingApproval:
                return "Pending Apple approval"
            case .approved:
                return "Approved"
            case .denied:
                return "Denied"
            }
        }
    }
    
    init() {
        // Load critical alerts status
        if let savedStatus = UserDefaults.standard.string(forKey: UserDefaultsKeys.criticalAlertsStatus),
           let status = CriticalAlertStatus(rawValue: savedStatus) {
            criticalAlertsStatus = status
        }
        
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
        
        // Check if we should use critical alerts (only if approved and authorized)
        let useCriticalAlerts = criticalAlertsStatus == .approved && isCriticalAlertsAuthorized
        
        // Check if we need to use a custom CAF sound
        if let cafSoundName = CustomCAFManager.shared.getSelectedCAFSoundName() {
            // Use the sound name directly for notifications
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: cafSoundName))
            print("Using custom CAF sound for notification: \(cafSoundName)")
        } else {
            // Use system default sound if no sound is selected (don't fallback to first built-in)
            content.sound = useCriticalAlerts ? UNNotificationSound.defaultCritical : UNNotificationSound.default
            print("Using system \(useCriticalAlerts ? "critical" : "default") sound for notification (no sound selected)")
        }
        
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
        stopVibrationAlarm()
    }
    
    // Function to stop alarm vibration
    func stopVibrationAlarm() {
        print("📱 NotificationManager: Stopping vibration TIMER ONLY")
        
        // 1: Stop and clear the timer (MAIN THREAD)
        DispatchQueue.main.async {
            if let timer = self.alarmSoundTimer {
                print("Invalidating NotificationManager timer")
                timer.invalidate()
                self.alarmSoundTimer = nil
            }
        }
        
        // REMOVED: Notification removal
        // REMOVED: System sound cleanup
        // REMOVED: Session resets
        // REMOVED: HapticManager call
    }
    
    // Function to clear the app badge count
    func clearBadgeCount() {
        // Use the modern approach only - the old one is deprecated
        UNUserNotificationCenter.current().setBadgeCount(0)
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
        // Only load the setting if it exists, otherwise keep our default (false)
        if defaults.object(forKey: UserDefaultsKeys.isHiddenFromMainSettings) != nil {
            isHiddenFromMainSettings = defaults.bool(forKey: UserDefaultsKeys.isHiddenFromMainSettings)
        }
    }
    
    // Save settings to UserDefaults
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isHiddenFromMainSettings, forKey: UserDefaultsKeys.isHiddenFromMainSettings)
    }
    
    // Function to trigger an immediate notification with vibration
    func triggerImmediateAlarmWithVibration() {
        print("📱 NotificationManager: Starting vibration")
        
        // First stop any existing vibration to prevent duplicates
        stopVibrationAlarm()
        
        // Make sure audio session is set up for background use - IMPORTANT FIX
        setupBackgroundAudioSession()
        
        // Simple one-time vibration to start
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // Try to get the actual duration of the selected sound
        updateCurrentSoundDuration()
        
        // Create a secure timer reference to avoid retain cycles and thread issues
        let timerRef = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { 
                timer.invalidate()
                return
            }
            
            // Run vibration on main thread
            DispatchQueue.main.async {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            
            // Add second vibration pattern with slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let _ = self else { return }
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            
            // Only send notifications when app is not in foreground
            // This prevents conflicts with the app's own alarm sound
            if UIApplication.shared.applicationState != .active {
                // Check if it's time to schedule a new notification
                let currentTime = Date()
                if let lastTime = self.lastNotificationTime {
                    // Only send a new notification if the sound duration has passed since the last one
                    // Add a small buffer (1 second) to ensure the previous sound has finished
                    let timeSinceLastNotification = currentTime.timeIntervalSince(lastTime)
                    let neededInterval = min(self.currentSoundDuration + 1.0, 30.0) // Cap at 30s
                    
                    if timeSinceLastNotification >= neededInterval {
                        print("💬 Sending next notification after waiting \(timeSinceLastNotification) seconds (sound duration is \(self.currentSoundDuration)s)")
                        self.sendAlarmNotification()
                        self.lastNotificationTime = currentTime
                    }
                } else {
                    // First run - send notification immediately
                    print("💬 Sending first notification (app in background)")
                    self.sendAlarmNotification()
                    self.lastNotificationTime = currentTime
                }
            } else {
                print("🔕 App is in foreground - skipping notification but continuing vibration")
            }
        }
        
        // Make timer more robust for background
        RunLoop.current.add(timerRef, forMode: .common)
        
        // Securely store the timer reference
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.alarmSoundTimer = timerRef
        }
    }
    
    // Setup background audio session to ensure timer continues
    private func setupBackgroundAudioSession() {
        do {
            // Configure audio session for background operation
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            print("📱 NotificationManager: Audio session configured for background")
        } catch {
            print("📱 NotificationManager: Failed to configure audio session: \(error)")
        }
    }
    
    // Get the duration of the current notification sound
    private func updateCurrentSoundDuration() {
        // Try to get the URL of the selected sound file
        if let cafSoundName = CustomCAFManager.shared.getSelectedCAFSoundName() {
            if let cafSoundURL = CustomCAFManager.shared.getSelectedCAFSoundURL() {
                if let duration = getSoundDuration(from: cafSoundURL) {
                    // We found the duration - cap it at 30 seconds (iOS limit)
                    currentSoundDuration = min(duration, 30.0)
                    print("📊 Detected notification sound duration: \(currentSoundDuration) seconds")
                    return
                }
            }
        }
        
        // If we couldn't get the duration, try the fallback built-in sound
        if let firstBuiltInSoundName = CustomCAFManager.shared.getFirstBuiltInSoundName(),
           let firstBuiltInURL = CustomCAFManager.shared.getBuiltInSoundURL(named: firstBuiltInSoundName) {
            if let duration = getSoundDuration(from: firstBuiltInURL) {
                currentSoundDuration = min(duration, 30.0)
                print("📊 Using fallback built-in sound duration: \(currentSoundDuration) seconds")
                return
            }
        }
        
        // If all else fails, use a conservative default (5 seconds)
        currentSoundDuration = 5.0
        print("📊 Could not detect sound duration, using default: \(currentSoundDuration) seconds")
    }
    
    // Helper to get sound duration from a URL
    private func getSoundDuration(from url: URL) -> TimeInterval? {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            return audioPlayer.duration
        } catch {
            print("📊 Error getting sound duration: \(error)")
            return nil
        }
    }
    
    // Helper method to send the actual notification
    private func sendAlarmNotification() {
        // Remove isNotificationSoundPlaying check as it may be preventing notifications
        guard isNotificationAuthorized else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Wake Up!"
        content.body = "Your nap time is over."
        
        // Check if we should use critical alerts (only if approved and authorized)
        let useCriticalAlerts = criticalAlertsStatus == .approved && isCriticalAlertsAuthorized
        
        // Check if we need to use a custom CAF sound
        if let cafSoundName = CustomCAFManager.shared.getSelectedCAFSoundName() {
            // Use the sound name directly for notifications
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: cafSoundName))
        } else {
            // Use system default sound if no sound is selected
            content.sound = useCriticalAlerts ? UNNotificationSound.defaultCritical : UNNotificationSound.default
        }
        
        content.categoryIdentifier = "alarmCategory"
        
        // Create trigger for immediate delivery with DIFFERENT identifier
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request with UNIQUE ID that won't conflict
        let requestID = "immediateAlarm_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: requestID,
            content: content,
            trigger: trigger
        )
        
        // Add to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling immediate notification: \(error.localizedDescription)")
            } else {
                print("Immediate background notification scheduled successfully")
            }
        }
    }
    
    // MARK: - Authorization
    func requestNotificationAuthorization() {
        // Update critical alert status to pendingApproval
        criticalAlertsStatus = .pendingApproval
        saveCriticalAlertStatus()
        
        // Use a standard request for now - when your app is approved, you'll use .criticalAlert here
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isNotificationAuthorized = granted
                self?.isCheckingPermission = false
                
                // Notify that we've requested critical alerts (even though we're not actually using them yet)
                NotificationCenter.default.post(name: .criticalAlertStatusChanged, object: nil)
            }
        }
    }
    
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
    
    // Test a CAF notification immediately with a custom sound
    func testCAFNotification() {
        // Make sure we have permission first
        guard isNotificationAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Custom Sound Test"
        content.body = "Testing your custom notification sound."
        
        // Check if we should use critical alerts (only if approved and authorized)
        let useCriticalAlerts = criticalAlertsStatus == .approved && isCriticalAlertsAuthorized
        
        // Check if we need to use a custom CAF sound
        if let cafSoundName = CustomCAFManager.shared.getSelectedCAFSoundName() {
            // Use the sound name directly for notifications
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: cafSoundName))
            print("Testing custom CAF sound: \(cafSoundName)")
        } else {
            // Use system default sound if no sound is selected
            content.sound = useCriticalAlerts ? UNNotificationSound.defaultCritical : UNNotificationSound.default
            print("Testing system \(useCriticalAlerts ? "critical" : "default") sound (no sound selected)")
        }
        
        // Create trigger for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request with unique ID
        let requestID = "cafTest_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: requestID,
            content: content,
            trigger: trigger
        )
        
        // Add to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling CAF test notification: \(error.localizedDescription)")
            } else {
                print("CAF test notification scheduled successfully")
            }
        }
    }
    
    // Function to update critical alert status
    func updateCriticalAlertStatus(_ status: CriticalAlertStatus) {
        criticalAlertsStatus = status
        saveCriticalAlertStatus()
        
        // Also update the isCriticalAlertsAuthorized flag for compatibility
        isCriticalAlertsAuthorized = (status == .approved)
        
        // Notify that the status changed
        NotificationCenter.default.post(name: .criticalAlertStatusChanged, object: nil)
    }
    
    private func saveCriticalAlertStatus() {
        UserDefaults.standard.set(criticalAlertsStatus.rawValue, forKey: UserDefaultsKeys.criticalAlertsStatus)
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
                        
                        Text("SnoozeFuse needs notifications to alert you when your nap ends when the app is in the background. Notifications will only be used for nap alarms.")
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

// Notification name extension
extension Notification.Name {
    static let criticalAlertStatusChanged = Notification.Name("criticalAlertStatusChanged")
}
