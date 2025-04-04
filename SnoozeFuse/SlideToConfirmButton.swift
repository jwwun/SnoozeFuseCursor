import SwiftUI

/// A slider button component that requires sliding to confirm an action
struct SlideToConfirmButton: View {
    // MARK: - Properties
    
    /// Action to perform when slider is completely dragged
    var action: () -> Void
    
    /// Direction of the slider
    var direction: Edge = .trailing
    
    /// Text label to display
    var label: String = "Slide to confirm"
    
    /// Accent color for the button and track
    var accentColor: Color = .blue
    
    /// Secondary color for various states
    var secondaryColor: Color = .white
    
    // MARK: - State
    
    /// Tracks the drag amount (0-1)
    @State private var dragAmount: CGFloat = 0
    
    /// Flag to track if slider is in "success" state
    @State private var isSuccess: Bool = false
    
    /// Width of the component frame
    @State private var frameWidth: CGFloat = 0
    
    // MARK: - Constants
    
    /// Size of the thumb/handle
    private let thumbSize: CGFloat = 54
    
    /// Minimum distance to register as complete
    private let completionThreshold: CGFloat = 0.85
    
    // MARK: - Body
    
    var body: some View {
        // Get drag direction multiplier
        let dragDirectionMultiplier: CGFloat = direction == .trailing ? 1 : -1
        
        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(accentColor.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(accentColor.opacity(0.5), lineWidth: 1)
                    )
                
                // Progress fill
                Capsule()
                    .fill(accentColor.opacity(0.4))
                    .frame(width: max(thumbSize, geometry.size.width * dragAmount))
                
                // Track label - always shows in center
                HStack {
                    if direction == .trailing {
                        Spacer()
                    }
                    
                    Text(label)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(secondaryColor)
                        .lineLimit(1)
                        .padding(.horizontal, thumbSize / 2)
                    
                    if direction == .leading {
                        Spacer()
                    }
                }
                
                // Drag handle/thumb
                ZStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    
                    Image(systemName: direction == .trailing ? "chevron.right" : "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(secondaryColor)
                }
                .offset(x: calculateThumbOffset(geometry: geometry, dragAmount: dragAmount, direction: direction))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Store frame width for calculations
                            self.frameWidth = geometry.size.width
                            
                            // Calculate new drag position as percentage
                            let dragPercentage = calculateDragPercentage(
                                value: value,
                                geometry: geometry,
                                direction: direction
                            )
                            
                            // Update drag amount with constraints
                            self.dragAmount = min(max(0, dragPercentage), 1.0)
                            
                            // Reset success state while dragging
                            if isSuccess {
                                isSuccess = false
                            }
                        }
                        .onEnded { value in
                            // Check if we should trigger action
                            if self.dragAmount > self.completionThreshold {
                                self.isSuccess = true
                                
                                // Animate to full
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    self.dragAmount = 1.0
                                }
                                
                                // Trigger haptic feedback
                                HapticManager.shared.trigger()
                                
                                // Small delay before triggering action
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    self.action()
                                    
                                    // Reset after a short delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation {
                                            self.dragAmount = 0
                                            self.isSuccess = false
                                        }
                                    }
                                }
                            } else {
                                // Spring back to start
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    self.dragAmount = 0
                                }
                            }
                        }
                )
            }
            .frame(height: 56)
            .onAppear {
                // Store frame width for calculations
                self.frameWidth = geometry.size.width
            }
        }
        .frame(height: 56)
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the drag percentage based on the drag value and direction
    private func calculateDragPercentage(value: DragGesture.Value, geometry: GeometryProxy, direction: Edge) -> CGFloat {
        let totalWidth = geometry.size.width - thumbSize
        let directionalMultiplier: CGFloat = direction == .trailing ? 1 : -1
        
        if direction == .trailing {
            return min(max(0, value.translation.width), totalWidth) / totalWidth
        } else {
            return min(max(0, -value.translation.width), totalWidth) / totalWidth
        }
    }
    
    /// Calculates the thumb offset based on drag amount and direction
    private func calculateThumbOffset(geometry: GeometryProxy, dragAmount: CGFloat, direction: Edge) -> CGFloat {
        let totalWidth = geometry.size.width - thumbSize
        
        if direction == .trailing {
            return dragAmount * totalWidth
        } else {
            // For leading direction, we start from the right side
            return geometry.size.width - thumbSize - (dragAmount * totalWidth)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        SlideToConfirmButton(
            action: { print("Slider action triggered!") },
            label: "Slide to confirm",
            accentColor: .blue
        )
        .frame(width: 280)
        
        SlideToConfirmButton(
            action: { print("Slider action triggered!") },
            direction: .leading,
            label: "Slide to go back",
            accentColor: .red
        )
        .frame(width: 280)
    }
    .padding()
    .background(Color.black)
} 