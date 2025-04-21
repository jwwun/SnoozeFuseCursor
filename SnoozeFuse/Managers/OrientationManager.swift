import SwiftUI
import UIKit
import Combine

// Enum for the different orientation options
enum DeviceOrientation: String, CaseIterable, Identifiable, Codable {
    case portrait = "Portrait"
    case portraitUpsideDown = "Upside Down"
    case landscapeLeft = "Landscape Left"
    case landscapeRight = "Landscape Right"
    
    var id: String { self.rawValue }
    
    // Convert to UIInterfaceOrientationMask
    var orientationMask: UIInterfaceOrientationMask {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        }
    }
    
    // Get appropriate device orientation value
    var deviceOrientationValue: Int {
        switch self {
        case .portrait:
            return UIDeviceOrientation.portrait.rawValue
        case .portraitUpsideDown:
            return UIDeviceOrientation.portraitUpsideDown.rawValue
        case .landscapeLeft:
            // Original mapping - do not change
            return UIDeviceOrientation.landscapeLeft.rawValue
        case .landscapeRight:
            // Original mapping - do not change
            return UIDeviceOrientation.landscapeRight.rawValue
        }
    }
    
    // Icon name for visual representation
    var iconName: String {
        switch self {
        case .portrait:
            return "iphone"
        case .portraitUpsideDown:
            return "iphone"
        case .landscapeLeft:
            return "iphone.landscape"
        case .landscapeRight:
            return "iphone.landscape"
        }
    }
}

class OrientationManager: ObservableObject {
    static let shared = OrientationManager()
    
    @Published var orientation: DeviceOrientation = .portrait
    @Published var isLockEnabled: Bool = true
    @Published var orientationChangeSuccess: Bool = false
    @Published var isFirstLaunch: Bool = true
    @Published var forcedInitialPortrait: Bool = false  // New flag to track forced portrait mode
    
    // IMPORTANT! Make the userDefaultsKey static and public so it can be accessed consistently
    static let userDefaultsKey = "orientationSettings"
    private var cancellables = Set<AnyCancellable>()
    
    fileprivate let orientationFixVersion = "1.0.2"
    
