import SwiftUI

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
    @Binding var duration: TimeInterval // Use TimeInterval binding directly
    var label: String
    var focus: FocusState<TimerSettingsControl.TimerField?>.Binding
    var timerField: TimerSettingsControl.TimerField

    // Internal state for the wheel picker and unit selection
    @State private var numericValue: Int = 0
    @State private var selectedUnit: TimeUnit = .seconds // Default to seconds initially
    
    // State to track active scrolling - helps improve performance
    @State private var isScrolling: Bool = false
    @State private var scrollDebounceTimer: Timer? = nil
    
    // Track if the binding warm-up has occurred
    @State private var hasWarmedUpBinding: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            // Timer label without emoji
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 2)

            // Wheel Picker for numeric value
            Picker("", selection: $numericValue) {
                ForEach(0..<100) { number in // Assuming max 99 for simplicity
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .onChange(of: numericValue) { _ in
                // Mark that scrolling has started
                isScrolling = true
                
                // Cancel existing timer
                scrollDebounceTimer?.invalidate()
                
                // Set timer to update duration only after scrolling stops
                scrollDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                    composeAndUpdateDuration()
                    
                    // Delay marking scrolling as finished to ensure UI remains responsive
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isScrolling = false
                    }
                }
            }

            // Unit selection picker with compact style
            Menu {
                ForEach(TimeUnit.allCases) { timeUnit in
                    Button(action: {
                        selectedUnit = timeUnit
                        composeAndUpdateDuration()
                    }) {
                        Text(timeUnit.rawValue.uppercased())
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedUnit.rawValue) // Use selectedUnit state
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                    
                    // Add a tap/edit icon to indicate this can be changed
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue.opacity(0.8))
                }
                .frame(minWidth: 50)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    ZStack {
                        // Animated pulsing background for extra tap indication
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                            .scaleEffect(1.02)
                        
                        // Border
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.6), lineWidth: 1.5)
                    }
                )
                // Add a subtle animation to indicate tappability
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                        .scaleEffect(1.1)
                        .opacity(0.5)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: UUID() // Always animate
                        )
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.15))
        )
        .onAppear {
            // Initialize picker state when view appears
            decomposeAndUpdateState()
            
            // Perform binding warm-up only once
            if !hasWarmedUpBinding {
                // Delay slightly to ensure view is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let originalDuration = duration
                    // Tiny change to trigger binding update
                    duration += 0.001 
                    
                    // Change back immediately
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        duration = originalDuration
                        hasWarmedUpBinding = true
                    }
                }
            }
        }
        .onChange(of: duration) { _ in
            // Only update picker state if we're not currently scrolling
            // This prevents feedback loops during active scrolling
            if !isScrolling {
                decomposeAndUpdateState()
            }
        }
        .onDisappear {
            // Clean up timer
            scrollDebounceTimer?.invalidate()
            scrollDebounceTimer = nil
            
            // Reset warm-up flag if needed (optional, depends on desired behavior)
            // hasWarmedUpBinding = false 
        }
    }
    
    // Helper to decompose TimeInterval into internal state (value and unit)
    private func decomposeAndUpdateState() {
        let value = Int(duration)
        if value >= 60 && value % 60 == 0 {
            numericValue = value / 60
            selectedUnit = .minutes
        } else {
            numericValue = value
            selectedUnit = .seconds
        }
    }

    // Helper to compose TimeInterval from internal state and update binding
    private func composeAndUpdateDuration() {
        let newDuration = TimeInterval(numericValue) * selectedUnit.multiplier
        // Only update if value actually changed to reduce redundant updates
        if duration != newDuration {
            duration = newDuration
        }
    }
} 