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
                    
                    // Circle preview using shared component
                    VStack {
                        CircleView(size: min(timerManager.circleSize, 300))
                        
                        Text("Preview")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 5)
                    }
                    .padding()
                    
                    // Circle size setting
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Circle Size")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            TextField("Size", value: $timerManager.circleSize, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                            
                            Stepper("", value: $timerManager.circleSize, in: 50...1000, step: 10)
                                .labelsHidden()
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
