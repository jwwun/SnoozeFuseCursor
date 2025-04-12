import SwiftUI
import Combine

// MARK: - TimerElement Enum
enum TimerElement {
    case release
    case nap
    case max
    case units
    
    var explanation: String {
        switch self {
        case .release:
            return getReleaseExplanation()
        case .nap:
            return getNapExplanation()
        case .max:
            return getMaxExplanation()
        case .units:
            return getUnitsExplanation()
        }
    }
    
    private func getReleaseExplanation() -> String {
        return "The RELEASE timer starts counting down when you let go of the circle. When it reaches zero, your nap begins."
    }
    
    private func getNapExplanation() -> String {
        return "The NAP timer controls how long you'll sleep before the alarm wakes you up."
    }
    
    private func getMaxExplanation() -> String {
        return "The MAX timer is a safety feature that limits the total session time if you manage to not let go of the button."
    }
    
    private func getUnitsExplanation() -> String {
        return "You can switch between seconds and minutes by tapping this selector in the actual app."
    }
}

struct AboutScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showSupportDialog = false
    @State private var isPressingDemoCircle = false
    @State private var demoReleaseTimer = 0
    @State private var demoTimerActive = false
    @State private var showNapTransition = false
    @State private var selectedOrientationOption = 0 // 0 for Portrait, 1 for Landscape
    
    // For Smart Timer System interactive explanations
    @State private var selectedTimerElement: TimerElement? = nil
    
    // Timer for demo animation
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack {
                // Page indicator
                PageIndicator(currentPage: currentPage)
                
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    HowItWorksPage(
                        isPressingDemoCircle: $isPressingDemoCircle,
                        demoTimerActive: $demoTimerActive,
                        demoReleaseTimer: $demoReleaseTimer,
                        showNapTransition: $showNapTransition,
                        timer: timer
                    )
                    .tag(1)
                    
                    SmartTimerSystemPage(selectedTimerElement: $selectedTimerElement)
                        .tag(2)
                    
                    PositioningPage()
                        .tag(3)
                    
                    SupportPage(showSupportDialog: $showSupportDialog)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation buttons
                NavigationButtons(
                    currentPage: $currentPage,
                    dismiss: dismiss
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .sheet(isPresented: $showSupportDialog) {
            SupportDialog()
        }
    }
}

// MARK: - Page Indicator
struct PageIndicator: View {
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Navigation Buttons
struct NavigationButtons: View {
    @Binding var currentPage: Int
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 12) { // Outer VStack to place Support button above
            // Support button - shown only on page 3 (Positioning)
            if currentPage == 3 {
                HStack {
                    Spacer() // Push to the right
                    Button(action: { withAnimation { currentPage = 4 } }) {
                        // Text-only button
                        Text("Support")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.purple.opacity(0.3))
                            .cornerRadius(18)
                    }
                }
            }
            