    private init() {
        // Force portrait mode at initialization
        forcedInitialPortrait = true
        
        // First load saved settings if available
        loadSavedSettings()
        
        // Force portrait mode explicitly, regardless of settings
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        
        // Set up observers
        setupObservers()
        
        // Schedule a check to reset the forced portrait flag after a longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.forcedInitialPortrait = false
        }
    }
    
    // Reset settings to force fresh start with portrait mode
    func resetSavedOrientationSettings() {
        // Clear any saved orientation settings
        UserDefaults.standard.removeObject(forKey: OrientationManager.userDefaultsKey)
        UserDefaults.standard.synchronize()
        
        // Manually set defaults
        self.orientation = .portrait
        self.isLockEnabled = true
    }
    
    private func loadSavedSettings() {
        // Print debug info about UserDefaults
        let defaults = UserDefaults.standard
        print("Attempting to load orientation settings from key '\(OrientationManager.userDefaultsKey)'")
        print("All keys in UserDefaults:")
        for key in defaults.dictionaryRepresentation().keys.sorted() {
            if key.contains("orientation") {
                print("- \(key)")
            }
        }
        
        // Try to get saved data
        if let data = defaults.data(forKey: OrientationManager.userDefaultsKey),
           let savedSettings = try? JSONDecoder().decode(SavedSettings.self, from: data) {
            // Successfully loaded saved settings
            self.orientation = savedSettings.orientation
            self.isLockEnabled = savedSettings.isLockEnabled
            print("Loaded saved orientation settings: \(orientation.rawValue), lock enabled: \(isLockEnabled)")
        } else {
            // No saved settings found, use defaults
            print("No saved orientation settings found, using defaults")
            self.orientation = .portrait
            self.isLockEnabled = true
        }
    }
    
    private func setupObservers() {
        // Observe orientation changes
        self.$orientation
            .dropFirst() // Skip the initial value
            .sink { [weak self] newValue in
                guard let self = self else { return }
                if self.isLockEnabled {
                    self.lockOrientation()
                    print("Orientation changed to: \(newValue.rawValue)")
                }
            }
            .store(in: &cancellables)
        
        // Observe lock enabled changes
        self.$isLockEnabled
            .dropFirst() // Skip the initial value
            .sink { [weak self] newValue in
                guard let self = self else { return }
                if newValue {
                    self.lockOrientation()
                } else {
                    self.unlockOrientation()
                }
                print("Orientation lock changed to: \(newValue)")
            }
            .store(in: &cancellables)
    }
    
    func lockOrientation() {
        // Don't apply user orientation during first launch or when forcedInitialPortrait is active
        if isFirstLaunch || forcedInitialPortrait {
            return
        }
        
        // Force the device to the desired orientation
        forciblyRotateDevice()
        
        // Show success feedback
        showSuccessFeedback()
        
        // Force UI update on all scenes
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
            }
        }
    }
    
    func unlockOrientation() {
        // Update orientation on controllers to allow free rotation
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
            }
        }
        
        // Use the modern approach to request orientation update
        if #available(iOS 16.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    windowScene.windows.forEach { window in
                        window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                    }
                }
            }
        } else {
            // Fallback for older iOS versions
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    private func forciblyRotateDevice() {
        // If we're in the forced initial portrait state, only allow portrait
        if isFirstLaunch || forcedInitialPortrait {
            // Use the modern approach for iOS 16+
            if #available(iOS 16.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    // The requestGeometryUpdate call can actually throw, so keep the try/catch
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
            print("Forcing portrait orientation during first launch")
            return
        }
        
        // Determine the correct orientation value based on visual appearance
        var targetValue: Int
        let targetMask: UIInterfaceOrientationMask
        
        switch orientation {
        case .portrait:
            targetValue = UIDeviceOrientation.portrait.rawValue
            targetMask = .portrait
            print("Setting orientation to portrait")
        case .portraitUpsideDown:
            targetValue = UIDeviceOrientation.portraitUpsideDown.rawValue
            targetMask = .portraitUpsideDown
            print("Setting orientation to portrait upside down")
        case .landscapeLeft:
            targetValue = UIDeviceOrientation.landscapeLeft.rawValue
            targetMask = .landscapeLeft
            print("Setting orientation to Landscape Left (UIDevice.landscapeLeft)")
        case .landscapeRight:
            targetValue = UIDeviceOrientation.landscapeRight.rawValue
            targetMask = .landscapeRight
            print("Setting orientation to Landscape Right (UIDevice.landscapeRight)")
        }
        
        // For iOS 16 and later, use the more modern approach exclusively
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                // Map our orientation to the correct mask
                print("Requesting geometry update with mask: \(targetMask)")
                
                // The requestGeometryUpdate call can actually throw, so keep the try/catch
                do {
                    try windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: targetMask))
                    
                    // Force the preferred orientation
                    windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                } catch {
                    print("Could not update orientation: \(error)")
                    orientationChangeSuccess = false
                    return
                }
            }
        } else {
            // Fallback for older iOS versions
            UIDevice.current.setValue(targetValue, forKey: "orientation")
            
            // Force rotation for all iOS versions with modern approach if available
            if #available(iOS 16.0, *) {
                for scene in UIApplication.shared.connectedScenes {
                    if let windowScene = scene as? UIWindowScene {
                        windowScene.windows.forEach { window in
                            window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                        }
                    }
                }
            } else {
                // Fallback for older iOS versions
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
        
        // Indicate success
        orientationChangeSuccess = true
        print("Orientation change successful")
        
        // Reset success indicator after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.orientationChangeSuccess = false
        }
    }
    
    private func showSuccessFeedback() {
        // Visual feedback is managed by the orientationChangeSuccess property
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Persistence
    
    private struct SavedSettings: Codable {
        let orientation: DeviceOrientation
        let isLockEnabled: Bool
        // Note: We don't persist isFirstLaunch as it should always be true when app starts fresh
    }
    
    func saveSettings(forceOverride: Bool = false) {
        // Ensure we're not in first launch mode when saving settings
        if (isFirstLaunch || forcedInitialPortrait) && !forceOverride {
            // Don't save settings during first launch or forced portrait state
            // This prevents overwriting user preferences with initial startup values
            print("Skipping save during first launch or forced portrait state")
            return
        }
        
        // Use synchronize to ensure settings are saved immediately
        let settings = SavedSettings(
            orientation: orientation,
            isLockEnabled: isLockEnabled
        )
        
        if let encoded = try? JSONEncoder().encode(settings) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: OrientationManager.userDefaultsKey)
            defaults.synchronize() // Force immediate save
            
            // Debug print to verify settings were saved
            print("Saved orientation settings to key '\(OrientationManager.userDefaultsKey)': \(orientation.rawValue), lock enabled: \(isLockEnabled)")
            
            // Debug all UserDefaults keys for orientation settings
            print("All keys in UserDefaults:")
            for key in defaults.dictionaryRepresentation().keys.sorted() {
                if key.contains("orientation") {
                    print("- \(key)")
                }
            }
        }
    }
    
    private func loadSettings() -> SavedSettings? {
        guard let data = UserDefaults.standard.data(forKey: OrientationManager.userDefaultsKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode(SavedSettings.self, from: data)
    }
}

// A SwiftUI View that embeds the orientation controller
struct OrientationLockingView: UIViewControllerRepresentable {
    @ObservedObject var orientationManager = OrientationManager.shared
    
    func makeUIViewController(context: Context) -> UIViewController {
        return OrientationAwareViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        uiViewController.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
    
    class OrientationAwareViewController: UIViewController {
        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            let manager = OrientationManager.shared
            return manager.isLockEnabled ? manager.orientation.orientationMask : .all
        }
        
        override var shouldAutorotate: Bool {
            return !OrientationManager.shared.isLockEnabled
        }
    }
}

// View modifier to apply orientation locking
extension View {
    func lockToOrientation(_ manager: OrientationManager) -> some View {
        self.background(OrientationLockingView().frame(width: 0, height: 0))
    }
}

