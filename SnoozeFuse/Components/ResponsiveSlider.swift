import SwiftUI

// Custom Slider with immediate response
struct ResponsiveSlider: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let step: CGFloat
    let onValueChange: (CGFloat) -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    init(value: Binding<CGFloat>, in range: ClosedRange<CGFloat>, step: CGFloat = 1, onValueChange: @escaping (CGFloat) -> Void = { _ in }) {
        self._value = value
        self.range = range
        self.step = step
        self.onValueChange = onValueChange
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.3))
                    .frame(height: 6)
                
                // Filled portion
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue)
                    .frame(width: position(for: value, in: geometry.size.width), height: 6)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .offset(x: position(for: value, in: geometry.size.width) - 12)
            }
            .frame(height: 44) // Larger hit area
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let width = geometry.size.width
                        let dragX = min(max(0, gesture.location.x), width)
                        let percentage = dragX / width
                        let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * percentage
                        
                        // Apply stepping if needed
                        if step > 0 {
                            let steppedValue = round(newValue / step) * step
                            value = steppedValue
                        } else {
                            value = newValue
                        }
                        
                        // Call the callback
                        onValueChange(value)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 44) // Fixed height for the slider
    }
    
    // Calculate position for a given value
    private func position(for value: CGFloat, in width: CGFloat) -> CGFloat {
        let rangeDistance = range.upperBound - range.lowerBound
        let percentage = (value - range.lowerBound) / rangeDistance
        return width * percentage
    }
} 