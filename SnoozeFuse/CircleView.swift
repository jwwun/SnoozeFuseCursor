//
//  CircleView.swift
//  SnoozeFuse
//
//  Created by Jonathan Truong on 3/28/25.
//

import SwiftUI

/// A customizable circular view that can display different states and text
struct CircleView: View {
    // MARK: - Properties
    
    /// The size (diameter) of the circle
    var size: CGFloat
    
    /// Whether the circle is in pressed state
    var isPressed: Bool = false
    
    /// Whether to show status text in the center
    var showStatusText: Bool = false
    
    /// Whether to show initial instructions when not pressed
    var showInitialInstructions: Bool = false
    
    /// Color when not pressed (with default)
    var normalColor: Color = .blue
    
    /// Color when pressed (with default)
    var pressedColor: Color = .blue
    
    /// Text to show when pressed (with default)
    var pressedText: String = "HOLDING"
    
    /// Text to show when not pressed (with default)
    var notPressedText: String = "RELEASED"
    
    /// Instructions text (with default)
    var instructionsText: String = "TAP AND HOLD\nTO START"
    
    /// Optional timer value to display
    var timerValue: String?
    
    /// Whether to show timer value
    var showTimer: Bool = false
    
    /// Timer text color (with default)
    var timerColor: Color = .white
    
    /// Timer progress value (0.0 to 1.0)
    var timerProgress: Double = 1.0
    
    /// Timer progress color
    var progressColor: Color = .blue
    
    /// Release timer progress value (0.0 to 1.0)
    var releaseTimerProgress: Double? = nil
    
    /// Release timer color
    var releaseTimerColor: Color = .orange
    
    /// Whether to show the timer arcs
    var showArcs: Bool = true
    
    /// Whether full-screen mode is enabled
    var isFullScreenMode: Bool = false
    
    // MARK: - Private Animation State
    
    /// State for a single sparkle particle
    private struct SparkState {
        var id = UUID()
        var offset: CGPoint = .zero
        var scale: CGFloat = 0.0
        var opacity: Double = 0.0
        var rotation: Double = 0.0
    }
    
    /// State for a single burnt particle emitting from the tip
    private struct BurntEmitParticleState {
        var id = UUID()
        var offset: CGPoint = .zero
        var scale: CGFloat = 0.0
        var opacity: Double = 0.0
    }
    
    /// State for a single burnt particle near the tip (not currently used visually but kept for potential future use)
    private struct BurntParticleState {
        var id = UUID()
        var offset: CGPoint = .zero
        var scale: CGFloat = 0.0
        var rotation: Double = 0.0
    }
    
    @State private var sparkStates: [SparkState] = Array(repeating: SparkState(), count: 12)
    @State private var burntEmitStates: [BurntEmitParticleState] = Array(repeating: BurntEmitParticleState(), count: 8)
    @State private var burntStates: [BurntParticleState] = Array(repeating: BurntParticleState(), count: 6) // Kept for potential future effects
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Show full-screen mode indicator if enabled
            if isFullScreenMode {
                fullScreenModeIndicator
            }
            
