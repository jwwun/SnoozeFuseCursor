import SwiftUI

// Completely separate preview overlay structure
struct CirclePreviewOverlay: View {
    @ObservedObject private var circleSizeManager = CircleSizeManager.shared
    @Binding var isVisible: Bool
    
    var body: some View {
        GeometryReader { fullScreen in
            ZStack {
                // Overlay background with tap to dismiss
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isVisible = false
                        }
                    }
                
                // Circle display
                ZStack {
                    // Real-sized circle
                    CircleView(size: circleSizeManager.circleSize)
                        // Don't constrain the size at all
                        .frame(width: circleSizeManager.circleSize, height: circleSizeManager.circleSize)
                        .position(
                            x: fullScreen.size.width / 2,
                            y: fullScreen.size.height / 2 - 50
                        )
                    
                    // Size indicator
                    Text("HOLD CIRCLE SIZE: \(Int(circleSizeManager.circleSize))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
                                )
                        )
                        .position(
                            x: fullScreen.size.width / 2,
                            y: min(fullScreen.size.height - 100, fullScreen.size.height / 2 + circleSizeManager.circleSize / 2 + 40)
                        )
                }
            }
        }
        .transition(.opacity)
        .allowsHitTesting(true) // Explicitly allow hit testing
    }
} 