            // Main navigation row (Previous / Next / Get Started)
            HStack {
                if currentPage > 0 {
                    Button(action: { withAnimation { currentPage -= 1 } }) {
                        Text("Previous")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(20)
                    }
                } else {
                    // Add spacer to keep right button aligned when no Previous button
                    Spacer()
                }
                
                Spacer()
                
                // Right-side button logic
                if currentPage < 3 {
                    // Normal "Next" button for pages 0-2
                    Button(action: { withAnimation { currentPage += 1 } }) {
                        Text("Next")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(20)
                    }
                } else if currentPage == 3 {
                    // On positioning page (index 3), show "Get Started" in the main row
                    Button(action: { dismiss() }) {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                } else {
                    // Last page (support/donations page, index 4)
                    Button(action: { dismiss() }) {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(20)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    // Simple animation state
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image("logotransparent")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 60)
                .padding(.top, 20)
            
            Text("The app that helps optimally nap")
                .font(.system(size: 30, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text("(you still have to do the sleeping part)")
                .padding(.bottom, 15)
                .font(.system(size: 8, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Super basic shimmer text effect - now right to left
            ZStack {
                // Base text
                Text("swipe to next →")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
                
                // Mask and shimmer
                Text("swipe to next →")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.clear)
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: .white, location: 0.2),
                                        .init(color: .white, location: 0.3),
                                        .init(color: .clear, location: 0.5)
                                    ]),
                                    startPoint: .trailing, // Changed from leading to trailing
                                    endPoint: .leading     // Changed from trailing to leading
                                )
                            )
                            .frame(width: 200, height: 100)
                            .offset(x: isAnimating ? -200 : 200) // Flipped the values
                    )
                    .mask(
                        Text("swipe to next →")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                    )
            }
            .padding(.top, 70)
            .onAppear {
                withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - How It Works Page
struct HowItWorksPage: View {
    @Binding var isPressingDemoCircle: Bool
    @Binding var demoTimerActive: Bool
    @Binding var demoReleaseTimer: Int
    @Binding var showNapTransition: Bool
    let timer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tap & Hold Mechanism")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            // Demo circle - more like the actual CircleView
            DemoCircleView(
                isPressingDemoCircle: $isPressingDemoCircle,
                demoTimerActive: $demoTimerActive,
                demoReleaseTimer: $demoReleaseTimer,
                showNapTransition: $showNapTransition
            )
            
            Text("Tap and hold the circle to begin. The nap countdown starts when you release your finger- this is based on the assumption that your muscles aren't active while napping.")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .onReceive(timer) { _ in
            if demoTimerActive {
                if demoReleaseTimer > 0 {
                    demoReleaseTimer -= 1
                } else {
                    demoTimerActive = false
                    // Show nap transition effect
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showNapTransition = true
                    }
                    
                    // Reset after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showNapTransition = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Demo Circle View
struct DemoCircleView: View {
    @Binding var isPressingDemoCircle: Bool
    @Binding var demoTimerActive: Bool
    @Binding var demoReleaseTimer: Int
    @Binding var showNapTransition: Bool
    
    var body: some View {
        ZStack {
            // Screen transition indicator when timer reaches zero
            if showNapTransition {
                // Purple background to indicate screen change
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 260, height: 260)
                
                // Arrows indicating screen transition
                HStack(spacing: 140) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.purple.opacity(0.6))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.purple.opacity(0.6))
                }
                .offset(y: -110)
                
                // Screen change indicator at top
                Text("SWITCHING TO NAP SCREEN")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.purple.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .offset(y: -130)
            }
            
            // Background transition effect when timer reaches zero
            if showNapTransition {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 220, height: 220)
            }
            
            // Outer circle border
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: 200, height: 200)
            
            // Middle circle
            Circle()
                .stroke(demoTimerActive || showNapTransition ? Color.purple.opacity(0.4) : Color.blue.opacity(0.4), lineWidth: 3)
                .frame(width: 180, height: 180)
            
            // Inner circle - changes color when pressed
            Circle()
                .fill(isPressingDemoCircle ? Color.blue.opacity(0.25) : 
                     (demoTimerActive || showNapTransition ? Color.purple.opacity(0.25) : Color.blue.opacity(0.1)))
                .frame(width: 170, height: 170)
            
            // Center fill
            Circle()
                .fill(isPressingDemoCircle ? Color.blue.opacity(0.4) : 
                      (demoTimerActive || showNapTransition ? Color.purple.opacity(0.4) : Color.white.opacity(0.05)))
                .frame(width: 120, height: 120)
            
            // Text showing status - positioned in center
            DemoCircleText(
                isPressingDemoCircle: isPressingDemoCircle, 
                demoTimerActive: demoTimerActive,
                demoReleaseTimer: demoReleaseTimer,
                showNapTransition: showNapTransition
            )
        }
        .overlay(
            Text("DEMO")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .offset(y: -90)
        )
 
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !demoTimerActive && !showNapTransition {
                        isPressingDemoCircle = true
                    }
                }
                .onEnded { _ in
                    isPressingDemoCircle = false
                    if !demoTimerActive && !showNapTransition {
                        demoTimerActive = true
                        demoReleaseTimer = 5
                    }
                }
        )
    }
}

// MARK: - Demo Circle Text
struct DemoCircleText: View {
    let isPressingDemoCircle: Bool
    let demoTimerActive: Bool
    let demoReleaseTimer: Int
    let showNapTransition: Bool
    
