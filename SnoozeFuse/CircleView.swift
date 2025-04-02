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
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            circleBackground
            statusTextView
        }
        .frame(width: size, height: size)
    }
    
    // MARK: - Private Views
    
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
            } else {
                Text(isPressed ? pressedText : notPressedText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(2)
            }
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
