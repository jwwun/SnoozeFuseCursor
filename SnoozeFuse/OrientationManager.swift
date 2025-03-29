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
            return UIDeviceOrientation.landscapeLeft.rawValue
        case .landscapeRight:
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
    
    private let userDefaultsKey = "orientationSettings"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // First initialize all properties with defaults (already done above)
        
        // Then load saved settings if available
        loadSavedSettings()
        
        // Set up observers
        setupObservers()
    }
    
    private func loadSavedSettings() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }
        
        if let savedSettings = try? JSONDecoder().decode(SavedSettings.self, from: data) {
            self.orientation = savedSettings.orientation
            self.isLockEnabled = savedSettings.isLockEnabled
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
                }
                self.saveSettings()
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
                self.saveSettings()
            }
            .store(in: &cancellables)
    }
    
    func lockOrientation() {
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
        
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    private func forciblyRotateDevice() {
        // This is a direct way to force orientation change
        UIDevice.current.setValue(orientation.deviceOrientationValue, forKey: "orientation")
        
        // For iOS 16 and later, use the more modern approach
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                do {
                    try windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation.orientationMask))
                } catch {
                    print("Could not update orientation: \(error)")
                    orientationChangeSuccess = false
                    return
                }
            }
        }
        
        // Force rotation for all iOS versions
        UIViewController.attemptRotationToDeviceOrientation()
        
        // Indicate success
        orientationChangeSuccess = true
        
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
    }
    
    private func saveSettings() {
        let settings = SavedSettings(
            orientation: orientation,
            isLockEnabled: isLockEnabled
        )
        
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadSettings() -> SavedSettings? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
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
        
        var body: some View {
            VStack(alignment: .center, spacing: 15) {
                Text("ORIENTATION LOCK")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                    .padding(.bottom, 5)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Orientation lock toggle
                Toggle("Enable Orientation Lock", isOn: $orientationManager.isLockEnabled)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                
                if orientationManager.isLockEnabled {
                    // Orientation picker
                    Picker("Orientation", selection: $orientationManager.orientation) {
                        ForEach(DeviceOrientation.allCases) { orientation in
                            Text(orientation.rawValue).tag(orientation)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Visual indicator of selected orientation with success feedback
                    ZStack {
                        // Background shape
                        RoundedRectangle(cornerRadius: 12)
                            .fill(orientationManager.orientationChangeSuccess ? 
                                  Color.green.opacity(0.2) : Color.black.opacity(0.2))
                            .frame(width: 100, height: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(orientationManager.orientationChangeSuccess ? 
                                            Color.green.opacity(0.6) : Color.gray.opacity(0.2), 
                                            lineWidth: 2)
                            )
                        
                        // iPhone icon
                        Image(systemName: orientationManager.orientation.iconName)
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.7))
                            .rotationEffect(.degrees(
                                orientationManager.orientation == .portrait ? 0 :
                                orientationManager.orientation == .portraitUpsideDown ? 180 :
                                orientationManager.orientation == .landscapeLeft ? 0 :
                                0
                            ))
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                                    .opacity(orientationManager.orientationChangeSuccess ? 1.0 : 0.0)
                                    .offset(x: 30, y: -30)
                            )
                        
                        // Lock icon
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(6)
                            .background(Color.blue.opacity(0.5))
                            .clipShape(Circle())
                            .offset(x: 30, y: 30)
                    }
                    .padding(.top, 15)
                    .animation(.easeInOut(duration: 0.3), value: orientationManager.orientation)
                    .animation(.easeInOut(duration: 0.3), value: orientationManager.orientationChangeSuccess)
                    
                    // Help text
                    Text("The app will stay in \(orientationManager.orientation.rawValue) mode until you change it. iPhoneX and above do not support Upside Down.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
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