//
//  CircleView.swift
//  SnoozeFuse
//
//  Created by Jonathan Truong on 3/28/25.
//


import SwiftUI

struct CircleView: View {
    var size: CGFloat
    var isPressed: Bool = false
    var showStatusText: Bool = false
    var showInitialInstructions: Bool = false
    
    var body: some View {
        ZStack {
            // Visual circle
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            isPressed ? Color.blue.opacity(0.8) : Color.blue.opacity(0.5),
                            isPressed ? Color.indigo.opacity(0.4) : Color.indigo.opacity(0.2)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 1.5
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3), value: isPressed)
            
            // Status text (optional)
            if showStatusText {
                if showInitialInstructions && !isPressed {
                    Text("TAP AND HOLD\nTO START")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(2)
                        .multilineTextAlignment(.center)
                } else {
                    Text(isPressed ? "HOLDING" : "RELEASED")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(2)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        CircleView(size: 200)
        CircleView(size: 200, isPressed: true, showStatusText: true)
    }
    .preferredColorScheme(.dark)
    .padding()
    .background(Color.black)
}
