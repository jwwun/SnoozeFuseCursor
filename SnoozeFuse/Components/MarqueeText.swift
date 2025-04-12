import SwiftUI

/// A text component that automatically scrolls horizontally for text that's too long to display
struct MarqueeText: View {
    // Main properties
    let text: String
    let font: Font
    let textColor: Color
    
    // Using an ID to help SwiftUI recreate the view
    @State private var viewID = UUID()
    @State private var animate = false
    
    // Only show marquee effect for text longer than this character count
    private let longTextThreshold = 12
    
    // Computed property to check if text needs to marquee
    private var needsMarquee: Bool {
        return text.count > longTextThreshold
    }
    
    var body: some View {
        Group {
            if needsMarquee {
                GeometryReader { geometry in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 30) {
                            Text(text)
                                .font(font)
                                .foregroundColor(textColor)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                            
                            Text(text)
                                .font(font)
                                .foregroundColor(textColor)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.horizontal, 10)
                        .offset(x: animate ? -400 : 0)
                        .animation(
                            Animation.linear(duration: 12)
                                .repeatForever(autoreverses: true),
                            value: animate
                        )
                    }
                    .disabled(true)
                }
                .frame(height: 20)
                .onAppear {
                    startAnimation()
                }
            } else {
                // Static text for shorter strings
                Text(text)
                    .font(font)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // The critical fix: use text + UUID as the ID to force recreation
        .id("marquee-\(text)-\(viewID)")
        // Observe text changes and force view recreation
        .onChange(of: text) { _ in
            resetAnimation()
        }
    }
    
    private func startAnimation() {
        // Small delay to ensure smooth animation start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animate = true
        }
    }
    
    private func resetAnimation() {
        // Reset animation state completely
        animate = false
        // Generate new ID to force view recreation
        viewID = UUID()
        // Restart animation with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startAnimation()
        }
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