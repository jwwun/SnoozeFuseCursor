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
    
    /// Random offsets for spark positions
    @State private var sparkOffsets: [CGPoint] = Array(repeating: .zero, count: 12)
    @State private var sparkScales: [CGFloat] = Array(repeating: 0.0, count: 12)
    @State private var sparkOpacities: [Double] = Array(repeating: 0.0, count: 12)
    @State private var sparkRotations: [Double] = Array(repeating: 0.0, count: 12)
    
    /// Random properties for burnt particles that emit from the tip
    @State private var burntEmitOffsets: [CGPoint] = Array(repeating: .zero, count: 8)
    @State private var burntEmitScales: [CGFloat] = Array(repeating: 0.0, count: 8)
    @State private var burntEmitOpacities: [Double] = Array(repeating: 0.0, count: 8)
    
    /// Random properties for burnt particles
    @State private var burntOffsets: [CGPoint] = Array(repeating: .zero, count: 6)
    @State private var burntScales: [CGFloat] = Array(repeating: 0.0, count: 6)
    @State private var burntRotations: [Double] = Array(repeating: 0.0, count: 6)
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
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
            // Initialize random spark positions
            for i in 0..<sparkOffsets.count {
                resetSpark(index: i, initialDelay: Double(i) * 0.2)
            }
            
            // Initialize burnt emitting particles
            for i in 0..<burntEmitOffsets.count {
                resetBurntEmitParticle(index: i, initialDelay: Double(i) * 0.15)
            }
            
            // Initialize burnt particles
            for i in 0..<burntOffsets.count {
                resetBurntParticle(index: i, initialDelay: Double(i) * 0.1)
            }
        }
    }
    
    // MARK: - Private Views
    
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
                    // Release timer arc - now where max timer was
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: 8,
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
                ForEach(0..<sparkOffsets.count, id: \.self) { i in
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
                        .scaleEffect(sparkScales[i])
                        .opacity(sparkOpacities[i])
                        .rotationEffect(Angle(degrees: sparkRotations[i]))
                        .blur(radius: 0.2)
                        .shadow(color: .orange.opacity(0.7), radius: 3, x: 0, y: 0)
                        .offset(
                            x: (size/2 - 25) * cos(angle) + sparkOffsets[i].x, 
                            y: (size/2 - 25) * sin(angle) + sparkOffsets[i].y
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
                ForEach(0..<burntEmitOffsets.count, id: \.self) { i in
                    Circle()
                        .fill(
                            Color.black.opacity(i % 2 == 0 ? 0.7 : 0.5)
                        )
                        .frame(width: i % 3 == 0 ? 3 : (i % 3 == 1 ? 2 : 1.5), height: i % 3 == 0 ? 3 : (i % 3 == 1 ? 2 : 1.5))
                        .scaleEffect(burntEmitScales[i])
                        .opacity(burntEmitOpacities[i])
                        .offset(
                            x: tipPosition.x + burntEmitOffsets[i].x, 
                            y: tipPosition.y + burntEmitOffsets[i].y
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
            // Randomize position offset, scale and opacity with animation
            withAnimation(.easeOut(duration: 0.25)) {
                sparkScales[index] = CGFloat.random(in: 0.8...1.3)
                sparkOffsets[index] = CGPoint(
                    x: CGFloat.random(in: -20...20),
                    y: CGFloat.random(in: -20...20)
                )
                sparkOpacities[index] = Double.random(in: 0.6...1.0)
                sparkRotations[index] = Double.random(in: 0...360)
            }
            
            // After a short delay, fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.05...0.2)) {
                withAnimation(.easeIn(duration: 0.15)) {
                    sparkOpacities[index] = 0
                    sparkScales[index] = CGFloat.random(in: 0.3...0.6)
                    sparkOffsets[index].y += CGFloat.random(in: 5...12) // More upward movement
                    sparkOffsets[index].x += CGFloat.random(in: -5...5) // Some sideways drift
                    sparkRotations[index] += Double.random(in: 45...120)
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
            // Start at the tip position
            burntEmitOffsets[index] = CGPoint(x: 0, y: 0)
            burntEmitScales[index] = CGFloat.random(in: 0.8...1.2)
            burntEmitOpacities[index] = Double.random(in: 0.6...0.9)
            
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
                    burntEmitOffsets[index] = CGPoint(
                        x: cos(randomizedAngle) * distance,
                        y: sin(randomizedAngle) * distance
                    )
                    burntEmitScales[index] = CGFloat.random(in: 0.3...0.6)
                    burntEmitOpacities[index] = 0 // Fade out completely
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
            // Randomize position offset, scale and rotation with animation
            withAnimation(.easeInOut(duration: Double.random(in: 0.8...1.5))) {
                // Keep particles close to the tip but give them some random movement
                burntScales[index] = CGFloat.random(in: 0.8...1.2)
                burntOffsets[index] = CGPoint(
                    x: CGFloat.random(in: -4...4),
                    y: CGFloat.random(in: -4...4)
                )
                burntRotations[index] = Double.random(in: 0...360)
            }
            
            // Restart animation after a delay for continuous subtle movement
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.8...1.5)) {
                resetBurntParticle(index: index)
            }
        }
    }
    
    /// The circle background with gradient and animation
    private var circleBackground: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        isPressed ? pressedColor.opacity(0.8) : normalColor.opacity(0.5),
                        isPressed ? pressedColor.opacity(0.4) : normalColor.opacity(0.2)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 1.5
                )
            )
            .overlay(
                Circle()
                    .stroke(normalColor.opacity(0.6), lineWidth: 2)
            )
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
            Text(timerText)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(timerColor)
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
