import SwiftUI

// Breaking up the UI into smaller components
struct CircleSizeControl: View {
    @Binding var circleSize: CGFloat
    @Binding var textInputValue: String
    @FocusState private var isTextFieldFocused: Bool
    var onValueChanged: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(spacing: 0) {
                TextField("", text: $textInputValue)
                    .keyboardType(.numberPad)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .frame(width: CGFloat(max(textInputValue.count, 1) * 20 + 28))
                    .focused($isTextFieldFocused)
                    .onChange(of: textInputValue) { newValue in
                        if let newSize = Int(newValue) {
                            circleSize = CGFloat(newSize)
                            onValueChanged()
                        }
                    }
                HStack(spacing: 0) {
                    Text("⌞⌝  ")
                        .foregroundColor(.white.opacity(0.7))
 
                    Slider(value: $circleSize, in: 100...1000, step: 1)
                        .accentColor(.blue)
                        .onChange(of: circleSize) { _ in
                            textInputValue = "\(Int(circleSize))"
                            onValueChanged()
                        }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding(.horizontal, 8) // Reduced to prevent edge cutoff
    }
}

// Time unit selection for each timer
enum TimeUnit: String, CaseIterable, Identifiable {
    case seconds = "sec"
    case minutes = "min"
    
    var id: String { self.rawValue }
    
    var multiplier: TimeInterval {
        switch self {
        case .seconds: return 1
        case .minutes: return 60
        }
    }
}

// Cute time picker with unit selection
struct CuteTimePicker: View {
    @Binding var value: String
    @Binding var unit: TimeUnit
    var label: String
    var focus: FocusState<TimerSettingsControl.TimerField?>.Binding
    var timerField: TimerSettingsControl.TimerField
    var updateAction: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            // Timer label without emoji
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 2)
            
            // Time input field - make bigger
            TextField("0", text: $value)
                .keyboardType(.numberPad)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 12) // Bigger touch target
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .frame(minWidth: 100)
                .focused(focus, equals: timerField)
                .onChange(of: value) { _ in
                    updateAction()
                }
            
            // Unit selection picker with cute style
            Menu {
                Picker("Unit", selection: $unit) {
                    ForEach(TimeUnit.allCases) { unit in
                        Text(unit.rawValue.uppercased())
                            .tag(unit)
                    }
                }
            } label: {
                HStack {
                    Text(unit.rawValue)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.6), lineWidth: 1.5)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.15))
        )
    }
}

// New component for timer settings
struct TimerSettingsControl: View {
    @Binding var holdDuration: TimeInterval
    @Binding var napDuration: TimeInterval
    @Binding var maxDuration: TimeInterval
    
    @State private var holdTime: String = "30"
    @State private var napTime: String = "20"
    @State private var maxTime: String = "30"
    
    @State private var holdUnit: TimeUnit = .seconds // Default seconds
    @State private var napUnit: TimeUnit = .minutes  // Default minutes
    @State private var maxUnit: TimeUnit = .minutes  // Default minutes
    
    @FocusState private var focusedField: TimerField?
    
    enum TimerField {
        case hold, nap, max
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("TIMER SETTINGS")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color.blue.opacity(0.7))
                .tracking(3)
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Timer grid layout - reduced spacings to prevent edge cutoff
            HStack(alignment: .top, spacing: 8) {
                // Hold Timer (Timer A)
                CuteTimePicker(
                    value: $holdTime,
                    unit: $holdUnit,
                    label: "HOLD",
                    focus: $focusedField,
                    timerField: .hold,
                    updateAction: updateHoldTimer
                )
                
                // Nap Timer (Timer B)
                CuteTimePicker(
                    value: $napTime,
                    unit: $napUnit,
                    label: "NAP",
                    focus: $focusedField,
                    timerField: .nap,
                    updateAction: updateNapTimer
                )
                
                // Max Timer (Timer C)
                CuteTimePicker(
                    value: $maxTime,
                    unit: $maxUnit,
                    label: "MAX",
                    focus: $focusedField,
                    timerField: .max,
                    updateAction: updateMaxTimer
                )
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, 8) // Reduced to prevent edge cutoff
        .onAppear {
            // Initialize units and values
            setupInitialValues()
        }
    }
    
    // Setup initial values based on the existing durations
    private func setupInitialValues() {
        let hold = Int(holdDuration)
        if hold >= 60 && hold % 60 == 0 {
            holdUnit = .minutes
            holdTime = "\(hold / 60)"
        } else {
            holdUnit = .seconds
            holdTime = "\(hold)"
        }
        
        let nap = Int(napDuration)
        if nap >= 60 && nap % 60 == 0 {
            napUnit = .minutes
            napTime = "\(nap / 60)"
        } else {
            napUnit = .seconds
            napTime = "\(nap)"
        }
        
        let max = Int(maxDuration)
        if max >= 60 && max % 60 == 0 {
            maxUnit = .minutes
            maxTime = "\(max / 60)"
        } else {
            maxUnit = .seconds
            maxTime = "\(max)"
        }
    }
    
    private func updateHoldTimer() {
        let value = Int(holdTime) ?? 0
        holdDuration = TimeInterval(value) * holdUnit.multiplier
    }
    
    private func updateNapTimer() {
        let value = Int(napTime) ?? 0
        napDuration = TimeInterval(value) * napUnit.multiplier
    }
    
    private func updateMaxTimer() {
        let value = Int(maxTime) ?? 0
        maxDuration = TimeInterval(value) * maxUnit.multiplier
    }
}

