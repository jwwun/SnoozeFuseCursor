import SwiftUI
import UIKit

// MARK: - Touch View Delegate Protocol

/// Protocol for handling touch events in a TouchView
protocol TouchViewDelegate: AnyObject {
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView)
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView)
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView)
    func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView)
}

// MARK: - TouchView

/// Basic UIView that handles and delegates touch events
class TouchView: UIView {
    weak var delegate: TouchViewDelegate?
    var circleRadius: CGFloat = 100
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.touchesBegan(touches, with: event, in: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.touchesMoved(touches, with: event, in: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.touchesEnded(touches, with: event, in: self)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.touchesCancelled(touches, with: event, in: self)
    }
}

// MARK: - TouchDetectionView

/// View that detects touches within a circular area
class TouchDetectionView: UIView {
    // MARK: - Properties
    
    /// Callback triggered when touch state changes
    var onTouchesChanged: ((Bool) -> Void)?
    
    /// Radius of the circular detection area
    var circleRadius: CGFloat = 0
    
    /// Current touching state
    private var isTouching = false
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        checkTouches(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        checkTouches(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        checkTouches(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTouchState(false)
    }
    
    // MARK: - Private Methods
    
    /// Updates the touch state and triggers callbacks if state changed
    private func updateTouchState(_ newState: Bool) {
        guard isTouching != newState else { return }
        
        isTouching = newState
        onTouchesChanged?(newState)
        
        // Trigger haptic feedback on state change
        if newState {
            HapticManager.shared.trigger()
        }
    }
    
    /// Checks if any active touch is within the circle
    private func checkTouches(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Get all touches including the ones that just ended
        var allTouches = Set<UITouch>()
        if let eventTouches = event?.allTouches {
            allTouches = allTouches.union(eventTouches)
        }
        allTouches = allTouches.union(touches)
        
        // Check if any touch is within the circle
        let touchingCircle = allTouches.contains { touch in
            // Only consider active touches (not ended or cancelled)
            guard touch.phase != .ended && touch.phase != .cancelled else { return false }
            
            let location = touch.location(in: self)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let distance = hypot(location.x - center.x, location.y - center.y)
            return distance <= circleRadius
        }
        
        updateTouchState(touchingCircle)
    }
}

// MARK: - MultiTouchHandler

/// SwiftUI wrapper for handling multiple touches in a circular area
struct MultiTouchHandler: UIViewRepresentable {
    // MARK: - Properties
    
    /// Callback for when touch state changes
    var onTouchesChanged: (Bool) -> Void
    
    /// Radius of the circular detection area
    var circleRadius: CGFloat
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> TouchDetectionView {
        let view = TouchDetectionView(frame: .zero)
        view.onTouchesChanged = onTouchesChanged
        view.circleRadius = circleRadius
        return view
    }
    
    func updateUIView(_ uiView: TouchDetectionView, context: Context) {
        uiView.onTouchesChanged = onTouchesChanged
        uiView.circleRadius = circleRadius
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, TouchViewDelegate {
        // MARK: - Properties
        
        /// Reference to parent MultiTouchHandler
        var parent: MultiTouchHandler
        
        /// Set of all active touches
        var activeTouches: Set<UITouch> = []
        
        // MARK: - Initialization
        
        init(_ parent: MultiTouchHandler) {
            self.parent = parent
        }
        
        // MARK: - TouchViewDelegate Implementation
        
        /// Handles new touches
        func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView) {
            for touch in touches {
                activeTouches.insert(touch)
                
                // Check if this new touch is inside the circle
                if isTouchInsideCircle(touch, in: view) {
                    parent.onTouchesChanged(true)
                    return
                }
            }
        }
        
        /// Handles touch movements
        func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView) {
            // Check if any active touch is inside the circle
            let touchesInsideCircle = activeTouches.contains { 
                isTouchInsideCircle($0, in: view)
            }
            
            // Notify based on whether any touch is inside the circle
            parent.onTouchesChanged(touchesInsideCircle)
        }
        
        /// Handles touch endings
        func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView) {
            for touch in touches {
                activeTouches.remove(touch)
            }
            
            // If we still have active touches, check if any are inside the circle
            if !activeTouches.isEmpty {
                let stillTouchingCircle = activeTouches.contains {
                    isTouchInsideCircle($0, in: view)
                }
                
                parent.onTouchesChanged(stillTouchingCircle)
            } else {
                // No more touches at all
                parent.onTouchesChanged(false)
            }
        }
        
        /// Handles cancelled touches
        func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView) {
            touchesEnded(touches, with: event, in: view)
        }
        
        // MARK: - Helper Methods
        
        /// Checks if a touch is inside the circular detection area
        private func isTouchInsideCircle(_ touch: UITouch, in view: UIView) -> Bool {
            let location = touch.location(in: view)
            let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            let distance = hypot(location.x - center.x, location.y - center.y)
            return distance <= parent.circleRadius
        }
    }
}
