import SwiftUI
import AVFoundation

// Main component for displaying volume controls
struct AudioVolumeUI: View {
    @ObservedObject var volumeManager = AudioVolumeManager.shared
    @State private var showMoveAnimation = false
    @State private var moveOutDirection: Edge = .trailing
    @State private var sliderDragging = false
    @State private var currentVolume: Float = 1.0
    
    // Format percentage for display
    private func formatPercentage(_ value: Float) -> String {
        return "\(Int(value * 100))%"
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // Header with title, help button, and toggle
            HStack {
                Text("ALARM VOLUME")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                
                HelpButton(helpText: "This controls the device volume when the alarm plays.\n\nWhen enabled, this will change your device's system volume to match the setting when the alarm sounds. The volume will go back when alarm is done")
                
                Spacer()
                
                // Hide/move button
                Button(action: {
                    // Set the direction for the animation
                    moveOutDirection = volumeManager.isHiddenFromMainSettings ? .leading : .trailing
                    
                    // Start the exit animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showMoveAnimation = true
                    }
                    
                    // Haptic feedback
                    HapticManager.shared.trigger()
                    
                    // After animation out, toggle the state and notify observers
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        volumeManager.toggleHiddenState()
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: volumeManager.isHiddenFromMainSettings ? 
                              "arrow.up.left" : "arrow.down.right")
                            .font(.system(size: 9))
                        Text(volumeManager.isHiddenFromMainSettings ? 
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
            .padding(.bottom, 2)
            
            // Main Volume Control
            VStack(alignment: .leading, spacing: 2) {
                // Force system volume toggle as primary control
                HStack {
                    Toggle(isOn: $volumeManager.forceSystemVolume) {
                        Text("Force System Volume")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: volumeManager.forceSystemVolume) { newValue in
                        volumeManager.saveSettings()
                        if newValue {
                            // When enabling, immediately apply the current volume setting
                            volumeManager.setSystemVolume(to: volumeManager.alarmVolume)
                        }
                    }
                }
                .padding(.bottom, 4)
                
                if volumeManager.forceSystemVolume {
                    // Volume slider with icons and percentage
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.1.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        
                        // A more responsive slider implementation
                        SliderView(
                            value: Binding(
                                get: { self.sliderDragging ? self.currentVolume : self.volumeManager.alarmVolume },
                                set: { newValue in
                                    self.currentVolume = newValue
                                    if !self.sliderDragging {
                                        self.volumeManager.alarmVolume = newValue
                                        
                                        // Immediately test the volume
                                        self.volumeManager.setSystemVolume(to: newValue)
                                        
                                        // Fix: Save settings after setting volume
                                        self.volumeManager.saveSettings()
                                    }
                                }
                            ),
                            range: 0.1...1.0,
                            onEditingChanged: { editing in
                                self.sliderDragging = editing
                                if !editing {
                                    // When slider is released, update the setting
                                    self.volumeManager.alarmVolume = self.currentVolume
                                    
                                    // Apply new volume to system
                                    self.volumeManager.setSystemVolume(to: self.currentVolume)
                                    
                                    // Fix: Save settings after slider is released
                                    self.volumeManager.saveSettings()
                                }
                            }
                        )
                        .accentColor(Color.blue.opacity(0.8))
                        
                        // Volume percentage display
                        Text(formatPercentage(sliderDragging ? currentVolume : volumeManager.alarmVolume))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 40, alignment: .trailing)
                            .animation(.none, value: sliderDragging)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    // Warning when force system volume is disabled
                    Text("You will still hear the alarm through Silent Mode and DnD.")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
        }
        .padding(.vertical, 6)
        .offset(x: showMoveAnimation ? (moveOutDirection == .trailing ? 500 : -500) : 0)
        .onAppear {
            // Reset animation state when view appears
            showMoveAnimation = false
            
            // Initialize current values
            currentVolume = volumeManager.alarmVolume
        }
    }
}

// Reusable slider component that matches the CircleSizeControl slider for responsiveness
public struct SliderView: View {
    @Binding var value: Float
    var range: ClosedRange<Float>
    var onEditingChanged: (Bool) -> Void
    
    // Properties for styling
    private var accentColor: Color = .blue
    
    // Public initializer
    public init(value: Binding<Float>, range: ClosedRange<Float>, onEditingChanged: @escaping (Bool) -> Void) {
        self._value = value
        self.range = range
        self.onEditingChanged = onEditingChanged
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track (for taps on the track)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: geometry.size.width, height: 40) // Increased touch area
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                self.onEditingChanged(true)
                                self.updateValue(at: gesture.location.x, in: geometry)
                            }
                            .onEnded { _ in
                                self.onEditingChanged(false)
                            }
                    )
                
