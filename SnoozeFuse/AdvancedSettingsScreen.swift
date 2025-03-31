import SwiftUI

struct AdvancedSettingsScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var hapticManager = HapticManager.shared
    @ObservedObject var orientationManager = OrientationManager.shared
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack {
                // Header - using system back button
                HStack {
                    Spacer()
                    // we already have navigationtitle so this is redundant
                    // Text("Advanced Settings") 
                    //     .font(.system(size: 18, weight: .semibold))
                    //     .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Haptic Settings Section
                        VStack(alignment: .center, spacing: 15) {
                            Text("HAPTIC FEEDBACK")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Color.blue.opacity(0.7))
                                .tracking(3)
                                .padding(.bottom, 5)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            Toggle("Enable Haptics", isOn: $hapticManager.isHapticEnabled)
                                .padding(.horizontal)
                            
                            if hapticManager.isHapticEnabled {
                                Picker("Intensity", selection: $hapticManager.hapticStyle) {
                                    Text("Light").tag(UIImpactFeedbackGenerator.FeedbackStyle.light)
                                    Text("Medium").tag(UIImpactFeedbackGenerator.FeedbackStyle.medium)
                                    Text("Heavy").tag(UIImpactFeedbackGenerator.FeedbackStyle.heavy)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.horizontal)
                                
                                Button(action: {
                                    hapticManager.trigger()
                                }) {
                                    Text("Test Haptic")
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.blue.opacity(0.6))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        .padding(.horizontal, 8)
                        
                        // Orientation Settings
                        OrientationSettings()
                        
                        // More advanced settings can be added here
                        
                    }
                    .padding(.top, 10)
                }
            }
        }
        // Allow native back button to show
        // .navigationBarBackButtonHidden(true)  
        // .navigationBarHidden(true)
        .navigationTitle("Advanced Settings")
        .navigationBarTitleDisplayMode(.inline)
        .lockToOrientation(orientationManager)
        .onAppear {
            // Lock orientation when screen appears
            orientationManager.lockOrientation()
        }
    }
}

#Preview {
    AdvancedSettingsScreen()
} 
