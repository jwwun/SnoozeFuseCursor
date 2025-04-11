import SwiftUI

/// A view modifier that conditionally applies Metal rendering (.drawingGroup())
/// with error handling to prevent metallib load failures
struct ConditionalMetalRenderer: ViewModifier {
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        if isEnabled {
            if #available(iOS 15.0, *) {
                content.drawingGroup()
            } else {
                content
            }
        } else {
            content
        }
    }
}

// Extension to make it easier to use
extension View {
    /// Applies Metal rendering with a fallback mechanism
    /// - Parameter isEnabled: Whether Metal rendering should be used
    /// - Returns: A view with conditional Metal rendering
    func safeMetalRendering(isEnabled: Bool = true) -> some View {
        modifier(ConditionalMetalRenderer(isEnabled: isEnabled))
    }
} 