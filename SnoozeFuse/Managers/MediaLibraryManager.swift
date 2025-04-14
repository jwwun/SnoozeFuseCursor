import Foundation
import MediaPlayer
import SwiftUI

class MediaLibraryManager: ObservableObject {
    static let shared = MediaLibraryManager()
    
    @Published var isMediaLibraryAuthorized = false
    @Published var isCheckingPermission = false
    @Published var isHiddenFromMainSettings = true
    
    private enum UserDefaultsKeys {
        static let hasCheckedMediaLibraryPermission = "hasCheckedMediaLibraryPermission"
        static let isMediaLibraryWarningHidden = "isMediaLibraryWarningHidden"
    }
    
    init() {
        checkMediaLibraryPermission()
        loadSettings()
    }
    
    func checkMediaLibraryPermission() {
        isCheckingPermission = true
        let status = MPMediaLibrary.authorizationStatus()
        
        DispatchQueue.main.async { [weak self] in
            switch status {
            case .authorized:
                self?.isMediaLibraryAuthorized = true
            case .denied, .restricted, .notDetermined:
                self?.isMediaLibraryAuthorized = false
            @unknown default:
                self?.isMediaLibraryAuthorized = false
            }
            self?.isCheckingPermission = false
            
            // Save that we've checked
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasCheckedMediaLibraryPermission)
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        isCheckingPermission = true
        MPMediaLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isMediaLibraryAuthorized = status == .authorized
                self?.isCheckingPermission = false
                completion(status == .authorized)
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
            
            // Add notification so we can listen for when app returns to foreground
            NotificationCenter.default.post(name: NSNotification.Name("MediaLibrarySettingsOpened"), object: nil)
        }
    }
    
    // Function to recheck permissions when app returns to foreground
    func recheckPermissionsAfterSettings() {
        // Check after a slight delay to ensure system has updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkMediaLibraryPermission()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        isHiddenFromMainSettings = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isMediaLibraryWarningHidden)
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(isHiddenFromMainSettings, forKey: UserDefaultsKeys.isMediaLibraryWarningHidden)
    }
} 