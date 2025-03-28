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
                    .font(.system(size: 25, weight: .light))
                    .foregroundColor(.white)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 14)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .frame(width: CGFloat(max(textInputValue.count, 1) * 18 + 24))
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
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding(.horizontal)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isTextFieldFocused = false
                }
            }
        }
    }
}

// New component for timer settings
struct TimerSettingsControl: View {
    @Binding var holdDuration: TimeInterval
    @Binding var napDuration: TimeInterval
    @Binding var maxDuration: TimeInterval
    @State private var holdMinutes: String = "0"
    @State private var holdSeconds: String = "30"
    @State private var napMinutes: String = "20"
    @State private var napSeconds: String = "0"
    @State private var maxMinutes: String = "30"
    @State private var maxSeconds: String = "0"
    @FocusState private var focusedField: TimerField?
    
    enum TimerField {
        case holdMin, holdSec, napMin, napSec, maxMin, maxSec
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("TIMER SETTINGS")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color.blue.opacity(0.7))
                .tracking(3)
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Hold Timer (Timer A)
            timerRow(
                label: "HOLD",
                minutes: $holdMinutes,
                seconds: $holdSeconds,
                minFocus: .holdMin,
                secFocus: .holdSec,
                updateAction: updateHoldTimer
            )
            
            // Nap Timer (Timer B)
            timerRow(
                label: "NAP",
                minutes: $napMinutes,
                seconds: $napSeconds,
                minFocus: .napMin,
                secFocus: .napSec,
                updateAction: updateNapTimer
            )
            
            // Max Timer (Timer C)
            timerRow(
                label: "MAX",
                minutes: $maxMinutes,
                seconds: $maxSeconds,
                minFocus: .maxMin,
                secFocus: .maxSec,
                updateAction: updateMaxTimer
            )
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding(.horizontal)
        .onAppear {
            // Initialize text fields from current values
            let hold = Int(holdDuration)
            holdMinutes = "\(hold / 60)"
            holdSeconds = "\(hold % 60)"
            
            let nap = Int(napDuration)
            napMinutes = "\(nap / 60)"
            napSeconds = "\(nap % 60)"
            
            let max = Int(maxDuration)
            maxMinutes = "\(max / 60)"
            maxSeconds = "\(max % 60)"
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
    
    private func timerRow(label: String, minutes: Binding<String>, seconds: Binding<String>, minFocus: TimerField, secFocus: TimerField, updateAction: @escaping () -> Void) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
                .frame(width: 100, alignment: .leading)
            
            // Minutes
            TextField("0", text: minutes)
                .keyboardType(.numberPad)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
                .padding(.vertical, 2)
                .padding(.horizontal, 8)
                .background(Color.black.opacity(0.2))
                .cornerRadius(6)
                .frame(width: 60)
                .focused($focusedField, equals: minFocus)
                .onChange(of: minutes.wrappedValue) { _ in updateAction() }
            
            Text("min")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            // Seconds
            TextField("0", text: seconds)
                .keyboardType(.numberPad)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
                .padding(.vertical, 2)
                .padding(.horizontal, 8)
                .background(Color.black.opacity(0.2))
                .cornerRadius(6)
                .frame(width: 60)
                .focused($focusedField, equals: secFocus)
                .onChange(of: seconds.wrappedValue) { _ in updateAction() }
            
            Text("sec")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
    
    private func updateHoldTimer() {
        let min = Int(holdMinutes) ?? 0
        let sec = Int(holdSeconds) ?? 0
        holdDuration = TimeInterval(min * 60 + sec)
    }
    
    private func updateNapTimer() {
        let min = Int(napMinutes) ?? 0
        let sec = Int(napSeconds) ?? 0
        napDuration = TimeInterval(min * 60 + sec)
    }
    
    private func updateMaxTimer() {
        let min = Int(maxMinutes) ?? 0
        let sec = Int(maxSeconds) ?? 0
        maxDuration = TimeInterval(min * 60 + sec)
    }
}

struct SettingsScreen: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var showPreview = false
    @State private var previewTimer: Timer?
    @State private var textInputValue: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.opacity(0.9).ignoresSafeArea()
                
                // Dismiss keyboard when tapping elsewhere
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                
                ScrollView {
                    VStack(spacing: 30) {
                        // App title
                        Text("SnoozeFuse")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 60)
                        
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
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal)
                }
                
                // Preview overlay
                previewOverlay
            }
            .navigationBarHidden(true)
            .onAppear {
                textInputValue = "\(Int(timerManager.circleSize))"
            }
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
    
    private var previewOverlay: some View {
        Group {
            if showPreview {
                ZStack {
                    CircleView(size: timerManager.circleSize)
                    
                    // Circle size update message
                    Text("CIRCLE SIZE UPDATED")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.blue.opacity(0.7))
                        .tracking(3)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.black.opacity(0.4))
                        )
                        .offset(y: timerManager.circleSize / 2 - timerManager.circleSize/3) // Position below the circle
                }
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }
    
    private func showPreviewBriefly() {
        // Cancel existing timer if any
        previewTimer?.invalidate()
        
        // Show preview
        showPreview = true
        
        // Set timer to hide preview after 0.3 seconds
        previewTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            withAnimation {
                showPreview = false
            }
        }
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(TimerManager())
        .preferredColorScheme(.dark)
}