    var body: some View {
        if showNapTransition {
            VStack(spacing: 4) {
                Text("NAP MODE")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                Text("ACTIVE")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        } else if demoTimerActive {
            VStack(spacing: 4) {
                Text("RELEASING")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(demoReleaseTimer)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("seconds")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        } else if isPressingDemoCircle {
            VStack(spacing: 4) {
                Text("HOLD")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                Text("& RELEASE")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        } else {
            VStack(spacing: 4) {
                Text("TAP & HOLD")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                Text("TO START")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Smart Timer System Page
struct SmartTimerSystemPage: View {
    @Binding var selectedTimerElement: TimerElement?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Smart Timer System")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            // DEMO label at the top
            Text("INTERACTIVE DEMO - TAP ANY ELEMENT")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 4)
                .padding(.horizontal, 15)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(15)
            
            // Side-by-side timer controls like the real app
            TimerControlsView(selectedTimerElement: $selectedTimerElement)
            
            // Explanation text - shows details based on selected element
            TimerExplanationView(selectedTimerElement: $selectedTimerElement)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss explanation when tapping elsewhere
            if selectedTimerElement != nil {
                withAnimation {
                    selectedTimerElement = nil
                }
            }
        }
    }
}

// MARK: - Timer Controls View
struct TimerControlsView: View {
    @Binding var selectedTimerElement: TimerElement?
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Release Timer
            TimerControlView(
                title: "RELEASE",
                time: "5",
                color: .blue,
                isSelected: selectedTimerElement == .release,
                timerType: .release,
                selectedTimerElement: $selectedTimerElement,
                anyElementSelected: selectedTimerElement != nil
            )
            
            // Nap Timer
            TimerControlView(
                title: "NAP",
                time: "20",
                color: .purple,
                isSelected: selectedTimerElement == .nap,
                timerType: .nap,
                selectedTimerElement: $selectedTimerElement,
                anyElementSelected: selectedTimerElement != nil
            )
            
            // Max Timer
            TimerControlView(
                title: "MAX",
                time: "30",
                color: .red,
                isSelected: selectedTimerElement == .max,
                timerType: .max,
                selectedTimerElement: $selectedTimerElement,
                anyElementSelected: selectedTimerElement != nil
            )
        }
        .padding(.horizontal, 15)
        .padding(.top, 5)
        .padding(.bottom, 5)
    }
}

// MARK: - Individual Timer Control
struct TimerControlView: View {
    let title: String
    let time: String
    let color: Color
    let isSelected: Bool
    let timerType: TimerElement
    @Binding var selectedTimerElement: TimerElement?
    let anyElementSelected: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(anyElementSelected && !isSelected ? 0.5 : 0.8))
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.3) : Color.black.opacity(anyElementSelected && !isSelected ? 0.5 : 0.3))
                    .frame(height: 100)
                
                // Simulated wheel picker (non-interactive)
                VStack(spacing: 0) {
                    Text("\(Int(time)! - 1)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(isSelected ? 0.5 : (anyElementSelected && !isSelected ? 0.3 : 0.5)))
                    Text(time)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .white.opacity(anyElementSelected && !isSelected ? 0.4 : 1))
                    Text("\(Int(time)! + 1)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(isSelected ? 0.5 : (anyElementSelected && !isSelected ? 0.3 : 0.5)))
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTimerElement = selectedTimerElement == timerType ? nil : timerType
                }
            }
            
            // Unit picker indicator
            UnitsIndicator(
                isSelectedUnit: selectedTimerElement == .units,
                isSelectedTimer: isSelected,
                selectedTimerElement: $selectedTimerElement,
                timerType: title,
                anyElementSelected: anyElementSelected
            )
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isSelected ? 
                     color.opacity(0.1) : Color.gray.opacity(anyElementSelected && !isSelected ? 0.05 : 0.15))
                .animation(.easeInOut(duration: 0.2), value: selectedTimerElement)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isSelected ? 
                       color.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .cornerRadius(15)
        .opacity(anyElementSelected && !isSelected ? 0.7 : 1.0)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: anyElementSelected)
    }
}

// MARK: - Units Indicator
struct UnitsIndicator: View {
    let isSelectedUnit: Bool
    let isSelectedTimer: Bool
    @Binding var selectedTimerElement: TimerElement?
    let timerType: String
    let anyElementSelected: Bool
    
    var body: some View {
        Text(timerType == "RELEASE" ? "seconds" : "minutes")
            .font(.system(size: 14, design: .rounded))
            .foregroundColor(isSelectedUnit ? .blue : .blue.opacity(anyElementSelected && !isSelectedUnit && !isSelectedTimer ? 0.3 : 0.6))
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelectedUnit ? 
                           Color.blue : Color.blue.opacity(anyElementSelected && !isSelectedUnit && !isSelectedTimer ? 0.2 : 0.6), lineWidth: 1.5)
                    .background(isSelectedUnit ? 
                               Color.blue.opacity(0.2) : Color.blue.opacity(anyElementSelected && !isSelectedUnit && !isSelectedTimer ? 0.05 : 0.1))
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTimerElement = selectedTimerElement == .units ? nil : .units
                }
            }
    }
}