            circleBackground
            if showArcs {
                progressBar
                releaseTimerBar
                if !isPressed {
                    releaseTimerSparks
                    releaseTimerBurntEmission
                }
            }
            statusTextView
            timerTextView
        }
        .frame(width: size, height: size)
        .onAppear {
            // Initialize animations
            for i in 0..<sparkStates.count {
                resetSpark(index: i, initialDelay: Double(i) * 0.2)
            }
            for i in 0..<burntEmitStates.count {
                resetBurntEmitParticle(index: i, initialDelay: Double(i) * 0.15)
            }
            // Burnt particle initialization (currently unused visually)
            // for i in 0..<burntStates.count {
            //     resetBurntParticle(index: i, initialDelay: Double(i) * 0.1)
            // }
        }
    }
    
    // MARK: - Private Views
    
    /// Full-screen mode indicator
    private var fullScreenModeIndicator: some View {
        // Removed the dotted ring as requested
        EmptyView() // No indicator shown now
    }
    
    /// Max timer progress bar
    private var progressBar: some View {
        // Only show progress if there's a timer value
        Group {
            if showTimer && timerProgress < 1.0 {
                // Max timer progress - now positioned just outside the circle edge
                Circle()
                    .trim(from: 0, to: CGFloat(timerProgress))
                    .stroke(
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round
                        )
                    )
                    .foregroundColor(progressColor)
                    .rotationEffect(Angle(degrees: -90))
                    .padding(5) // Slight positive padding to move inward
            }
        }
    }
    
    /// Release timer progress bar (inner arc)
    private var releaseTimerBar: some View {
        // Only show if we have a release timer progress value
        Group {
            if let progress = releaseTimerProgress, progress < 1.0 {
                ZStack {
                    // Add thin black background arc for better contrast
                    Circle()
                        .trim(from: 0, to: 1.0)
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: 6,
                                lineCap: .round
                            )
                        )
                        .foregroundColor(Color.black.opacity(0.4))
                        .rotationEffect(Angle(degrees: -90))
                        .padding(25) // Same inset as the colored arc
                    
                    // Release timer arc - now thinner for more elegant look
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: 5,  // Reduced from 8 to 5
                                lineCap: .round
                            )
                        )
                        // Dynamically change color based on press state
                        .foregroundColor(isPressed ? Color.pink.opacity(0.8) : Color.white.opacity(0.8))
                        .rotationEffect(Angle(degrees: -90))
                        .padding(25) // More inset for better visual separation
                    
                    // Add burnt effect at the tip when not pressed (fuse is burning)
                    if !isPressed {
                        // Calculate the position along the arc for the burnt tip
                        let angle = 2 * .pi * CGFloat(progress) - .pi/2
                        let radius = size/2 - 25 // Match the arc radius
                        let tipPosition = CGPoint(
                            x: radius * cos(angle),
                            y: radius * sin(angle)
                        )
                        
                        // Orange-red ember glow behind the burnt tip
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.orange,
                                        Color.red.opacity(0.7),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 12
                                )
                            )
                            .frame(width: 18, height: 18)
                            .offset(x: tipPosition.x, y: tipPosition.y)
                            .blur(radius: 2)
                        
                        // Smoky grey effect just behind the burnt tip
                        Circle()
                            .fill(Color.gray.opacity(0.7))
                            .frame(width: 7, height: 7)
                            .offset(
                                x: tipPosition.x - 4,
                                y: tipPosition.y - 4
                            )
                            .blur(radius: 2.5)
                    }
                }
            }
        }
    }
    
    /// Sparking effects for the release timer to look like a burning fuse
    private var releaseTimerSparks: some View {
        Group {
            if let progress = releaseTimerProgress, progress < 1.0 {
                // Calculate the position along the arc where the spark should appear
                let angle = 2 * .pi * CGFloat(progress) - .pi/2
                
                // Add sparkles at the progress point
                ForEach(sparkStates.indices, id: \.self) { i in
                    SparkleShape()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    i % 3 == 0 ? Color.yellow : Color.orange, 
                                    i % 3 == 1 ? Color.orange : Color.red.opacity(0.9)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: i % 3 == 0 ? 12 : (i % 3 == 1 ? 9 : 7), height: i % 3 == 0 ? 12 : (i % 3 == 1 ? 9 : 7))
                        .scaleEffect(sparkStates[i].scale)
                        .opacity(sparkStates[i].opacity)
                        .rotationEffect(Angle(degrees: sparkStates[i].rotation))
                        .blur(radius: 0.2)
                        .shadow(color: .orange.opacity(0.7), radius: 3, x: 0, y: 0)
                        .offset(
                            x: (size/2 - 25) * cos(angle) + sparkStates[i].offset.x, 
                            y: (size/2 - 25) * sin(angle) + sparkStates[i].offset.y
                        )
                }
            }
        }
    }
    
    /// Emitted burnt particles from the release timer tip
    private var releaseTimerBurntEmission: some View {
        Group {
            if let progress = releaseTimerProgress, progress < 1.0 {
                // Calculate the position along the arc where the tip is
                let angle = 2 * .pi * CGFloat(progress) - .pi/2
                let radius = size/2 - 25 // Match the arc radius
                let tipPosition = CGPoint(
                    x: radius * cos(angle),
                    y: radius * sin(angle)
                )
                
                // Add small black particles emitting from the tip
                ForEach(burntEmitStates.indices, id: \.self) { i in
                    Circle()
                        .fill(
                            Color.black.opacity(i % 2 == 0 ? 0.7 : 0.5)
                        )
                        .frame(width: i % 3 == 0 ? 3 : (i % 3 == 1 ? 2 : 1.5), height: i % 3 == 0 ? 3 : (i % 3 == 1 ? 2 : 1.5))
                        .scaleEffect(burntEmitStates[i].scale)
                        .opacity(burntEmitStates[i].opacity)
                        .offset(
                            x: tipPosition.x + burntEmitStates[i].offset.x, 
                            y: tipPosition.y + burntEmitStates[i].offset.y
                        )
                        .blur(radius: 0.3)
                }
            }
        }
    }
    
    /// Create a star-shaped sparkle
    struct SparkleShape: Shape {
        func path(in rect: CGRect) -> Path {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let minDimension = min(rect.width, rect.height)
            let outerRadius = minDimension / 2
            let innerRadius = outerRadius * 0.4
            let pointCount = 4 // 4-point star like the sparkle emoji ✨
            
            var path = Path()
            
            for i in 0..<(pointCount * 2) {
                let angle = Double(i) * .pi / Double(pointCount)
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let x = center.x + CGFloat(cos(angle)) * radius
                let y = center.y + CGFloat(sin(angle)) * radius
                
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            path.closeSubpath()
            return path
        }
    }
    
    /// Reset a specific spark with animation
    private func resetSpark(index: Int, initialDelay: Double = 0) {
        // Only start animations after initial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            // Randomize properties within the state struct
            withAnimation(.easeOut(duration: 0.25)) {
                sparkStates[index].scale = CGFloat.random(in: 0.8...1.3)
                sparkStates[index].offset = CGPoint(
                    x: CGFloat.random(in: -20...20),
                    y: CGFloat.random(in: -20...20)
                )
                sparkStates[index].opacity = Double.random(in: 0.6...1.0)
                sparkStates[index].rotation = Double.random(in: 0...360)
            }
            
            // After a short delay, fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.05...0.2)) {
                withAnimation(.easeIn(duration: 0.15)) {
                    sparkStates[index].opacity = 0
                    sparkStates[index].scale = CGFloat.random(in: 0.3...0.6)
                    sparkStates[index].offset.y += CGFloat.random(in: 5...12) // More upward movement
                    sparkStates[index].offset.x += CGFloat.random(in: -5...5) // Some sideways drift
                    sparkStates[index].rotation += Double.random(in: 45...120)
                }
                
                // Restart animation after a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    resetSpark(index: index)
                }
            }
        }
    }
    
    /// Reset a specific burnt emitting particle with animation
    private func resetBurntEmitParticle(index: Int, initialDelay: Double = 0) {
        // Only start animations after initial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            // Start at the tip position using the state struct
            burntEmitStates[index].offset = CGPoint(x: 0, y: 0)
            burntEmitStates[index].scale = CGFloat.random(in: 0.8...1.2)
            burntEmitStates[index].opacity = Double.random(in: 0.6...0.9)
            
            // Calculate the opposite direction of the burning tip
            if let progress = releaseTimerProgress {
                let tipAngle = 2 * .pi * CGFloat(progress) - .pi/2
                // Add 180 degrees (pi radians) to get the opposite direction
                let oppositeAngle = tipAngle + .pi
                
                // Calculate distance to travel (much farther now)
                let distance = CGFloat.random(in: 30...60)
                
                // Add some randomness to the angle to create a spread effect
                let randomizedAngle = oppositeAngle + CGFloat.random(in: -0.3...0.3)
                
                // Animate the particle moving away from the tip in the opposite direction
                withAnimation(.easeOut(duration: Double.random(in: 1.0...2.0))) {
                    // Use the angle to determine direction vector
                    burntEmitStates[index].offset = CGPoint(
                        x: cos(randomizedAngle) * distance,
                        y: sin(randomizedAngle) * distance
                    )
                    burntEmitStates[index].scale = CGFloat.random(in: 0.3...0.6)
                    burntEmitStates[index].opacity = 0 // Fade out completely
                }
            }
            
            // Restart animation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.3...0.8)) {
                resetBurntEmitParticle(index: index)
            }
        }
    }
    
    /// Reset a specific burnt particle with animation
    private func resetBurntParticle(index: Int, initialDelay: Double = 0) {
        // Only start animations after initial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            // Randomize properties within the state struct
            withAnimation(.easeInOut(duration: Double.random(in: 0.8...1.5))) {
                // Keep particles close to the tip but give them some random movement
                burntStates[index].scale = CGFloat.random(in: 0.8...1.2)
                burntStates[index].offset = CGPoint(
                    x: CGFloat.random(in: -4...4),
                    y: CGFloat.random(in: -4...4)
                )
                burntStates[index].rotation = Double.random(in: 0...360)
            }
            
            // Restart animation after a delay for continuous subtle movement
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.8...1.5)) {
                resetBurntParticle(index: index)
            }
        }
    }
    
    /// The circle background with gradient and animation
    private var circleBackground: some View {
        ZStack {
            // Outer circle border
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: size, height: size)
            
            // Middle circle
            Circle()
                .stroke(isPressed ? pressedColor.opacity(0.4) : normalColor.opacity(0.4), lineWidth: 3)
                .frame(width: size - 20, height: size - 20)
            
            // Inner circle - changes color when pressed
            Circle()
                .fill(isPressed ? pressedColor.opacity(0.25) : normalColor.opacity(0.1))
                .frame(width: size - 30, height: size - 30)
            
            // Center fill
            Circle()
                .fill(isPressed ? pressedColor.opacity(0.4) : normalColor.opacity(0.2))
                .frame(width: size * 0.6, height: size * 0.6)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
    }
    
    /// The status text in the center of the circle
    @ViewBuilder
    private var statusTextView: some View {
        if showStatusText {
            if showInitialInstructions && !isPressed {
                Text(instructionsText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .offset(y: -20) // Move up to make room for timer if needed
            } else {
                Text(isPressed ? pressedText : notPressedText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(2)
                    .offset(y: -20) // Move up to make room for timer if needed
            }
        }
    }
    
    /// The timer text below the status text
    @ViewBuilder
    private var timerTextView: some View {
        if showTimer, let timerText = timerValue {
            // Parse the timer text to extract numbers and units
            let text = timerText // Example: "5 min 30 sec" or "5 min"
            
            // Use a HStack to display timer components with different sizes
            HStack(spacing: 1) {
                if text.contains("hr") {
                    // Handle hours format: "1 hr 30 min 45 sec" or "1 hr 30 min"
                    let components = text.split(separator: " ")
                    
                    // Group components in pairs (number, unit)
                    ForEach(0..<components.count/2, id: \.self) { pairIndex in
                        let numberIndex = pairIndex * 2
                        let unitIndex = numberIndex + 1
                        
                        if numberIndex < components.count && unitIndex < components.count {
                            Text(String(components[numberIndex]))
                                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                            
                            Text(String(components[unitIndex]))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .baselineOffset(-2)
                            
                            // Add space between components
                            if pairIndex < (components.count/2 - 1) {
                                Text(" ")
                                    .font(.system(size: 10))
                            }
                        }
                    }
                } else if text.contains("min") {
                    // Handle minutes format: "30 min 45 sec" or "30 min"
                    let components = text.split(separator: " ")
                    
                    // Group components in pairs (number, unit)
                    ForEach(0..<components.count/2, id: \.self) { pairIndex in
                        let numberIndex = pairIndex * 2
                        let unitIndex = numberIndex + 1
                        
                        if numberIndex < components.count && unitIndex < components.count {
                            Text(String(components[numberIndex]))
                                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                            
                            Text(String(components[unitIndex]))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .baselineOffset(-2)
                            
                            // Add space between components
                            if pairIndex < (components.count/2 - 1) {
                                Text(" ")
                                    .font(.system(size: 10))
                            }
                        }
                    }
                } else {
                    // Handle seconds only format: "45 sec"
                    let components = text.split(separator: " ")
                    if components.count >= 2 {
                        let number = components[0]
                        let unit = components[1]
                        
                        Text(String(number))
                            .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        
                        Text(String(unit))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .baselineOffset(-2)
                    }
                }
            }
            .foregroundColor(isPressed ? pressedColor.opacity(0.9) : timerColor)
            .offset(y: 15) // Position below status text
            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
        }
    }
}

// MARK: - Previews

struct CircleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CircleView(size: 200)
            
            CircleView(
                size: 200,
                isPressed: true,
                showStatusText: true
            )
            
            CircleView(
                size: 150,
                isPressed: false,
                showStatusText: true,
                showInitialInstructions: true,
                normalColor: .purple,
                pressedColor: .pink
            )
        }
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.black)
    }
}
