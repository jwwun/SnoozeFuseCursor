import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.opacity(0.9).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("SnoozeFuse")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 60)
                    
                    Spacer()
                    
                    // Independent circle preview
                    ZStack {
                        CircleView(size: min(timerManager.circleSize, 300))
                        
                        Text("Preview")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 5)
                    }
                    .frame(height: 320)
                    .padding()
                    
                    // Circle size setting with slider
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Circle Size: \(Int(timerManager.circleSize))")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("10")
                                .foregroundColor(.white.opacity(0.7))
                            
                            Slider(value: $timerManager.circleSize, in: 10...666, step: 1)
                                .accentColor(.blue)
                            
                            Text("666")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Start button
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
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(TimerManager())
        .preferredColorScheme(.dark)
}