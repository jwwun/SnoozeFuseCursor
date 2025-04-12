import SwiftUI

struct CustomMarqueeView: View {
    let text: String
    let font: Font
    let textColor: Color
    let speed: Double
    
    @State private var animating = false
    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    
    init(text: String, font: Font = .system(size: 16), textColor: Color = .primary, speed: Double = 40) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.speed = speed
    }
    
    private var shouldAnimate: Bool {
        return textWidth > UIScreen.main.bounds.width * 0.4
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                if shouldAnimate {
                    HStack(spacing: 20) {
                        Text(text)
                            .font(font)
                            .foregroundColor(textColor)
                            .fixedSize(horizontal: true, vertical: false)
                            .background(GeometryReader { textGeometry in
                                Color.clear.onAppear {
                                    self.textWidth = textGeometry.size.width
                                }
                            })
                        
                        Text(text)
                            .font(font)
                            .foregroundColor(textColor)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .offset(x: offset)
                    .onAppear {
                        // Short delay to allow proper width measurement
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(Animation.linear(duration: getDuration()).repeatForever(autoreverses: false)) {
                                offset = -textWidth - 20 // include spacing
                            }
                        }
                    }
                    .id("marquee-\(text)") // Force view recreation when text changes
                } else {
                    Text(text)
                        .font(font)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                }
            }
            .frame(width: geometry.size.width, alignment: .leading)
            .clipped()
        }
        .frame(height: 24)
    }
    
    private func getDuration() -> Double {
        let baseDuration = (textWidth + 20) / CGFloat(speed)
        return max(baseDuration, 2.0) // Ensure minimum animation time
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomMarqueeView(text: "Short text")
        CustomMarqueeView(text: "This is a very long text that should definitely scroll because it won't fit in the available space")
        CustomMarqueeView(text: "Another marquee example with custom styling", font: .system(size: 14, weight: .bold), textColor: .blue)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
    .previewLayout(.sizeThatFits)
}
