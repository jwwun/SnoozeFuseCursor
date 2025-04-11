import SwiftUI

// Breaking up the UI into smaller components
struct CircleSizeControl: View {
    @Binding var circleSize: CGFloat
    @Binding var textInputValue: String
    @FocusState private var isTextFieldFocused: Bool
    var onValueChanged: () -> Void
    @EnvironmentObject var timerManager: TimerManager
    
    // Add binding for full-screen mode toggle
    @Binding var isFullScreenMode: Bool
    
    // Add debounce timer
    @State private var saveDebounceTimer: Timer? = nil
    @State private var isAdjusting: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            // Title with help button
            HStack {
                Text("CIRCLE SIZE")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                
                HelpButton(helpText: "Directly tap the number on the left to manually input size and override the slider.\n\nEnable Full-Screen Touch Mode to make the entire screen a touchable area.")
            }
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, alignment: .center)
                
            // First add the slider spanning full width
            HStack(spacing: 0) {
                ResponsiveSlider(value: $circleSize, in: 100...500, step: 1) { newValue in
                    // When circleSize changes, update text and trigger callbacks
                    textInputValue = "\(Int(newValue))"
                    onValueChanged()
                    
                    // Mark as adjusting
                    isAdjusting = true
                    
                    // Cancel existing timer
                    saveDebounceTimer?.invalidate()
                    
                    // Create new debounced timer for saving
                    saveDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in    
                        DispatchQueue.global(qos: .userInitiated).async {
                            self.timerManager.saveSettings()
                            
                            // Reset adjusting state
                            DispatchQueue.main.async {
                                self.isAdjusting = false
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Add text field and toggle in a horizontal row
            HStack {
                // Manual size input field
                TextField("", text: $textInputValue)
                    .keyboardType(.numberPad)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .frame(width: CGFloat(max(textInputValue.count, 1) * 20 + 28))
                    .focused($isTextFieldFocused)
                    .onChange(of: textInputValue) { newValue in
                        // Update the circleSize binding when the text changes.
                        // The Slider's onChange will handle the saving and callback.
                        if let newSize = Int(newValue) {
                            // Only update if the value is actually different
                            // to prevent potential update loops.
                            if circleSize != CGFloat(newSize) {
                                 circleSize = CGFloat(newSize)
                            }
                        } 
                        // If input is invalid/empty, we don't update circleSize.
                        // The UI will be out of sync until a valid number or slider interaction.
                    }
                
                Spacer()
                
                // Full-screen mode toggle
                HStack {
                    Text("Full-Screen Touch")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Toggle("", isOn: $isFullScreenMode)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                        .onChange(of: isFullScreenMode) { newValue in
                            // Save settings when toggle changes
                            timerManager.saveSettings()
                        }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, 8) // Reduced to prevent edge cutoff
        .onDisappear {
            // Clean up timer
            saveDebounceTimer?.invalidate()
            saveDebounceTimer = nil
        }
    }
} 