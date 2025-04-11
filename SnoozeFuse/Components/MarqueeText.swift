import SwiftUI

/// A text component that automatically scrolls horizontally for text that's too long to display
struct MarqueeText: View {
    let text: String
    let font: Font
    let textColor: Color
    
    @State private var animate = false
    
    // Only show marquee effect for text longer than this character count
    private let longTextThreshold = 12
    
    private var needsMarquee: Bool {
        return text.count > longTextThreshold
    }
    
    var body: some View {
        Group {
            if needsMarquee {
                // Animated marquee for long text
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 30) {
                        Text(text)
                            .font(font)
                            .foregroundColor(textColor)
                            .lineLimit(1)
                        
                        Text(text)
                            .font(font)
                            .foregroundColor(textColor)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .offset(x: animate ? -400 : 0)  // Use a large enough offset to ensure scrolling
                    .animation(
                        Animation.linear(duration: 12)  // Fixed duration
                            .repeatForever(autoreverses: true),
                        value: animate
                    )
                    .onAppear {
                        // Start animation after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            animate = true
                        }
                    }
                }
                .disabled(true)  // Disable user scrolling
            } else {
                // Static text for shorter strings
                Text(text)
                    .font(font)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: 25)  // Fixed height for consistency
    }
}

// Keep helper extensions for potential future use
extension String {
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
    
    func heightOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.height
    }
} 