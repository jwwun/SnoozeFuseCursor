import SwiftUI
import MediaPlayer

// SwiftUI View component for media library permission warning
struct MediaLibraryPermissionWarning: View {
    @ObservedObject var mediaLibraryManager = MediaLibraryManager.shared
    @State private var isShowingPermissionAlert = false
    var showHideButton: Bool = true
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Media Library Access Disabled")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Without Media Library access, alarms won't play when the app is in the background. Enable access for full alarm functionality.")
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
                        Image(systemName: "music.note")
                        Text("Enable Media Library")
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
                        mediaLibraryManager.hideFromMainSettings()
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
                    title: Text("Enable Media Library Access"),
                    message: Text("Media Library access is required for alarm sounds to play when the app is in the background. Would you like to enable it now?"),
                    primaryButton: .default(Text("Enable")) {
                        mediaLibraryManager.requestPermission { granted in
                            if !granted {
                                // If denied, show option to open settings
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    mediaLibraryManager.openAppSettings()
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
        .onAppear {
            // Check permission status when the view appears
            mediaLibraryManager.checkMediaLibraryPermission()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Recheck permissions when returning to foreground
                mediaLibraryManager.checkMediaLibraryPermission()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MediaLibrarySettingsOpened"))) { _ in
            // Recheck after returning from settings
            mediaLibraryManager.recheckPermissionsAfterSettings()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MediaLibraryPermissionWarning()
    }
} 