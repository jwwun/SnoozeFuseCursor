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

// MARK: - FullScreenTouchHandler

/// SwiftUI wrapper for handling multiple touches across the entire screen
struct FullScreenTouchHandler: UIViewRepresentable {
    // MARK: - Properties
    
    /// Callback for when touch state changes
    var onTouchesChanged: (Bool) -> Void
    
    /// Callback for when touch position changes (optional)
    var onTouchMoved: ((CGPoint) -> Void)?
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> FullScreenTouchView {
        let view = FullScreenTouchView(frame: .zero)
        view.onTouchesChanged = onTouchesChanged
        view.onTouchMoved = onTouchMoved
        return view
    }
    
    func updateUIView(_ uiView: FullScreenTouchView, context: Context) {
        uiView.onTouchesChanged = onTouchesChanged
        uiView.onTouchMoved = onTouchMoved
    }
}

// MARK: - FullScreenTouchView

/// View that detects touches anywhere on the screen
class FullScreenTouchView: UIView {
    // MARK: - Properties
    
    /// Callback triggered when touch state changes
    var onTouchesChanged: ((Bool) -> Void)?
    
    /// Callback triggered when touch position changes
    var onTouchMoved: ((CGPoint) -> Void)?
    
    /// Current touching state
    private var isTouching = false
    
    /// Active touches set to ensure consistent state
    private var activeTouches = Set<UITouch>()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        
        // Listen for app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - App State Handling
    
    @objc private func appDidEnterBackground() {
        // When app goes to background, ensure we report no touching
        if isTouching {
            updateTouchState(false)
        }
        activeTouches.removeAll()
    }
    
    @objc private func appWillEnterForeground() {
        // Ensure we're in the correct state when coming back to foreground
        // This is a safety measure - state should already be false at this point
        if isTouching {
            updateTouchState(false)
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            activeTouches.insert(touch)
            // Report the position of the first touch
            if let firstTouch = activeTouches.first {
                let position = firstTouch.location(in: self)
                onTouchMoved?(position)
            }
        }
        
        // If we have any active touches, report touching
        if !activeTouches.isEmpty && !isTouching {
            updateTouchState(true)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Report position updates for the first touch
        if let firstTouch = activeTouches.first {
            let position = firstTouch.location(in: self)
            onTouchMoved?(position)
        }
        
        // This is a full-screen handler, so no position checking needed
        // Just ensure the touch state is correct
        if !activeTouches.isEmpty && !isTouching {
            updateTouchState(true)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            activeTouches.remove(touch)
        }
        
        // If the first touch ended but there are other touches,
        // report the position of the new first touch
        if let firstTouch = activeTouches.first {
            let position = firstTouch.location(in: self)
            onTouchMoved?(position)
        }
        
        // If we have no more active touches, report not touching
        if activeTouches.isEmpty && isTouching {
            updateTouchState(false)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            activeTouches.remove(touch)
        }
        
        // If the first touch was cancelled but there are other touches,
        // report the position of the new first touch
        if let firstTouch = activeTouches.first {
            let position = firstTouch.location(in: self)
            onTouchMoved?(position)
        }
        
        // If we have no more active touches, report not touching
        if activeTouches.isEmpty && isTouching {
            updateTouchState(false)
        }
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
}

// MARK: - MultiSwipeConfirmation

/// A component that requires multiple consecutive swipes to confirm an action
struct MultiSwipeConfirmation: View {
    var action: () -> Void
    var requiredSwipes: Int = 3
    var direction: Edge = .leading
    var label: String = "Swipe to exit"
    var confirmLabel: String = "Swipe again to confirm"
    var finalLabel: String = "Final swipe to confirm"
    var requireMultipleSwipes: Bool = true
    
    @State private var swipeCount: Int = 0
    @State private var resetTimer: Timer? = nil
    
    var body: some View {
        HStack {
            if direction == .trailing {
                Spacer()
            }
            
            VStack(spacing: 5) {
                Image(systemName: direction == .leading ? "chevron.left.2" : "chevron.right.2")
                    .font(.system(size: 22, weight: .medium))
                Text(swipeText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        swipeCount == 0 ? Color.blue.opacity(0.4) :
                        swipeCount < requiredSwipes - 1 ? Color.orange.opacity(0.5) :
                        Color.red.opacity(0.5)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        swipeCount == 0 ? Color.blue.opacity(0.6) :
                        swipeCount < requiredSwipes - 1 ? Color.orange.opacity(0.7) :
                        Color.red.opacity(0.7),
                        lineWidth: 1
                    )
            )
            .gesture(
                DragGesture(minimumDistance: 50, coordinateSpace: .local)
                    .onEnded { value in
                        // Check swipe direction matches expected direction
                        let horizontalAmount = value.translation.width
                        let isSwipingLeft = horizontalAmount < 0
                        let isExpectedDirection = (direction == .leading && isSwipingLeft) ||
                                                 (direction == .trailing && !isSwipingLeft)
                        
                        if isExpectedDirection {
                            resetTimer?.invalidate()
                            swipeCount += 1
                            HapticManager.shared.trigger()
                            
                            // If we don't require multiple swipes or we reached the required count, perform action
                            if !requireMultipleSwipes || swipeCount >= requiredSwipes {
                                action()
                                swipeCount = 0
                            } else {
                                // Set timer to reset swipe count after 3 seconds
                                resetTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                    swipeCount = 0
                                }
                            }
                        }
                    }
            )
            
            if direction == .leading {
                Spacer()
            }
        }
    }
    
    private var swipeText: String {
        if !requireMultipleSwipes {
            return label // Just show the base label if we don't need multiple swipes
        }
        
        switch swipeCount {
        case 0:
            return label
        case requiredSwipes - 1:
            return finalLabel
        default:
            return confirmLabel
        }
    }
}
