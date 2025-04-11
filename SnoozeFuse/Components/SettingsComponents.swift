import SwiftUI

// MARK: - MovableSettingSection
/// Generic component that makes any UI section moveable between Main and Advanced Settings
struct MovableSettingSection<Content: View>: View {
    let title: String
    let icon: String
    let helpText: String
    @Binding var isHiddenFromMainSettings: Bool
    let content: () -> Content
    
    @State private var showMoveAnimation = false
    @State private var moveOutDirection: Edge = .trailing
    
    init(
        title: String,
        icon: String,
        helpText: String,
        isHiddenFromMainSettings: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.helpText = helpText
        self._isHiddenFromMainSettings = isHiddenFromMainSettings
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // Header with title, help button, and toggle
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .tracking(3)
                
                if !helpText.isEmpty {
                    HelpButton(helpText: helpText)
                }
                
                Spacer()
                
                // Hide/move button
                Button(action: {
                    // Set the direction for the animation
                    moveOutDirection = isHiddenFromMainSettings ? .leading : .trailing
                    
                    // Start the exit animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showMoveAnimation = true
                    }
                    
                    // Haptic feedback
                    HapticManager.shared.trigger()
                    
                    // After animation out, toggle the state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isHiddenFromMainSettings.toggle()
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: isHiddenFromMainSettings ? 
                              "arrow.up.left" : "arrow.down.right")
                            .font(.system(size: 9))
                        Text(isHiddenFromMainSettings ? 
                             "To Main" : "Hide")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(6)
                    .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.bottom, 2)
            
            // Content
            content()
        }
        .padding(.vertical, 8)
        .offset(x: showMoveAnimation ? (moveOutDirection == .trailing ? 500 : -500) : 0)
        .onAppear {
            // Reset animation state when view appears
            showMoveAnimation = false
        }
    }
}

// Remove the duplicate HelpButton component since it already exists elsewhere 