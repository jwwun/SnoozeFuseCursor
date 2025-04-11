import SwiftUI
import UniformTypeIdentifiers
import MediaPlayer

// New component for alarm sound selection
struct AlarmSoundSelector: View {
    @Binding var selectedAlarm: AlarmSound
    var onPreview: () -> Void
    @State private var isPlaying: Bool = false
    @EnvironmentObject var timerManager: TimerManager
    @State private var showDocumentPicker = false
    @State private var showMusicPicker = false
    @State private var showingManageSoundsSheet = false
    @State private var musicAuthStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @State private var showPermissionAlert = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            // Title with help button
            HStack {
                Text("ALARM SOUND")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                
                HelpButton(helpText: "Choose the sound that will play as a looping alarm when your nap ends. You can select from built-in sounds or add your own custom sounds. \n\n It was not possible for me to add the Apple default alarm sounds.")
            }
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Sound selection, import, preview, and manage
            HStack {
                // Dropdown menu for alarm selection
                Menu {
                    // Built-in sounds
                    ForEach(AlarmSound.allCases.filter { $0 != .custom }) { sound in
                        Button(action: {
                            selectedAlarm = sound
                            timerManager.selectedCustomSoundID = nil
                            timerManager.saveSettings()
                        }) {
                            HStack {
                                Text(sound.rawValue)
                                if sound == selectedAlarm && timerManager.selectedCustomSoundID == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    if !timerManager.customSounds.isEmpty {
                        Divider()
                        
                        // Custom sounds section
                        ForEach(timerManager.customSounds) { customSound in
                            Button(action: {
                                selectedAlarm = .custom
                                timerManager.selectedCustomSoundID = customSound.id
                                timerManager.saveSettings()
                            }) {
                                HStack {
                                    Text(customSound.name)
                                    if selectedAlarm == .custom && timerManager.selectedCustomSoundID == customSound.id {
                                        Image(systemName: "checkmark")
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
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Show the name of the selected sound (custom or built-in)
                        if selectedAlarm == .custom, let id = timerManager.selectedCustomSoundID,
                           let customSound = timerManager.customSounds.first(where: { $0.id == id }) {
                            Text(customSound.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(selectedAlarm.rawValue)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
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

                // Menu for importing sounds from Files or Apple Music
                Menu {
                    Button(action: importCustomSound) {
                        Label("Import from Files", systemImage: "folder")
                    }

                    Button(action: requestToShowMusicPicker) {
                        HStack {
                            if timerManager.isExportingMusic {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .padding(.trailing, 4)
                            }
                            Label("Import from Apple Music", systemImage: "music.note")
                        }
                    }
                } label: {
                    // Use the folder icon as the menu label with import state
                    HStack(spacing: 4) {
                        if timerManager.isExportingMusic {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        if timerManager.isExportingMusic {
                            Text("Importing...")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                }

                // Preview/Stop toggle button
                Button(action: {
                    isPlaying.toggle()
                    if isPlaying {
                        timerManager.playAlarmSound()
                    } else {
                        timerManager.stopAlarmSound()
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
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, 8)
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(selectedFileURL: onFileSelected)
        }
        .sheet(isPresented: $showMusicPicker, onDismiss: checkMusicPermission) {
            switch musicAuthStatus {
            case .authorized:
                MusicPicker { mediaItem in
                    // Implement logic in TimerManager to handle selected mediaItem
                    self.timerManager.addMusicSound(item: mediaItem)
                }
            case .denied, .restricted:
                Text("Music Library access is required. Please enable it in Settings.")
                    .padding()
                    .onAppear { 
                        showMusicPicker = false 
                        showPermissionAlert = true
                    }
            case .notDetermined:
                Text("Requesting Music Library access...")
                    .onAppear { 
                        showMusicPicker = false
                        checkMusicPermission()
                    }
            @unknown default:
                Text("Unknown music library authorization status.")
                    .onAppear { showMusicPicker = false }
            }
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("SnoozeFuse needs access to your Music Library to select alarm sounds. Please enable access in Settings.")
        }
        .sheet(isPresented: $showingManageSoundsSheet) {
            // Present the new management view
            ManageSoundsView()
                .environmentObject(timerManager) // Pass TimerManager down
        }
        // Add onAppear handler to load custom sounds only when this view appears
        .onAppear {
            // Load custom sounds when the selector is shown
            timerManager.loadCustomSounds()
        }
    }

    private func checkMusicPermission() {
        let currentStatus = MPMediaLibrary.authorizationStatus()
        musicAuthStatus = currentStatus

        switch currentStatus {
        case .notDetermined:
            MPMediaLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    musicAuthStatus = status
                    if status == .authorized {
                        // If granted, now we *can* set showMusicPicker to true
                        // This logic might need refinement depending on user flow.
                        // For now, assume the user taps the menu item *after* this check.
                    } else {
                        // If denied, trigger the alert
                        showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            // If already denied/restricted, prepare to show alert
            // The actual alert showing is triggered by the menu action attempt.
            break // State is already set
        case .authorized:
            // Already authorized, nothing more to do here
            break
        @unknown default:
            print("Unknown Music Library authorization status encountered.")
        }
    }
    
    private func requestToShowMusicPicker() {
        checkMusicPermission()
        
        DispatchQueue.main.async {
             switch musicAuthStatus {
             case .authorized:
                 showMusicPicker = true
             case .denied, .restricted:
                 showPermissionAlert = true
             case .notDetermined:
                 MPMediaLibrary.requestAuthorization { status in
                    DispatchQueue.main.async {
                        musicAuthStatus = status
                        if status == .authorized {
                            showMusicPicker = true
                        } else {
                            showPermissionAlert = true
                        }
                    }
                 }
             @unknown default:
                 print("Cannot show music picker due to unknown auth status.")
             }
        }
    }
    
    private func importCustomSound() {
        showDocumentPicker = true
    }
    
    private func onFileSelected(_ url: URL) {
        // Set up for new sound using selected file
        let filename = url.lastPathComponent
        timerManager.addCustomSound(name: filename, fileURL: url)
    }
}

// Document Picker for selecting audio files
struct DocumentPicker: UIViewControllerRepresentable {
    var selectedFileURL: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Define the types of audio files we want to allow
        let supportedTypes: [UTType] = [.audio, .mp3, .wav]
        
        // Create a document picker with these types
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
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

// Music Picker for selecting songs from Apple Music library
struct MusicPicker: UIViewControllerRepresentable {
    // Callback to pass the selected media item
    var didPickMediaItem: (MPMediaItem) -> Void

    func makeUIViewController(context: Context) -> MPMediaPickerController {
        // Configure the picker for music
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = false
        picker.showsCloudItems = false  // Or false, depending on desired behavior
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        let parent: MusicPicker

        init(_ parent: MusicPicker) {
            self.parent = parent
        }

        // Delegate method called when item(s) are picked
        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            // Get the first item (since multiple selection is off)
            if let mediaItem = mediaItemCollection.items.first {
                parent.didPickMediaItem(mediaItem)
            }
            mediaPicker.dismiss(animated: true)
        }

        // Delegate method called when the picker is cancelled
        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            mediaPicker.dismiss(animated: true)
        }
    }
}

// View for managing (deleting) custom sounds
struct ManageSoundsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss // To close the sheet

    var body: some View {
        NavigationView { // Use NavigationView for title and Done button
            List {
                // Section for sounds imported from files
                Section("Imported Sounds") {
                    // Check if the array exists and is not empty
                    if !timerManager.customSounds.isEmpty {
                        ForEach(timerManager.customSounds) { sound in
                            Text(sound.name)
                        }
                        .onDelete(perform: deleteItems)
                    } else {
                        Text("No imported sounds yet.")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Manage Sounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle()) // Use a nice list style
        }
    }

    // Function to handle deletion from the list's swipe action
    private func deleteItems(at offsets: IndexSet) {
        // Get the IDs of the sounds to delete based on the offsets
        let idsToDelete = offsets.map { timerManager.customSounds[$0].id }
        
        // Call TimerManager to remove them
        for id in idsToDelete {
            timerManager.removeCustomSound(id: id)
        }
    }
} 