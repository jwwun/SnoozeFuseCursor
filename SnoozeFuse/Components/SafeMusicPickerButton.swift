import SwiftUI

// A safe wrapper button for accessing Apple Music that won't trigger permissions until tapped
struct SafeMusicPickerButton: View {
    var onImport: (URL, String) -> Void
    @State private var showPermissionAlert = false
    @Binding var isExporting: Bool
    @State private var showMusicPickerSheet = false
    
    var body: some View {
        Button(action: handleMusicImportTap) {
            HStack {
                if isExporting {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.trailing, 4)
                }
                Label("Import from Apple Music", systemImage: "music.note")
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
        .fullScreenCover(isPresented: $showMusicPickerSheet) {
            LazyLoadedMusicPicker(onSelect: { url, name in
                showMusicPickerSheet = false
                isExporting = false
                if let url = url, !name.isEmpty {
                    onImport(url, name)
                }
            }, onCancel: {
                showMusicPickerSheet = false
                isExporting = false
            })
        }
    }
    
    private func handleMusicImportTap() {
        // Set exporting state to true to show progress
        isExporting = true
        
        // Print trace for debugging media permission issues
        print("🎵 User explicitly tapped music import button - now loading MediaPlayer framework")
        
        // Show the picker that will lazy-load MediaPlayer
        showMusicPickerSheet = true
    }
}

// A view that lazy-loads MediaPlayer only when it appears on screen
struct LazyLoadedMusicPicker: View {
    var onSelect: (URL?, String) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack {
            // Placeholder loading view while MediaPlayer loads
            Text("Loading Music Picker...")
                .font(.headline)
                .padding()
            
            ProgressView()
                .scaleEffect(1.5)
                .padding()
                
            Button("Cancel") {
                onCancel()
            }
            .padding()
        }
        .onAppear {
            // This is the ONE place we dynamically load the MediaPlayer code
            // It only happens when this view appears, which is after user taps the button
            print("🎵 LazyLoadedMusicPicker appeared - NOW loading MediaPlayer")
            
            // Small delay to ensure the loading UI is visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // This is the ONLY place that explicitly loads MediaPlayer code
                MediaPlayerHelper.shared.handleMusicImportRequest { success, _ in
                    if success {
                        // If permission is granted, use the helper to show the picker
                        MediaPlayerHelper.shared.showMusicPicker { url, name in
                            onSelect(url, name)
                        } onCancel: {
                            onCancel()
                        }
                    } else {
                        // Show permission alert if needed
                        showPermissionAlert()
                        onCancel()
                    }
                }
            }
        }
    }
    
    private func showPermissionAlert() {
        // Display alert on main thread
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Permission Required",
                message: "SnoozeFuse needs access to your Music Library to select alarm sounds. Please enable access in Settings.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString), 
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            })
            
            // Present the alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        }
    }
} 