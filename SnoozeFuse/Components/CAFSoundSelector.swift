import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct CAFSoundSelector: View {
    @ObservedObject private var cafManager = CustomCAFManager.shared
    @State private var isPlaying: Bool = false
    @State private var showDocumentPicker = false
    @State private var showingManageSoundsSheet = false
    @State private var showFileFormatAlert = false
    @State private var previewPlayer: AVAudioPlayer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title and help
            HStack {
                Text("NOTIFICATION SOUND")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                
                HelpButton(helpText: "Choose a .caf sound file to play when notifications are triggered outside the app. Only .caf files are supported for iOS notifications.")
                
                Spacer()
            }
            .padding(.bottom, 3)
            
            // Format requirement warning
            Text("Note: iOS requires .caf format files for custom notification sounds")
                .font(.system(size: 12))
                .foregroundColor(.orange)
                .padding(.bottom, 5)
            
            // Sound selection and import
            HStack {
                // Dropdown menu for CAF sound selection
                Menu {
                    Button(action: {
                        cafManager.selectedCAFSoundID = nil
                        cafManager.saveCAFSounds()
                        stopPreviewSound()
                    }) {
                        HStack {
                            Text("Default System Sound")
                            if cafManager.selectedCAFSoundID == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    if !cafManager.cafSounds.isEmpty {
                        Divider()
                        
                        // Custom CAF sounds section
                        ForEach(cafManager.cafSounds) { cafSound in
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
                        
                        Divider()
                        Button(action: {
                            showingManageSoundsSheet = true
                        }) {
                            Label("Manage CAF Sounds...", systemImage: "slider.horizontal.3")
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.and.waveform.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Show the name of the selected sound or "Default System Sound"
                        if let selectedID = cafManager.selectedCAFSoundID,
                           let customSound = cafManager.cafSounds.first(where: { $0.id == selectedID }) {
                            MarqueeText(
                                text: customSound.name,
                                font: .system(size: 16, weight: .medium),
                                textColor: .white
                            )
                            .frame(height: 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            MarqueeText(
                                text: "Default System Sound",
                                font: .system(size: 16, weight: .medium),
                                textColor: .white
                            )
                            .frame(height: 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))
                    )
                }

                // Import button
                Button(action: {
                    showDocumentPicker = true
                }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.vertical, 10)
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
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isPlaying ? Color.red.opacity(0.6) : Color.purple.opacity(0.6))
                    )
                    .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .sheet(isPresented: $showDocumentPicker) {
            CAFDocumentPicker(selectedFileURL: onFileSelected)
        }
        .sheet(isPresented: $showingManageSoundsSheet) {
            ManageCAFSoundsView()
        }
        .alert("Unsupported File Format", isPresented: $showFileFormatAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Only .caf format files are supported for iOS notifications. Please select a .caf file.")
        }
        .onDisappear {
            stopPreviewSound()
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
            // Play default system sound if no CAF sound is selected
            AudioServicesPlaySystemSound(1304) // Default notification sound
            
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

// View for managing (deleting) CAF sounds
struct ManageCAFSoundsView: View {
    @ObservedObject var cafManager = CustomCAFManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("CAF Notification Sounds") {
                    if !cafManager.cafSounds.isEmpty {
                        ForEach(cafManager.cafSounds) { sound in
                            HStack {
                                Text(sound.name)
                                
                                if cafManager.selectedCAFSoundID == sound.id {
                                    Spacer()
                                    Text("Selected")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    } else {
                        Text("No CAF sounds added yet.")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About CAF Files")
                            .font(.headline)
                        
                        Text("iOS requires notification sounds to be in .caf (Core Audio Format) format. Regular audio files like MP3 or WAV won't work for notifications outside the app.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("You can convert audio files to .caf format using various online converters or audio tools like ffmpeg.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Manage CAF Sounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        let idsToDelete = offsets.map { cafManager.cafSounds[$0].id }
        
        for id in idsToDelete {
            cafManager.removeCAFSound(id: id)
        }
    }
} 