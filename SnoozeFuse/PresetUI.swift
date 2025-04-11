import SwiftUI

// Main component for displaying presets
struct PresetUI: View {
    @ObservedObject var presetManager = PresetManager.shared
    @EnvironmentObject var timerManager: TimerManager
    @State private var showingRenameAlert = false
    @State private var renameId: UUID?
    @State private var newPresetName = ""
    @State private var lastTappedPreset: UUID?
    @State private var showMoveAnimation = false
    @State private var moveOutDirection: Edge = .trailing
    
    // Format timer values to a compact string
    private func formatTimers(holdDuration: TimeInterval, napDuration: TimeInterval, maxDuration: TimeInterval) -> String {
        let holdStr = formatTime(holdDuration)
        let napStr = formatTime(napDuration)
        let maxStr = formatTime(maxDuration)
        
        return "\(holdStr)→\(napStr)→\(maxStr)"
    }
    
    // Format a single duration
    private func formatTime(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        
        if seconds >= 60 && seconds % 60 == 0 {
            return "\(seconds / 60)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // Header with title and help button
            HStack {
                Text("PRESETS")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(2)
                
                HelpButton(helpText: "Tap a preset to apply those timer settings instantly.\n\nTap '+' to add your current timer settings as a new preset.\n\nLong press a preset to rename or delete it.")
                
                Spacer()
                
                // Hide/move button
                Button(action: {
                    // Set the direction for the animation
                    moveOutDirection = presetManager.isHiddenFromMainSettings ? .leading : .trailing
                    
                    // Start the exit animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showMoveAnimation = true
                    }
                    
                    // Haptic feedback
                    HapticManager.shared.trigger()
                    
                    // After animation out, toggle the state and notify observers
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        presetManager.toggleHiddenState()
                        
                        // Force a notification of change
                        presetManager.objectWillChange.send()
                        
                        // Post a notification that can be observed by both screens
                        NotificationCenter.default.post(name: .presetUIStateChanged, object: nil)
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: presetManager.isHiddenFromMainSettings ? 
                              "arrow.up.left" : "arrow.down.right")
                            .font(.system(size: 9))
                        Text(presetManager.isHiddenFromMainSettings ? 
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
            .padding(.bottom, 0)
            
            // No presets view
            if presetManager.presets.isEmpty {
                HStack {
                    Text("No presets - Tap '+' to add")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                    
                    // Add preset button
                    Button(action: {
                        presetManager.createNewPreset(from: timerManager)
                        HapticManager.shared.trigger()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 2)
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: 2) {
                    // Presets horizontal scroll view
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(presetManager.presets) { preset in
                                PresetBox(
                                    preset: preset,
                                    isSelected: lastTappedPreset == preset.id,
                                    onTap: {
                                        // Apply the preset
                                        presetManager.applyPreset(preset, to: timerManager)
                                        
                                        // Visual feedback
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            lastTappedPreset = preset.id
                                            
                                            // Reset after feedback duration
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                withAnimation {
                                                    lastTappedPreset = nil
                                                }
                                            }
                                        }
                                        
                                        // Haptic feedback
                                        HapticManager.shared.trigger()
                                    },
                                    onRename: {
                                        // Show rename alert
                                        renameId = preset.id
                                        newPresetName = preset.name
                                        showingRenameAlert = true
                                    },
                                    onDelete: {
                                        // Delete the preset
                                        presetManager.deletePreset(id: preset.id)
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 0)
                        .padding(.leading, 2)
                        .padding(.trailing, 2)
                    }
                    .frame(height: 50)
                    
                    // Add preset button
                    Button(action: {
                        presetManager.createNewPreset(from: timerManager)
                        HapticManager.shared.trigger()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(Color.black.opacity(0.25))
        .cornerRadius(10)
        .padding(.horizontal, 0)
        .padding(.top, -8) // Use negative padding at the top
        .padding(.bottom, -4) // Use negative padding at the bottom
        .offset(x: showMoveAnimation ? (moveOutDirection == .trailing ? 500 : -500) : 0)
        .alert("Rename Preset", isPresented: $showingRenameAlert) {
            TextField("Preset Name", text: $newPresetName)
                .autocapitalization(.words)
            
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let id = renameId {
                    presetManager.renamePreset(id: id, newName: newPresetName)
                }
            }
        } message: {
            Text("Enter a new name for this preset.")
        }
        .onAppear {
            // Reset animation state when view appears
            showMoveAnimation = false
        }
    }
}

// Individual preset box component
struct PresetBox: View {
    let preset: PresetItem
    let isSelected: Bool
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    
    // Format timer values to a compact string
    private func formatTimers() -> String {
        let holdStr = formatTime(preset.holdDuration)
        let napStr = formatTime(preset.napDuration)
        let maxStr = formatTime(preset.maxDuration)
        
        return "\(holdStr)→\(napStr)→\(maxStr)"
    }
    
    // Format a single duration
    private func formatTime(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        
        if seconds >= 60 && seconds % 60 == 0 {
            return "\(seconds / 60)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    @State private var showContextMenu = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            // Preset name
            Text(preset.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Timer values
            Text(formatTimers())
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .frame(width: 100, height: 50)
        .background(
            ZStack {
                // Fill
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? 
                          LinearGradient(colors: [Color.green.opacity(0.3), Color.blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) : 
                          LinearGradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                // Border
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green.opacity(0.7) : Color.gray.opacity(0.5), lineWidth: 1)
            }
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button(action: onRename) {
                Label("Rename", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// Preview
struct PresetUI_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
            
            PresetUI()
                .environmentObject(TimerManager())
        }
    }
} 