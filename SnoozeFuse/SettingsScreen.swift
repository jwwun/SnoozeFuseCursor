import SwiftUI
import UserNotifications
import MediaPlayer

// This file uses components that have been moved to separate files
// CircleSizeControl, TimerSettingsControl, etc. are now defined in the Components directory

struct SettingsScreen: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var showPreview = false
    @State private var previewTimer: Timer?
    @State private var textInputValue: String = ""
    @FocusState private var isAnyFieldFocused: Bool
    @State private var showNapScreen = false  // State for showing nap screen
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var mediaLibraryManager = MediaLibraryManager.shared
    @ObservedObject private var presetManager = PresetManager.shared
    @ObservedObject private var alarmSoundManager = AlarmSoundManager.shared
    @ObservedObject private var circleSizeManager = CircleSizeManager.shared
    @State private var presetsRefreshTrigger = false // Force view updates for presets
    @State private var audioOutputRefreshTrigger = false // Force view updates for audio output UI
    @State private var volumeRefreshTrigger = false // Force view updates for volume UI
    @State private var alarmSoundRefreshTrigger = false // Force view updates for alarm sound UI
    @State private var circleSizeRefreshTrigger = false // Force view updates for circle size UI
    @AppStorage("hasVisitedTutorial") private var hasVisitedTutorial = false
    
    var body: some View {
        ZStack {
            NavigationView {
                ZStack {
                    // Background
                    Color.black.opacity(0.9).ignoresSafeArea()
                    
                    // Dismiss keyboard when tapping background
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isAnyFieldFocused = false
                            hideKeyboard()
                        }
                    
                    // ScrollView with better spacing
                    ScrollView {
                        VStack(spacing: 8) {
                            // App title at the top - now with pixel animation!
                            HStack {
                                Image("logotransparent")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 132, height: 66)
                                    .scaleEffect(0.8)
                                    // Use safe Metal rendering that avoids errors
                                    .safeMetalRendering(isEnabled: true)
                                    .modifier(PixelateEffect(isActive: timerManager.isLogoAnimating))
                                    .onTapGesture {
                                        if !timerManager.isLogoAnimating {
                                            timerManager.isLogoAnimating = true
                                            // Play haptic feedback
                                            HapticManager.shared.trigger()
                                            // Reset animation flag after animation completes
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                                timerManager.isLogoAnimating = false
                                            }
                                        }
                                    }
                                
                                Spacer()
                                
                                // Basics button - clean text-only style, precise hitbox
                                NavigationLink(destination: AboutScreen().onDisappear {
                                    // Mark as visited when user returns from About screen
                                    hasVisitedTutorial = true
                                }) {
                                    if hasVisitedTutorial {
                                        // After viewing - just a small info icon
                                        ZStack {
                                            // Empty Color view to define exact hitbox area
                                            Color.clear
                                                .frame(width: 30, height: 30)
                                            
                                            Image(systemName: "info.circle")
                                                .font(.system(size: 22)) // Slightly larger for visibility
                                                .foregroundColor(.white.opacity(0.2))
                                        }
                                    } else {
                                        // First time - simple text without button styling
                                        HStack(spacing: 5) {
                                            Image(systemName: "info.circle.fill")
                                                .font(.system(size: 18))
                                            Text("Basics")
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                        }
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, -8) // topleft corner
                            .padding(.top, -33) // make it go into the ui status boundary
                            .padding(.bottom, 0)
                            
                            // Notification permission warning - only show if not hidden from main settings
                            if !notificationManager.isHiddenFromMainSettings {
                                NotificationPermissionWarning()
                            }
                            
                            // Media Library permission warning - only show if not hidden from main settings AND not authorized
                            if !mediaLibraryManager.isHiddenFromMainSettings && !mediaLibraryManager.isMediaLibraryAuthorized {
                                MediaLibraryPermissionWarning()
                            }
                            
                            // Circle size control - only show if not hidden from main settings
                            if !circleSizeManager.isHiddenFromMainSettings {
                                CircleSizeControl(
                                    textInputValue: $textInputValue,
                                    onValueChanged: showPreviewBriefly
                                )
                            }
                            
                            // Timer Settings Section
                            TimerSettingsControl(
                                holdDuration: $timerManager.holdDuration,
                                napDuration: $timerManager.napDuration,
                                maxDuration: $timerManager.maxDuration
                            )
                            
                            // Audio UI Group
                            if !AudioOutputManager.shared.isHiddenFromMainSettings || !AudioVolumeManager.shared.isHiddenFromMainSettings || !AlarmSoundManager.shared.isHiddenFromMainSettings {
                                VStack(alignment: .center, spacing: 3) {
                                    Text("AUDIO SETTINGS")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(Color.blue.opacity(0.7))
                                        .tracking(3)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    
                                    // Audio Output UI - only show if not hidden
                                    if !AudioOutputManager.shared.isHiddenFromMainSettings {
                                        AudioOutputUI()
                                    }
                                    
                                    // Audio Volume UI - only show if not hidden
                                    if !AudioVolumeManager.shared.isHiddenFromMainSettings {
                                        AudioVolumeUI()
                                    }
                                    
                                    // Alarm Sound UI - only show if not hidden
                                    if !AlarmSoundManager.shared.isHiddenFromMainSettings {
                                        AlarmSoundSelector(
                                            selectedAlarm: $timerManager.selectedAlarmSound,
                                            onPreview: timerManager.previewAlarmSound
                                        )
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(15)
                                .padding(.horizontal, 8)
                                .id("audioGroup-\(audioOutputRefreshTrigger)-\(volumeRefreshTrigger)-\(alarmSoundRefreshTrigger)")
                            }
                            
                            // Start button
                            bottomButtonBar
                                .padding(.top, 6)
                            
                            // Add extra padding at the bottom for better scrolling
                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(.horizontal, 5)
                    }
                    .scrollIndicators(.hidden) // Hide scroll indicators for cleaner look
                    .simultaneousGesture(DragGesture().onChanged { _ in }) // Add empty gesture to ensure proper propagation
                    .focusable(false) // Prevent focus to ensure scrolling takes priority
                    .focused($isAnyFieldFocused)
                    .allowsHitTesting(true) // Explicitly allow hit testing
                    
                    // Global keyboard dismissal button and loading overlay
                    VStack {
                        Spacer()
                        if isAnyFieldFocused {
                            Button(action: {
                                isAnyFieldFocused = false
                                hideKeyboard()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 32))
                                    Text("CONFIRM")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 20)
                                .frame(minWidth: 300)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "66BB6A"), Color(hex: "43A047")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(30)
                                .shadow(color: Color(hex: "43A047").opacity(0.7), radius: 12, x: 0, y: 6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.green, lineWidth: 3)
                                        .blur(radius: 3)
                                        .opacity(0.7)
                                )
                            }
                            .padding(.bottom, 40)
                            .padding(.horizontal, 20)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAnyFieldFocused)
                        }
                    }
                }
                .navigationBarHidden(true)
            }
            
            // Completely separate preview overlay that doesn't affect layout
            if showPreview {
                CirclePreviewOverlay(
                    isVisible: $showPreview
                )
            }
        }
        .onAppear {
            textInputValue = "\(Int(circleSizeManager.circleSize))"
            
            // Add observer for preset UI state changes
            NotificationCenter.default.addObserver(forName: .presetUIStateChanged, object: nil, queue: .main) { _ in
                // Toggle the refresh trigger to force UI update
                withAnimation {
                    self.presetsRefreshTrigger.toggle()
                }
            }
            
            // Add observer for audio output UI state changes
            NotificationCenter.default.addObserver(forName: .audioOutputUIStateChanged, object: nil, queue: .main) { _ in
                // Toggle the refresh trigger to force UI update
                withAnimation {
                    self.audioOutputRefreshTrigger.toggle()
                }
            }
            
            // Add observer for volume UI state changes
            NotificationCenter.default.addObserver(forName: .audioVolumeUIStateChanged, object: nil, queue: .main) { _ in
                // Toggle the refresh trigger to force UI update
                withAnimation {
                    self.volumeRefreshTrigger.toggle()
                }
            }
            
            // Add observer for alarm sound UI state changes
            NotificationCenter.default.addObserver(forName: .alarmSoundUIStateChanged, object: nil, queue: .main) { _ in
                // Toggle the refresh trigger to force UI update
                withAnimation {
                    self.alarmSoundRefreshTrigger.toggle()
                }
            }
            
            // Add observer for circle size UI state changes
            NotificationCenter.default.addObserver(forName: .circleSizeUIStateChanged, object: nil, queue: .main) { _ in
                // Toggle the refresh trigger to force UI update
                withAnimation {
                    self.circleSizeRefreshTrigger.toggle()
                }
            }
        }
        .onDisappear {
            // Remove the observers when view disappears
            NotificationCenter.default.removeObserver(self, name: .presetUIStateChanged, object: nil)
            NotificationCenter.default.removeObserver(self, name: .audioOutputUIStateChanged, object: nil)
            NotificationCenter.default.removeObserver(self, name: .audioVolumeUIStateChanged, object: nil)
            NotificationCenter.default.removeObserver(self, name: .alarmSoundUIStateChanged, object: nil)
            NotificationCenter.default.removeObserver(self, name: .circleSizeUIStateChanged, object: nil)
        }
    }
    
    private var bottomButtonBar: some View {
        VStack {
            // Circular Start button
            Button(action: {
                showNapScreen = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 5) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 50))
                        Text("Start")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
            }
            
            // Advanced Settings button
            NavigationLink(destination: AdvancedSettingsScreen()) {
                VStack(spacing: 8) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 20))
                    Text("Advanced")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 100, height: 70)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 30)
        .fullScreenCover(isPresented: $showNapScreen) {
            NapScreen()
                .environmentObject(timerManager)
        }
    }
    
    private func showPreviewBriefly() {
        // Cancel existing timer if any
        previewTimer?.invalidate()
        
        // Show preview
        showPreview = true
        
        // Set timer to hide preview after 1 second for better visibility
        previewTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.5)) {
                showPreview = false
            }
        }
    }
    
    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(TimerManager())
        .preferredColorScheme(.dark)
} 
