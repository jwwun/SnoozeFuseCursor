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
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            circleBackground
            progressBar
            releaseTimerBar
            statusTextView
            timerTextView
        }
        .frame(width: size, height: size)
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
                // Release timer arc - now where max timer was
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round
                        )
                    )
                    // Dynamic color based on press state - white normally, pink when pressed
                    .foregroundColor(isPressed ? Color.pink.opacity(0.8) : Color.white.opacity(0.8))
                    .rotationEffect(Angle(degrees: -90))
                    .padding(25) // More inset for better visual separation
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
