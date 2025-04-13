import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

// Extension to get display name for sounds
extension CustomCAFSound {
    var displayName: String {
        return name
    }
}

// Custom alert overlay modifier to ensure it's at the top level
struct CAFInfoAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var dontShowAgain: Bool
    var onConfirm: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                // Full-screen semi-transparent background
                Color.black.opacity(0.6)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        isPresented = false
                    }
                
                // Alert content
                VStack(spacing: 16) {
                    // Header
                    Text("Custom Notifications Warning")
                        .font(.headline)
                        .padding(.top, 15)
                    
                    // Content - ensure text doesn't get cut off
                    Text("Only .caf format files can be used for these custom iOS notifications. You can easily convert using a tool online.\n\niOS limits notification sounds to 30 seconds maximum.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                    
                    // Toggle with adequate padding - fix text cutoff
                    HStack {
                        Toggle("Don't show again", isOn: $dontShowAgain)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .font(.system(size: 14))
                    }
                    .padding(.horizontal, 16)
                    
                    // Button
                    Button(action: onConfirm) {
                        Text("OK")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 30)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 15)
                }
                .frame(width: 280)
                .background(
                    BlurView(style: .systemThinMaterial)
                        .cornerRadius(16)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                // Use ZIndex to ensure it's above everything else
                .zIndex(999)
            }
        }
    }
}

// Extension for View to easily apply the custom alert
extension View {
    func cafInfoAlert(
        isPresented: Binding<Bool>,
        dontShowAgain: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.modifier(CAFInfoAlertModifier(
            isPresented: isPresented,
            dontShowAgain: dontShowAgain,
            onConfirm: onConfirm
        ))
    }
}

struct CAFSoundSelector: View {
    @ObservedObject private var cafManager = CustomCAFManager.shared
    @State private var isPlaying: Bool = false
    @State private var showDocumentPicker = false
    @State private var showingManageSoundsSheet = false
    @State private var showFileFormatAlert = false
    @State private var showCAFInfoSheet = false
    @State private var dontShowCAFInfoAgain = false
    @State private var previewPlayer: AVAudioPlayer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title and help
            HStack {

                    Text("NOTIFICATION SOUND")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.blue.opacity(0.7))
                        .tracking(3)
                    

                
                HelpButton(helpText: "Choose a sound to play when notifications are triggered outside the app. The built-in alarm sounds are also available for notifications.")
                