// MARK: - Timer Explanation View
struct TimerExplanationView: View {
    @Binding var selectedTimerElement: TimerElement?
    
    var body: some View {
        if let selectedElement = selectedTimerElement {
            VStack {
                Text(selectedElement.explanation)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                    )
                    .padding(.horizontal, 15)
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation {
                            selectedTimerElement = nil
                        }
                    }
                
                // Tap anywhere to dismiss explanation
                Text("Tap to dismiss")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 5)
            }
        } else {
            // Default text when nothing is selected
            Text("RELEASE: Starts nap when countdown ends\n\nNAP: How long your nap lasts\n\nMAX: Failsafe total time limit")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Positioning Page
struct PositioningPage: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Comfortable Positioning")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Device positioning tips with images - removed scary yellow colors
                VStack(spacing: 10) {
                    Image(systemName: "iphone")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .padding(.bottom, 5)
                    
                    Text("Default Portrait Mode")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 5)
                    
                    Text("The app works in portrait mode by default. More options in Advanced Settings.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
                
                Text("Best positions for napping:\n• Above your hand while lying down\n• On a cushioned surface beside you\n• Sideways to prevent accidental taps\n• On a pillow at a comfortable angle")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                Spacer(minLength: 80) // Add extra space at bottom to ensure content doesn't get cut off
            }
            .frame(minHeight: UIScreen.main.bounds.height - 160) // Ensure minimal height for proper swiping
        }
        .gesture(DragGesture()) // Empty drag gesture to ensure scrolling works properly
    }
}

// MARK: - Support Page
struct SupportPage: View {
    @Binding var showSupportDialog: Bool
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                Image(systemName: "gift")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                Text("Support the App")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("I made this prototype in 2 months on my free time from planning to publishing. If you're vibing with it and want to support the app, any amount helps—even $1!")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Contact information - moved to the top
                VStack(alignment: .center, spacing: 5) {
                    Text("Contact")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 2)
                    
                    Text("Email: snoozefuze@proton.me")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    Text("For feedback, support, or questions")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 5)
                .padding(.bottom, 15)
                
                // Single Support Me button
                Button(action: {
                    showSupportDialog = true
                }) {
                    Text("Donate")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                }
                .padding(.vertical, 5)
                
                // Donation tiers
                DonationTiersView()
                
                Spacer(minLength: 80) // Add extra space at bottom to ensure content doesn't get cut off
            }
            .frame(minHeight: UIScreen.main.bounds.height - 160) // Ensure minimal height for proper swiping
        }
        .gesture(DragGesture()) // Empty drag gesture to ensure scrolling works properly
    }
}

// MARK: - Donation Tiers View
struct DonationTiersView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Total Donation Goals:")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.bottom, 2)
            
            Text("• $99 total → I'll renew the dev license for a year")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            Text("• $120 total → I'll add snooze + stats features")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            Text("• $140 total → I'll turn it into a full alarm app")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            Text("• $600 total → I can afford rent for a month 😅")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            
            Text("Individual Donations:")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 10)
                .padding(.bottom, 2)
            
            Text("Donate any amount you're comfortable with! Every contribution helps, even $1.")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            Text("Shoutout for any donation in the next app update!")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            
            Text("No pressure — just if you wanna help out!")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, 5)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 15)
    }
}

struct SupportDialog: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Title
            Text("Support Development")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 10)
            
            // Primary donation method - PayPal (more prominent)
            Link(destination: URL(string: "https://paypal.me/jwwwun")!) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PayPal: @jwwwun")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("May include fees depending on method")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Secondary donation method - Ko-fi (more subtle)
            Link(destination: URL(string: "https://ko-fi.com/jwwwun")!) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ko-fi: ko-fi.com/jwwwun")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text("Ko-fi also takes a small platform fee")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
            }
            
            // Footer
            Text("No expectations – donate only if you want to support future development")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 15)
            
            // Close button with proper tap area
            Button(action: { dismiss() }) {
                Text("Close")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 10)
        }
        .padding(25)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationView {
        AboutScreen()
    }
} 