struct SettingsScreen: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var showPreview = false
    @State private var previewTimer: Timer?
    @State private var textInputValue: String = ""
    @FocusState private var isAnyFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Actual content view
            NavigationView {
                ZStack {
                    // Background
                    Color.black.opacity(0.9).ignoresSafeArea()
                    
                    // Dismiss keyboard when tapping background
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isAnyFieldFocused = false
                            hideKeyboard()
                        }
                    
                    // ScrollView with better spacing
                    ScrollView {
                        VStack(spacing: 25) {
                            // App title
                            Text("SnoozeFuse")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.top, 50)
                            
                            // Circle size control
                            CircleSizeControl(
                                circleSize: $timerManager.circleSize,
                                textInputValue: $textInputValue,
                                onValueChanged: showPreviewBriefly
                            )
                            
                            // Timer settings
                            TimerSettingsControl(
                                holdDuration: $timerManager.holdDuration,
                                napDuration: $timerManager.napDuration,
                                maxDuration: $timerManager.maxDuration
                            )
                            
                            // Start button
                            startButton
                                .padding(.bottom, 80) // Added more bottom padding
                        }
                    }
                    .focused($isAnyFieldFocused)
                    
                    // Global keyboard dismissal button - now green and cuter
                    VStack {
                        Spacer()
                        if isAnyFieldFocused {
                            Button(action: {
                                isAnyFieldFocused = false
                                hideKeyboard()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Confirm")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .frame(width: 180)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "66BB6A"), Color(hex: "43A047")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(25)
                                .shadow(color: Color(hex: "43A047").opacity(0.5), radius: 8, x: 0, y: 4)
                            }
                            .padding(.bottom, 25)
                        }
                    }
                }
                .navigationBarHidden(true)
            }
            
            // Completely separate preview overlay that doesn't affect layout
            if showPreview {
                CirclePreviewOverlay(
                    circleSize: timerManager.circleSize,
                    isVisible: $showPreview
                )
            }
        }
        .onAppear {
            textInputValue = "\(Int(timerManager.circleSize))"
        }
    }
    
    private var startButton: some View {
        NavigationLink(destination: NapScreen().environmentObject(timerManager)) {
            Text("Start Nap Session")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal, 40)
        }
    }
    
    private func showPreviewBriefly() {
        // Cancel existing timer if any
        previewTimer?.invalidate()
        
        // Show preview
        showPreview = true
        
        // Set timer to hide preview after 1 second for better visibility
        previewTimer = Timer.scheduledTimer(withTimeInterval: .5, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.1)) {
                showPreview = false
            }
        }
    }
    
    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Completely separate preview overlay structure
struct CirclePreviewOverlay: View {
    let circleSize: CGFloat
    @Binding var isVisible: Bool
    
    var body: some View {
        GeometryReader { fullScreen in
            ZStack {
                // Overlay background with tap to dismiss
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isVisible = false
                        }
                    }
                
                // Circle display
                ZStack {
                    // Real-sized circle
                    CircleView(size: circleSize)
                        // Don't constrain the size at all
                        .frame(width: circleSize, height: circleSize)
                        .position(
                            x: fullScreen.size.width / 2,
                            y: fullScreen.size.height / 2 - 50
                        )
                    
                    // Size indicator
                    Text("CIRCLE SIZE: \(Int(circleSize))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
                                )
                        )
                        .position(
                            x: fullScreen.size.width / 2,
                            y: min(fullScreen.size.height - 100, fullScreen.size.height / 2 + circleSize / 2 + 40)
                        )
                }
            }
        }
        .transition(.opacity)
        .zIndex(999) // Ensure it's above everything
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(TimerManager())
        .preferredColorScheme(.dark)
}