                Spacer()
            }
            .padding(.bottom, 3)
            
            // Sound selection and import
            HStack {
                // Dropdown menu for CAF sound selection
                Menu {
                    if !cafManager.cafSounds.isEmpty {
                        // Built-in sounds section
                        Section(header: Text("Built-in Sounds")) {
                            ForEach(cafManager.cafSounds.filter { $0.isBuiltIn }) { cafSound in
                                Button(action: {
                                    cafManager.selectedCAFSoundID = cafSound.id
                                    cafManager.saveCAFSounds()
                                    stopPreviewSound()
                                }) {
                                    HStack {
                                        Text(cafSound.name)
                                        if cafManager.selectedCAFSoundID == cafSound.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Custom sounds section (only show if there are custom sounds)
                        if cafManager.cafSounds.contains(where: { !$0.isBuiltIn }) {
                            Section(header: Text("Detected .caf Sounds")) {
                                ForEach(cafManager.cafSounds.filter { !$0.isBuiltIn }) { cafSound in
                                    Button(action: {
                                        cafManager.selectedCAFSoundID = cafSound.id
                                        cafManager.saveCAFSounds()
                                        stopPreviewSound()
                                    }) {
                                        HStack {
                                            Text(cafSound.name)
                                            if cafManager.selectedCAFSoundID == cafSound.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        Button(action: {
                            showingManageSoundsSheet = true
                        }) {
                            Label("Manage Sounds...", systemImage: "slider.horizontal.3")
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        // Create a fixed-width container for the marquee
                        ZStack(alignment: .leading) {
                            // Show the name of the selected sound
                            if let selectedID = cafManager.selectedCAFSoundID,
                               let customSound = cafManager.cafSounds.first(where: { $0.id == selectedID }) {
                                MarqueeText(
                                    text: customSound.name,
                                    font: .system(size: 16, weight: .medium),
                                    textColor: .white
                                )
                            } else if let firstSound = cafManager.cafSounds.first(where: { $0.isBuiltIn }) {
                                // Fallback to first built-in sound if nothing selected
                                MarqueeText(
                                    text: firstSound.name,
                                    font: .system(size: 16, weight: .medium),
                                    textColor: .white.opacity(0.7)
                                )
                            } else {
                                // Ultimate fallback if no sounds available
                                MarqueeText(
                                    text: "No sounds available",
                                    font: .system(size: 16, weight: .medium),
                                    textColor: .white.opacity(0.5)
                                )
                            }
                        }
                        .frame(width: 170, alignment: .leading)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))
                    )
                }

                // Import button
                Button(action: {
                    // Show the CAF info sheet if user hasn't chosen to hide it
                    if !UserDefaults.standard.bool(forKey: "dontShowCAFInfoAlert") {
                        showCAFInfoSheet = true
                    } else {
                        // Go straight to document picker if user has disabled the alert
                        showDocumentPicker = true
                    }
                }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                }

                // Preview/Stop toggle button
                Button(action: {
                    if isPlaying {
                        stopPreviewSound()
                    } else {
                        playPreviewSound()
                    }
                }) {
                    HStack(spacing: 7) {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 16))
                        Text(isPlaying ? "Stop" : "Test")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isPlaying ? Color.red.opacity(0.6) : Color.purple.opacity(0.6))
                    )
                    .foregroundColor(.white)
                }
            }
        }
        .cafInfoAlert(
            isPresented: $showCAFInfoSheet,
            dontShowAgain: $dontShowCAFInfoAgain,
            onConfirm: {
                // Save the preference if user chose not to show again
                if dontShowCAFInfoAgain {
                    UserDefaults.standard.set(true, forKey: "dontShowCAFInfoAlert")
                }
                // Open document picker
                showDocumentPicker = true
                showCAFInfoSheet = false
            }
        )
        .sheet(isPresented: $showDocumentPicker) {
            CAFDocumentPicker(selectedFileURL: onFileSelected)
        }
        .sheet(isPresented: $showingManageSoundsSheet) {
            ManageCAFSoundsView()
        }
        .alert("Unsupported File Format", isPresented: $showFileFormatAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Only .caf format files are supported for notification sounds. Please select a .caf file.")
        }
        .onDisappear {
            stopPreviewSound()
        }
        .onAppear {
            // Load user preference
            dontShowCAFInfoAgain = UserDefaults.standard.bool(forKey: "dontShowCAFInfoAlert")
        }
    }
    
    private func onFileSelected(_ url: URL) {
        // Check if it's a .caf file
        if url.pathExtension.lowercased() != "caf" {
            showFileFormatAlert = true
            return
        }
        
        // Add the CAF sound
        let filename = url.lastPathComponent
        if let newSound = cafManager.addCAFSound(name: filename, fileURL: url) {
            // Auto-select the newly added sound
            cafManager.selectedCAFSoundID = newSound.id
            cafManager.saveCAFSounds()
        }
    }
    
    private func playPreviewSound() {
        stopPreviewSound() // Stop any existing playback
        
        if let selectedURL = cafManager.getSelectedCAFSoundURL() {
            do {
                previewPlayer = try AVAudioPlayer(contentsOf: selectedURL)
                previewPlayer?.prepareToPlay()
                previewPlayer?.play()
                isPlaying = true
            } catch {
                print("Error playing CAF sound: \(error)")
                isPlaying = false
            }
        } else {
            // Play default system alert sound (this is similar to the iOS notification alert sound)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) // Vibrate first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                AudioServicesPlaySystemSound(1304) // Standard iOS notification sound
            }
            
            // Since system sounds don't have duration, we'll simulate a short playback
            isPlaying = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isPlaying = false
            }
        }
    }
    
    private func stopPreviewSound() {
        previewPlayer?.stop()
        previewPlayer = nil
        isPlaying = false
    }
}

// UIKit Blur View for SwiftUI
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// Document Picker specifically for CAF files
struct CAFDocumentPicker: UIViewControllerRepresentable {
    var selectedFileURL: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Define CAF file type
        let cafType = UTType(filenameExtension: "caf")!
        
        // Create a document picker with CAF type
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [cafType])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: CAFDocumentPicker
        
        init(_ parent: CAFDocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            
            // Call the callback with the selected URL
            parent.selectedFileURL(url)
            
            // Stop accessing the security-scoped resource
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
} 