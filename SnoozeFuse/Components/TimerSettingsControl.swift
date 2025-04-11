import SwiftUI

// New component for timer settings
struct TimerSettingsControl: View {
    @Binding var holdDuration: TimeInterval
    @Binding var napDuration: TimeInterval
    @Binding var maxDuration: TimeInterval

    @FocusState private var focusedField: TimerField?
    @EnvironmentObject var timerManager: TimerManager
    @ObservedObject private var presetManager = PresetManager.shared
    
    // Text state for commitment message to prevent constant recalculation
    @State private var commitmentMessage: String = ""
    
    // Debounce timer for message updates
    @State private var messageUpdateTimer: Timer? = nil

    // Warning states (remain the same)
    private var isMaxLessThanNap: Bool {
        maxDuration < napDuration
    }

    private var isHoldTooLong: Bool {
        holdDuration > (maxDuration - napDuration)
    }

    enum TimerField {
        case hold, nap, max
    }
    
    // Helper to format time with appropriate unit
    private func formatTimeUnit(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        
        // Use hours format if 60 minutes or more
        if totalSeconds >= 3600 {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            
            if seconds == 0 {
                return "\(hours) hr \(minutes) min"
            } else {
                return "\(hours) hr \(minutes) min \(seconds) sec"
            }
        } 
        // Use minutes format if 60 seconds or more
        else if totalSeconds >= 60 {
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            
            if seconds == 0 {
                return "\(minutes) min"
            } else {
                return "\(minutes) min \(seconds) sec"
            }
        } 
        // Use seconds only format if less than 60 seconds
        else {
            return "\(totalSeconds) sec"
        }
    }
    
    // Update the commitment message text without triggering view updates
    private func updateCommitmentMessage() {
        let holdText = formatTimeUnit(holdDuration)
        let napText = formatTimeUnit(napDuration)
        let maxText = formatTimeUnit(maxDuration)
        
        commitmentMessage = "Release to start a \(holdText) prep countdown → \(napText) nap, with a backup limit at \(maxText)."
    }
    
    // Schedule a delayed update of the commitment message and settings save
    private func scheduleDelayedUpdate() {
        // Cancel any existing timer
        messageUpdateTimer?.invalidate()
        
        // Create a new timer with a reasonable delay
        messageUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            // Always save settings on the main thread to avoid publishing changes from background threads
            DispatchQueue.main.async {
                self.timerManager.saveSettings()
                self.updateCommitmentMessage()
            }
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 1) {
            // Title with help button (remains the same)
             HStack {
                 Text("TIMER SETTINGS")
                     .font(.system(size: 14, weight: .bold, design: .rounded))
                     .foregroundColor(Color.blue.opacity(0.7))
                     .tracking(3)
                 
                 HelpButton(helpText: "There will be a lag when first using this because it's caching. This is normal.\n\nRELEASE: When the circle is not being held, this timer counts down. Starts <NAP> timer when done.\n\nNAP: How long your nap will last.\n\nMAX: A failsafe time limit for the entire session. Alarm will sound when this hits 0.")
             }
             .padding(.bottom, 5)
             .frame(maxWidth: .infinity, alignment: .center)

            // Timer grid layout - pass bindings directly
            HStack(alignment: .top, spacing: 8) {
                // Hold Timer (Timer A)
                CuteTimePicker(
                    duration: $holdDuration, // Pass binding
                    label: "RELEASE",
                    focus: $focusedField,
                    timerField: .hold
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isHoldTooLong ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 2)
                )
                 .onChange(of: holdDuration) { _ in 
                     scheduleDelayedUpdate()
                 } // Schedule delayed save on change

                // Nap Timer (Timer B)
                CuteTimePicker(
                    duration: $napDuration, // Pass binding
                    label: "NAP",
                    focus: $focusedField,
                    timerField: .nap
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isMaxLessThanNap ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 2)
                )
                .onChange(of: napDuration) { _ in 
                    scheduleDelayedUpdate()
                } // Schedule delayed save on change

                // Max Timer (Timer C)
                CuteTimePicker(
                    duration: $maxDuration, // Pass binding
                    label: "MAX",
                    focus: $focusedField,
                    timerField: .max
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isMaxLessThanNap ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 2)
                )
                .onChange(of: maxDuration) { _ in 
                    scheduleDelayedUpdate()
                } // Schedule delayed save on change
            }
            
            // Commitment message that explains the timer process - now using pre-computed string
            Text(commitmentMessage)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle()) // Make sure it has the right hit test shape
                .allowsHitTesting(false) // Don't let it intercept touch events
                .safeMetalRendering() // Use safer Metal rendering approach

            // Subtle warning messages (remain the same)
             if isMaxLessThanNap || isHoldTooLong {
                 HStack(spacing: 4) {
                     Image(systemName: "exclamationmark.triangle.fill")
                         .font(.system(size: 12))
                     Text(isMaxLessThanNap ? "<MAX> should be greater than <NAP>" : "<Release> + <NAP> should be less than <MAX> ")
                         .font(.system(size: 12, weight: .medium))
                 }
                 .foregroundColor(Color.orange.opacity(0.8))
                 .padding(.top, 8)
             }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, 8)
        .onAppear {
            // Initialize the commitment message when the view appears
            updateCommitmentMessage()
        }
        .onDisappear {
            // Clean up timer when view disappears
            messageUpdateTimer?.invalidate()
            messageUpdateTimer = nil
        }
    }
} 