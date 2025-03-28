import SwiftUI

// Breaking up the UI into smaller components
struct CircleSizeControl: View {
    @Binding var circleSize: CGFloat
    @Binding var textInputValue: String
    @FocusState private var isTextFieldFocused: Bool
    var onValueChanged: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {

                    
                TextField("", text: $textInputValue)
                    .keyboardType(.numberPad)
                    .font(.system(size: 25, weight: .light))
                    .foregroundColor(.white)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 16)
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
            }
            
            HStack {
                Text("100")
                    .foregroundColor(.white.opacity(0.7))
                
                Slider(value: $circleSize, in: 100...1000, step: 1)
                    .accentColor(.blue)
                    .onChange(of: circleSize) { _ in
                        textInputValue = "\(Int(circleSize))"
                        onValueChanged()
                    }
                
                Text("1000")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal)
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
                
                VStack(spacing: 30) {
                    // App title
                    Text("SnoozeFuse")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 60)
                    
                    Spacer()
                    
                    // Circle size control (extracted to separate component)
                    CircleSizeControl(
                        circleSize: $timerManager.circleSize,
                        textInputValue: $textInputValue,
                        onValueChanged: showPreviewBriefly
                    )
                    
                    Spacer()
                    
                    // Start button
                    startButton
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
        .padding(.bottom, 40)
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