// Extension to add orientation settings to AdvancedSettingsScreen
extension AdvancedSettingsScreen {
    struct OrientationSettings: View {
        @ObservedObject var orientationManager = OrientationManager.shared
        @State private var showUpsideDownWarning = false
        
        var body: some View {
            VStack(alignment: .center, spacing: 15) {

                // Orientation lock toggle
                Toggle("Enable Orientation Lock", isOn: $orientationManager.isLockEnabled)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    .onChange(of: orientationManager.isLockEnabled) { _ in
                        orientationManager.saveSettings(forceOverride: true)
                    }
                
                if orientationManager.isLockEnabled {
                    // Orientation buttons instead of picker
                    VStack(spacing: 10) {
                        // Portrait button
                        Button(action: {
                            orientationManager.orientation = .portrait
                            orientationManager.saveSettings(forceOverride: true)
                        }) {
                            HStack {
                                Image(systemName: "iphone")
                                    .font(.system(size: 20))
                                    .padding(.trailing, 5)
                                Text("Portrait")
                                    .font(.system(size: 16))
                                Spacer()
                                if orientationManager.orientation == .portrait {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(orientationManager.orientation == .portrait ?
                                          Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                            )
                            .foregroundColor(.white)
                        }
                        
                        // Upside Down button with warning
                        Button(action: {
                            showUpsideDownWarning = true
                        }) {
                            HStack {
                                Image(systemName: "iphone")
                                    .font(.system(size: 20))
                                    .rotationEffect(.degrees(180))
                                    .padding(.trailing, 5)
                                Text("Upside Down")
                                    .font(.system(size: 16))
                                Spacer()
                                if orientationManager.orientation == .portraitUpsideDown {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(orientationManager.orientation == .portraitUpsideDown ?
                                          Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                            )
                            .foregroundColor(.white)
                        }
                        .alert("Warning: Upside Down Not Recommended", isPresented: $showUpsideDownWarning) {
                            Button("Cancel", role: .cancel) {}
                            Button("Use Anyway") {
                                orientationManager.orientation = .portraitUpsideDown
                                orientationManager.saveSettings(forceOverride: true)
                            }
                        } message: {
                            Text("iPhoneX and newer models do not support Upside Down orientation yet. It's recommended to use Portrait mode only on these devices since the home indicator needs to be visible.")
                        }
                        
                        // Landscape Left button
                        Button(action: {
                            orientationManager.orientation = .landscapeLeft
                            orientationManager.saveSettings(forceOverride: true)
                        }) {
                            HStack {
                                Image(systemName: "iphone.landscape")
                                    .font(.system(size: 20))
                                    .padding(.trailing, 5)
                                Text("Landscape Left")
                                    .font(.system(size: 16))
                                Spacer()
                                if orientationManager.orientation == .landscapeLeft {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(orientationManager.orientation == .landscapeLeft ?
                                          Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                            )
                            .foregroundColor(.white)
                        }
                        
                        // Landscape Right button
                        Button(action: {
                            orientationManager.orientation = .landscapeRight
                            orientationManager.saveSettings(forceOverride: true)
                        }) {
                            HStack {
                                Image(systemName: "iphone.landscape")
                                    .font(.system(size: 20))
                                    .padding(.trailing, 5)
                                Text("Landscape Right")
                                    .font(.system(size: 16))
                                Spacer()
                                if orientationManager.orientation == .landscapeRight {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(orientationManager.orientation == .landscapeRight ?
                                          Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                            )
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Visual success indication
                    if orientationManager.orientationChangeSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Orientation changed successfully!")
                                .foregroundColor(.green)
                        }
                        .padding(.top, 8)
                    }
                    
                    // Recommendation text
                    VStack(spacing: 8) {
                        Text("This is in-app so you don't need to use your own devices built in orientation lock. It's mainly for iPad. Your settings will be saved between app sessions.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Text("Note: Saved orientation settings take a few seconds to apply on startup.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        // iPhone landscape warning
                        if UIDevice.current.userInterfaceIdiom == .phone && 
                           (orientationManager.orientation == .landscapeLeft || orientationManager.orientation == .landscapeRight) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 14))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("⚠️ WARNING: iPhone Landscape Mode")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.orange)
                                    
                                    Text("UI elements may not fit properly in landscape on iPhone. Some controls could be cut off or difficult to access. App is optimized for portrait mode only.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange.opacity(0.8))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.top, 8)
                        }
                        
                        // iPad warning - orientation lock doesn't work
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("⚠️ WARNING: iPad Not Supported")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.red)
                                    
                                    Text("The orientation lock feature does not work properly on iPad devices. Please use your device's built-in orientation lock instead.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.top, 8)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal)
                } else {
                    // Disabled state message
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.left.arrow.right.circle")
                            .font(.system(size: 24))
                        Text("Orientation lock is disabled.\nYour device will rotate freely.")
                            .font(.system(size: 14))
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(15)
            .padding(.horizontal, 8)
        }
    }
} 