                // Visible track - THICC-er
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.3))
                    .frame(width: geometry.size.width, height: 10) // Increased from 6 to 10px
                    .cornerRadius(5) // Increased to match new height
                
                // Filled portion - THICC-er
                Rectangle()
                    .foregroundColor(self.accentColor)
                    .frame(width: self.knobPosition(in: geometry), height: 10) // Increased from 6 to 10px
                    .cornerRadius(5) // Increased to match new height
                
                // Knob - THICC-er
                Circle()
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24) // Increased from 18 to 24px
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1) // Increased shadow
                    .offset(x: self.knobPosition(in: geometry) - 12) // Adjust offset for new size (half of width)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                self.onEditingChanged(true)
                                self.updateValue(at: gesture.location.x, in: geometry)
                            }
                            .onEnded { _ in
                                self.onEditingChanged(false)
                            }
                    )
            }
            .frame(height: 40) // Increased total height for touch area
        }
        .frame(height: 40) // Increased to match inner frame
    }
    
    private func knobPosition(in geometry: GeometryProxy) -> CGFloat {
        let percent = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return max(0, min(percent * geometry.size.width, geometry.size.width))
    }
    
    private func updateValue(at position: CGFloat, in geometry: GeometryProxy) {
        let percent = max(0, min(position / geometry.size.width, 1))
        let newValue = range.lowerBound + Float(percent) * (range.upperBound - range.lowerBound)
        value = newValue
    }
    
    public func accentColor(_ color: Color) -> SliderView {
        var copy = self
        copy.accentColor = color
        return copy
    }
}

struct AudioVolumeSettingsView: View {
    @ObservedObject private var volumeManager = AudioVolumeManager.shared
    @State private var volume: Float = AudioVolumeManager.shared.alarmVolume
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Alarm Volume")
                .font(.headline)
            
            // Volume slider with percentage display
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.secondary)
                
                Slider(
                    value: $volume,
                    in: 0.1...1.0,
                    step: 0.05,
                    onEditingChanged: { editing in
                        isEditing = editing
                        if !editing {
                            // When slider editing ends, update the manager
                            AudioVolumeManager.shared.alarmVolume = volume
                        }
                    }
                )
                .accentColor(.orange)
                
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.secondary)
                
                Text("\(Int(volume * 100))%")
                    .frame(width: 45, alignment: .trailing)
                    .foregroundColor(isEditing ? .orange : .secondary)
                    .font(.system(.subheadline, design: .monospaced))
            }
            
            // Info text
            Text("This volume will be used for all alarms. The system volume will be set to this level when an alarm plays.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 5)
            
            // Test volume button
            Button(action: {
                playTestSound()
            }) {
                Label("Test Volume", systemImage: "play.circle")
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 5)
        }
        .padding()
        .onAppear {
            // Initialize slider with current setting
            volume = AudioVolumeManager.shared.alarmVolume
        }
    }
    
    // Test sound function to preview volume
    private func playTestSound() {
        // Set system volume to match our setting
        AudioVolumeManager.shared.setSystemVolume(to: volume)
        
        // Play a quick test tone
        if let soundURL = Bundle.main.url(forResource: "test_tone", withExtension: "wav") {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer.volume = AudioVolumeManager.shared.getAdjustedPlayerVolume()
                audioPlayer.play()
            } catch {
                print("Error playing test sound: \(error.localizedDescription)")
            }
        } else {
            // Fallback to system sound if test tone is missing
            AudioServicesPlaySystemSound(1304) // Default system sound
        }
    }
} 