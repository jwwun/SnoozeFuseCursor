import SwiftUI

// Simple flashy animation for the logo
struct PixelateEffect: ViewModifier {
    let isActive: Bool
    @State private var glowOpacity = 0.0
    @State private var glowScale = 1.0
    @State private var rotationAngle = 0.0
    @State private var bounceScale = 1.0
    @State private var hueRotation = 0.0
    
    func body(content: Content) -> some View {
        ZStack {
            // Base content with animated effects
            content
                .scaleEffect(bounceScale)
                .rotationEffect(.degrees(rotationAngle))
                .hueRotation(Angle(degrees: hueRotation))
                .animation(isActive ? 
                    .interpolatingSpring(mass: 0.2, stiffness: 5, damping: 0.5, initialVelocity: 5) : 
                    .easeInOut(duration: 0.5), 
                    value: bounceScale)
                .animation(isActive ? 
                    .interpolatingSpring(mass: 0.2, stiffness: 3, damping: 0.6, initialVelocity: 5) : 
                    .easeInOut(duration: 0.5), 
                    value: rotationAngle)
                .animation(.easeInOut(duration: 0.5), value: hueRotation)
                
            // Glow effect with smooth animation
            if isActive {
                content
                    .blur(radius: 8)
                    .opacity(glowOpacity)
                    .scaleEffect(glowScale)
                    .blendMode(.screen)
                    .animation(.easeInOut(duration: 0.7), value: glowOpacity)
                    .animation(.easeInOut(duration: 1.2), value: glowScale)
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                startAnimations()
            } else {
                resetAnimations()
            }
        }
    }
    
    private func startAnimations() {
        // Reset state before starting
        resetAnimations() 
        
        // Phase 1: Initial pop and glow
        withAnimation(.easeIn(duration: 0.3)) {
            glowOpacity = 0.7
            glowScale = 1.2
            bounceScale = 1.1 // Initial small bounce
        }
        
        // Phase 2: Hue shift and slight rotation start
        // Use a slightly delayed start for hue to make it less abrupt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.8).repeatCount(2, autoreverses: true)) {
                hueRotation = 30
            }
        }
        
        // Phase 3: Main bounce, rotation, and glow intensification
        // Delay this slightly to let phase 1 settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
             withAnimation(.easeInOut(duration: 0.8)) {
                 // Rotate smoothly over a longer duration
                 rotationAngle = 360 
             }
             withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                 // Bigger bounce effect
                 bounceScale = 1.3
                 glowOpacity = 0.9 // Max glow
                 glowScale = 1.4   // Max glow scale
             }
        }
        
        // Phase 4: Settle back and fade out glow
        // Start settling slightly after the main bounce peak
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { // Phase 3 animation duration (0.4) + delay (0.2)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                 // Settle back towards original size
                bounceScale = 0.9 // Slight overshoot
            }
             // Fade out glow while settling
             withAnimation(.easeOut(duration: 0.8)) {
                 glowOpacity = 0.0
                 glowScale = 2.0 // Glow expands as it fades
             }
        }
        
        // Phase 5: Final settle
        // Ensure this happens after the overshoot settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { // Phase 4 settle duration (0.5) + start time (0.6) - slight overlap
             withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                 bounceScale = 1.0 // Return to normal size
             }
        }
        
         // Phase 6: Reset rotation silently after animation completes (avoids snapping)
         // Total rotation animation duration (0.8) + start delay (0.2)
         DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
             rotationAngle = 0 // Reset angle non-animated
         }
    }
    
    private func resetAnimations() {
        // Use animations for resetting too, to avoid teleporting
        withAnimation(.easeOut(duration: 0.5)) {
            glowOpacity = 0.0
            glowScale = 1.0
            hueRotation = 0.0
        }
        
        // For rotation, use a separate animation that doesn't rotate back
        if rotationAngle != 0 {
            // Find the closest multiple of 360 degrees
            let fullRotations = Int(rotationAngle / 360)
            let targetAngle = CGFloat(fullRotations + 1) * 360
            
            // First complete the rotation to the next full 360
            withAnimation(.easeInOut(duration: 0.3)) {
                rotationAngle = targetAngle
            }
            
            // Then silently reset to 0 after the animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                rotationAngle = 0
            }
        }
        
        withAnimation(.spring()) {
            bounceScale = 1.0
        }
    }
} 