import SwiftUI

// Breaking up the UI into smaller components
struct CircleSizeControl: View {
    @ObservedObject private var circleSizeManager = CircleSizeManager.shared
    @Binding var textInputValue: String
    @FocusState private var isTextFieldFocused: Bool
    var onValueChanged: () -> Void
    
    // Animation states
    @State private var showMoveAnimation = false
    @State private var moveOutDirection: Edge = .trailing
    
    // Add debounce timer
    @State private var saveDebounceTimer: Timer? = nil
    @State private var isAdjusting: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            // Title with help button and hide/move button
            HStack {
                // Empty view for balance (same width as hide button)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 50, height: 1)
                
                Spacer()
                
                // Center title with help button
                HStack(spacing: 4) {
                    Text("CIRCLE SIZE")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.blue.opacity(0.7))
                        .tracking(3)
                    
                    HelpButton(helpText: "Directly tap the number on the left to manually input size and override the slider.\n\nEnable Full-Screen Touch Mode to make the entire screen a touchable area; the circle will become cosmetic.")
                }
                
                Spacer()
                
                // Hide/move button (right)
                Button(action: {
                    // Set the direction for the animation
                    moveOutDirection = circleSizeManager.isHiddenFromMainSettings ? .leading : .trailing
                    
                    // Start the exit animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showMoveAnimation = true
                    }
                    
                    // Haptic feedback
                    HapticManager.shared.trigger()
                    
                    // After animation out, toggle the state and notify observers
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        circleSizeManager.toggleHiddenState()
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: circleSizeManager.isHiddenFromMainSettings ? 
                              "arrow.up.left" : "arrow.down.right")
                            .font(.system(size: 9))
                        Text(circleSizeManager.isHiddenFromMainSettings ? 
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
            
            // Full-screen mode toggle
            Toggle(isOn: $circleSizeManager.isFullScreenMode) {
                Text("Full-Screen Touch Mode")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            .onChange(of: circleSizeManager.isFullScreenMode) { newValue in
                // When full-screen mode changes, save settings
                circleSizeManager.saveSettings()
            }
            .padding(.bottom, 6)
            
            // Only show circle size controls when NOT in fullscreen mode
            if !circleSizeManager.isFullScreenMode {
                // First add the slider and size input in one row
                HStack(spacing: 6) {
                    // Manual size input field
                    TextField("", text: $textInputValue)
                        .keyboardType(.numberPad)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .frame(width: 60)
                        .focused($isTextFieldFocused)
                        .onChange(of: textInputValue) { oldValue, newValue in
                            // Update the circleSize binding when the text changes.
                            // The Slider's onChange will handle the saving and callback.
                            if let newSize = Int(newValue) {
                                // Only update if the value is actually different
                                // to prevent potential update loops.
                                if circleSizeManager.circleSize != CGFloat(newSize) {
                                    circleSizeManager.circleSize = CGFloat(newSize)
                                    onValueChanged()
                                }
                            } 
                            // If input is invalid/empty, we don't update circleSize.
                            // The UI will be out of sync until a valid number or slider interaction.
                        }
                    
                    // Responsive slider
                    ResponsiveSlider(value: $circleSizeManager.circleSize, in: 100...500, step: 1) { newValue in
                        // When circleSize changes, update text and trigger callbacks
                        textInputValue = "\(Int(newValue))"
                        onValueChanged()
                        
                        // Mark as adjusting
                        isAdjusting = true
                        
                        // Cancel existing timer
                        saveDebounceTimer?.invalidate()
                        
                        // Create new debounced timer for saving
                        saveDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in    
                            // Always update models on the main thread to avoid publishing changes from background threads
                            DispatchQueue.main.async {
                                circleSizeManager.saveSettings()
                                self.isAdjusting = false
                            }
                        }
                    }
                }
                .padding(.horizontal, 6)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, 8)
        .offset(x: showMoveAnimation ? (moveOutDirection == .trailing ? 500 : -500) : 0)
        .onAppear {
            // Reset animation state when view appears
            showMoveAnimation = false
            
            // Initialize text input value
            textInputValue = "\(Int(circleSizeManager.circleSize))"
        }
    }
} 