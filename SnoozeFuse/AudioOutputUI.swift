import SwiftUI
import AVFoundation

// Main audio output manager singleton
class AudioOutputManager: ObservableObject {
    static let shared = AudioOutputManager()
    
    @Published var useSpeaker: Bool = true
    @Published var isHiddenFromMainSettings: Bool = true
    @Published var connectedDeviceName: String? = nil
    
    private init() {
        // Load saved settings from UserDefaults
        self.useSpeaker = UserDefaults.standard.object(forKey: "useSpeaker") as? Bool ?? true
        
        // By default, hide from main settings and show in Advanced Settings
        // Only use saved value if it exists
        if UserDefaults.standard.object(forKey: "audioOutputUIHidden") != nil {
            self.isHiddenFromMainSettings = UserDefaults.standard.bool(forKey: "audioOutputUIHidden")
        } else {
            // Default to hidden from main settings (shown in Advanced)
            self.isHiddenFromMainSettings = true
            UserDefaults.standard.set(true, forKey: "audioOutputUIHidden")
        }
        
        // Check for connected devices
        updateConnectedDeviceName()
        
        // Add observer for route changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        print("🔊 AudioOutputManager initialized: useSpeaker = \(useSpeaker), isHidden = \(isHiddenFromMainSettings)")
    }
    
    // Handle audio route changes (when headphones/bluetooth connect/disconnect)
    @objc private func handleRouteChange(notification: Notification) {
        updateConnectedDeviceName()
    }
    
    // Update the connected device name
    func updateConnectedDeviceName() {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        
        // Look for non-built-in outputs like headphones or bluetooth
        for output in currentRoute.outputs {
            if output.portType != AVAudioSession.Port.builtInSpeaker && 
               output.portType != AVAudioSession.Port.builtInReceiver {
                self.connectedDeviceName = output.portName
                print("🔊 Found external audio device: \(output.portName) (Type: \(output.portType.rawValue))")
                return
            }
        }
        
        // No external device found
        self.connectedDeviceName = nil
        print("🔊 No external audio device detected")
    }
    
    func toggleHiddenState() {
        isHiddenFromMainSettings.toggle()
        // Save new hide state to UserDefaults
        UserDefaults.standard.set(isHiddenFromMainSettings, forKey: "audioOutputUIHidden")
    }
    
    func saveSettings() {
        UserDefaults.standard.set(useSpeaker, forKey: "useSpeaker")
    }
    
    // Apply the audio output setting to the AVAudioSession
    func applyAudioOutputSetting() {
        do {
            if useSpeaker {
                // Use built-in speaker
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                print("🔊 Audio output set to speaker")
            } else {
                // Use default route (Bluetooth if connected)
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
                print("🔊 Audio output set to default route (Bluetooth if available)")
            }
            
            // Update connected device info after changing route
            updateConnectedDeviceName()
        } catch {
            print("⚠️ Failed to set audio output: \(error)")
        }
    }
}

// Notification name for audio output UI state changes
extension Notification.Name {
    static let audioOutputUIStateChanged = Notification.Name("audioOutputUIStateChanged")
}

// Main component for displaying audio output options
struct AudioOutputUI: View {
    @ObservedObject var audioManager = AudioOutputManager.shared
    @State private var showMoveAnimation = false
    @State private var moveOutDirection: Edge = .trailing
    
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            // Header with title and help button
            HStack {
                Text("AUDIO OUTPUT")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                
                HelpButton(helpText: "Select where you want alarm audio to play from.\n\nDevice Speaker: Always uses the device's built-in speaker even if headphones or Bluetooth are connected.\n\nBluetooth/Headphones: Uses connected headphones or Bluetooth devices if available.")
                
                Spacer()
                
                // Hide/move button
                Button(action: {
                    // Set the direction for the animation
                    moveOutDirection = audioManager.isHiddenFromMainSettings ? .leading : .trailing
                    
                    // Start the exit animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showMoveAnimation = true
                    }
                    
                    // Haptic feedback
                    HapticManager.shared.trigger()
                    
                    // After animation out, toggle the state and notify observers
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        audioManager.toggleHiddenState()
                        
                        // Force a notification of change
                        audioManager.objectWillChange.send()
                        
                        // Post a notification that can be observed by both screens
                        NotificationCenter.default.post(name: .audioOutputUIStateChanged, object: nil)
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: audioManager.isHiddenFromMainSettings ? 
                              "arrow.up.left" : "arrow.down.right")
                            .font(.system(size: 9))
                        Text(audioManager.isHiddenFromMainSettings ? 
                             "To Settings" : "Hide")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(6)
                    .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.bottom, 3)
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Audio output selector buttons in a more compact layout
            HStack(spacing: 10) {
                // Device Speaker button
                Button(action: {
                    audioManager.useSpeaker = true
                    audioManager.saveSettings()
                    audioManager.applyAudioOutputSetting()
                    HapticManager.shared.trigger()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 16))
                        Text("Device Speaker")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(audioManager.useSpeaker ? .white : .white.opacity(0.6))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(audioManager.useSpeaker ? 
                                      LinearGradient(colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) : 
                                      LinearGradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            if audioManager.useSpeaker {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.7), lineWidth: 1)
                            }
                        }
                    )
                }
                
                // External device button with connection status
                Button(action: {
                    audioManager.useSpeaker = false
                    audioManager.saveSettings()
                    audioManager.applyAudioOutputSetting()
                    HapticManager.shared.trigger()
                }) {
                    VStack(spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "badge.plus.radiowaves.right")
                                .font(.system(size: 16))
                            Text("Bluetooth/Headphones")
                                .font(.system(size: 13, weight: .medium))
                        }
                        
                        // Show connected device if available
                        if let deviceName = audioManager.connectedDeviceName {
                            Text("Connected: \(deviceName)")
                                .font(.system(size: 10))
                                .foregroundColor(!audioManager.useSpeaker ? .white.opacity(0.9) : .white.opacity(0.5))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        } else {
                            Text("No device connected")
                                .font(.system(size: 10))
                                .foregroundColor(!audioManager.useSpeaker ? .white.opacity(0.7) : .white.opacity(0.4))
                                .lineLimit(1)
                        }
                    }
                    .foregroundColor(!audioManager.useSpeaker ? .white : .white.opacity(0.6))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(!audioManager.useSpeaker ? 
                                      LinearGradient(colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) : 
                                      LinearGradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            if !audioManager.useSpeaker {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.7), lineWidth: 1)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 3)
        }
        .padding(.vertical, 6)
        .offset(x: showMoveAnimation ? (moveOutDirection == .trailing ? 500 : -500) : 0)
        .onAppear {
            // Reset animation state when view appears
            showMoveAnimation = false
            
            // Apply audio output setting when UI appears
            audioManager.updateConnectedDeviceName()
            audioManager.applyAudioOutputSetting()
        }
    }
}

// Preview
struct AudioOutputUI_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
            
            AudioOutputUI()
        }
    }
} 