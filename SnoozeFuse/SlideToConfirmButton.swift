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
    
    /// Transparency level for the control (0-1)
    var opacity: Double = 1.0
    
    // MARK: - State
    
    /// Tracks the drag amount (0-1)
    @State private var dragAmount: CGFloat = 0
    
    /// Flag to track if slider is in "success" state
    @State private var isSuccess: Bool = false
    
    /// Width of the component frame
    @State private var frameWidth: CGFloat = 0
    
    /// Animation state for the pulse effect
    @State private var isPulsing: Bool = false
    
    // MARK: - Constants
    
    /// Size of the thumb/handle
    private let thumbSize: CGFloat = 50
    
    /// Minimum distance to register as complete
    private let completionThreshold: CGFloat = 0.85
    
    // MARK: - Body
    
    var body: some View {
        // Get drag direction multiplier
        let dragDirectionMultiplier: CGFloat = direction == .trailing ? 1 : -1
        
        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background with dashed pattern
                ZStack {
                    // Solid background
                    Capsule()
                        .fill(Color.black.opacity(0.25))
                    
                    // Dashed overlay pattern for track
                    DashedTrack(isLeading: direction == .leading)
                        .stroke(accentColor.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [4, 6]))
                        .frame(height: 30)
                        .clipShape(Capsule())
                    
                    // Strong border outline
                    Capsule()
                        .stroke(accentColor.opacity(0.6), lineWidth: 2)
                }
                
                // Progress fill
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.6),
                                accentColor.opacity(0.4)
                            ]),
                            startPoint: direction == .trailing ? .leading : .trailing,
                            endPoint: direction == .trailing ? .trailing : .leading
                        )
                    )
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
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    
                    if direction == .leading {
                        Spacer()
                    }
                }
                
                // Drag handle/thumb - improved design to indicate draggability
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(accentColor.opacity(0.3))
                        .frame(width: thumbSize + 8, height: thumbSize + 8)
                        .blur(radius: 4)
                        .scaleEffect(isPulsing ? 1.15 : 1.05)
                    
                    // Main thumb
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor.opacity(1.0),
                                    accentColor.opacity(0.8)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                    
                    // Grip lines to indicate dragging
                    VStack(spacing: 4) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(secondaryColor.opacity(0.7))
                                .frame(width: 16, height: 2)
                        }
                    }
                    
                    // Direction indicator
                    Image(systemName: direction == .trailing ? "chevron.right" : "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(secondaryColor)
                        .opacity(0.9)
                        .offset(x: direction == .trailing ? 20 : -20)
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
                            
                            // Stop pulsing animation during drag
                            if isPulsing {
                                isPulsing = false
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
                                
                                // Restart pulsing animation after spring back
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.startPulseAnimation()
                                }
                            }
                        }
                )
            }
            .frame(height: 58) // Slightly taller for better visibility
            .opacity(opacity)
            .onAppear {
                // Store frame width for calculations
                self.frameWidth = geometry.size.width
                
                // Start pulsing animation
                self.startPulseAnimation()
            }
        }
        .frame(height: 58)
    }
    
    // MARK: - Helper Methods
    
    /// Start the thumb pulsing animation
    private func startPulseAnimation() {
        // Start pulse animation cycle
        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            self.isPulsing = true
        }
    }
    
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

// MARK: - Helper Views

/// Dashed track pattern that indicates direction
struct DashedTrack: Shape {
    var isLeading: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create a dashed line in the middle of the track
        let midY = rect.midY
        
        if isLeading {
            path.move(to: CGPoint(x: rect.maxX, y: midY))
            path.addLine(to: CGPoint(x: rect.minX, y: midY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: midY))
        }
        
        return path
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
            accentColor: .red,
            opacity: 0.7
        )
        .frame(width: 280)
    }
    .padding()
    .background(Color.black)
} 