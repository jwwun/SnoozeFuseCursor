import SwiftUI
import UIKit

// UIViewRepresentable wrapper for handling multiple touches
struct MultiTouchHandler: UIViewRepresentable {
    // Callbacks for touch events
    var onTouchesChanged: (Bool) -> Void
    var circleRadius: CGFloat
    
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
    
    class Coordinator: NSObject, TouchViewDelegate {
        var parent: MultiTouchHandler
        // Track all active touches
        var activeTouches: Set<UITouch> = []
        
        init(_ parent: MultiTouchHandler) {
            self.parent = parent
        }
        
        // When any touch begins
        func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView) {
            for touch in touches {
                activeTouches.insert(touch)
                
                // Check if this new touch is inside the circle
                let location = touch.location(in: view)
                let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
                let distance = hypot(location.x - center.x, location.y - center.y)
                
                // If at least one touch is inside the circle, notify we should stop the timer
                if distance <= parent.circleRadius {
                    parent.onTouchesChanged(true)
                    return
                }
            }
        }
        
        // When any touch moves
        func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView) {
            // Check if any touch is inside the circle
            let touchesInsideCircle = activeTouches.contains { touch in
                let location = touch.location(in: view)
                let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
                let distance = hypot(location.x - center.x, location.y - center.y)
                return distance <= parent.circleRadius
            }
            
            // Notify based on whether any touch is inside the circle
            parent.onTouchesChanged(touchesInsideCircle)
        }
        
        // When touches end
        func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView) {
            for touch in touches {
                activeTouches.remove(touch)
            }
            
            // If we still have active touches, check if any are inside the circle
            if !activeTouches.isEmpty {
                let stillTouchingCircle = activeTouches.contains { touch in
                    let location = touch.location(in: view)
                    let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
                    let distance = hypot(location.x - center.x, location.y - center.y)
                    return distance <= parent.circleRadius
                }
                
                parent.onTouchesChanged(stillTouchingCircle)
            } else {
                // No more touches at all
                parent.onTouchesChanged(false)
            }
        }
        
        // Handle cancelled touches the same as ended
        func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView) {
            touchesEnded(touches, with: event, in: view)
        }
    }
}

// Protocol for the touch view
protocol TouchViewDelegate: AnyObject {
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView)
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView)
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView)
    func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?, in view: TouchView)
}

// Basic UIView that handles touches
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

class TouchDetectionView: UIView {
    var onTouchesChanged: ((Bool) -> Void)?
    var circleRadius: CGFloat = 0
    private var isTouching = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateTouchState(_ newState: Bool) {
        if isTouching != newState {
            isTouching = newState
            onTouchesChanged?(newState)
            
            // Trigger haptic feedback on state change
            if newState {
                HapticManager.shared.trigger()
            }
        }
    }
    
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
    
    private func checkTouches(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Get all touches including the ones that just ended
        var allTouches = Set<UITouch>()
        if let eventTouches = event?.allTouches {
            allTouches = allTouches.union(eventTouches)
        }
        allTouches = allTouches.union(touches)
        
        // Check if any touch is within the circle
        let touchingCircle = allTouches.contains { touch in
            let location = touch.location(in: self)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let distance = hypot(location.x - center.x, location.y - center.y)
            return distance <= circleRadius && touch.phase != UITouch.Phase.ended && touch.phase != UITouch.Phase.cancelled
        }
        
        updateTouchState(touchingCircle)
    }
}
