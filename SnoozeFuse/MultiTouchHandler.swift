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

// MARK: - HomeIndicatorHider

/// SwiftUI view modifier for hiding the home indicator
struct HomeIndicatorHider: UIViewControllerRepresentable {
    var prefersHidden: Bool
    
    func makeUIViewController(context: Context) -> HomeIndicatorViewController {
        HomeIndicatorViewController(prefersHidden: prefersHidden)
    }
    
    func updateUIViewController(_ uiViewController: HomeIndicatorViewController, context: Context) {
        uiViewController.prefersHidden = prefersHidden
        uiViewController.setNeedsUpdateOfHomeIndicatorAutoHidden()
        uiViewController.setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }
    
    class HomeIndicatorViewController: UIViewController {
        var prefersHidden: Bool
        
        init(prefersHidden: Bool) {
            self.prefersHidden = prefersHidden
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var prefersHomeIndicatorAutoHidden: Bool {
            return prefersHidden
        }
        
        override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
            // Defer ALL edges to make it much harder to exit with home indicator
            return [.bottom, .top, .left, .right]
        }
        
        override var prefersStatusBarHidden: Bool {
            return false
        }
        
        // Add this to make the home indicator truly hidden
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Set the home indicator to auto-hide immediately
            if #available(iOS 16.0, *) {
                // iOS 16 and later
                self.setNeedsUpdateOfHomeIndicatorAutoHidden()
            } else {
                // Earlier iOS versions
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }
}

// Extension to add a modifier for hiding the home indicator
extension View {
    func hideHomeIndicator(_ hidden: Bool = true) -> some View {
        self.background(HomeIndicatorHider(prefersHidden: hidden).frame(width: 0, height: 0))
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
    var isTimerActive: Bool = true
    
    @State private var swipeCount: Int = 0
    @State private var resetTimer: Timer? = nil
    
    var body: some View {
        HStack {
            if direction == .trailing {
                Spacer()
            }
            
            VStack(spacing: 5) {
                Image(systemName: direction == .leading ? "chevron.left" : "chevron.right")
                    .font(.system(size: 20))
                Text(swipeText)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(swipeCount == 0 ? Color.blue.opacity(0.3) : 
                          swipeCount < effectiveRequiredSwipes - 1 ? Color.orange.opacity(0.4) : 
                          Color.red.opacity(0.4))
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
                            
                            // If reached required count, perform action
                            if swipeCount >= effectiveRequiredSwipes {
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
            .onTapGesture {
                // If timer is not active, allow tap to complete action directly
                if !isTimerActive {
                    action()
                }
            }
            
            if direction == .leading {
                Spacer()
            }
        }
    }
    
    // Returns the effective number of swipes required based on timer status
    private var effectiveRequiredSwipes: Int {
        return isTimerActive ? requiredSwipes : 1
    }
    
    private var swipeText: String {
        // If timer is not active, show tap label
        if !isTimerActive {
            return "Tap to exit"
        }
        
        switch swipeCount {
        case 0:
            return label
        case effectiveRequiredSwipes - 1:
            return finalLabel
        default:
            return confirmLabel
        }
    }
}
