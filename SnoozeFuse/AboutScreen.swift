import SwiftUI

struct AboutScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)
                
                TabView(selection: $currentPage) {
                    // Page 1: Welcome
                    VStack(spacing: 20) {
                        Image("logotransparent")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 60)
                            .padding(.top, 20)
                        
                        Text("Welcome to SnoozeFuse!")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("The perfect nap companion that helps you wake up refreshed, not groggy.")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .tag(0)
                    
                    // Page 2: How It Works
                    VStack(spacing: 20) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.top, 20)
                        
                        Text("Tap & Hold Mechanism")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Tap and hold the circle to start. The nap countdown begins when you release your finger. Perfect for drifting off to sleep naturally!")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .tag(1)
                    
                    // Page 3: Timer Types
                    VStack(spacing: 20) {
                        Image(systemName: "timer")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                            .padding(.top, 20)
                        
                        Text("Smart Timer System")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("RELEASE TIMER: Counts down when you release your finger, starting your nap when it reaches zero\n\nNAP TIMER: Controls how long your nap lasts before the alarm sounds\n\nMAX TIMER: A failsafe that limits your total session time in case you fall into deep sleep")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .tag(2)
                    
                    // Page 4: Phone Positioning
                    VStack(spacing: 20) {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .padding(.top, 20)
                        
                        Text("Comfortable Positioning")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Position your phone for comfortable napping:\n\n• Above your hand while lying on your back\n• On your bed or cushioned surface beside you\n• Try holding sideways to prevent accidentally tabbing out\n• Rest on a pillow at a comfortable angle\n\nThe key is finding a relaxed position as you drift off!")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .tag(3)
                    
                    // Page 5: Support (moved from page 4)
                    VStack(spacing: 20) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                            .padding(.top, 20)
                        
                        Text("Support the App")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("I made this prototype in 2 months on my free time. If you're vibing with it and want to support my project and keep this app running with future updates. Just $1 helps but you don't have to donate if you dont want to.") 
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Link(destination: URL(string: "https://ko-fi.com/jwwwun")!) {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 18))
                                Text("Support Me on Ko-fi")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FF5E5B"), Color(hex: "FF3B3B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: Color(hex: "FF3B3B").opacity(0.5), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 10)
                    }
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation buttons
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
                    }
                    
                    Spacer()
                    
                    if currentPage < 4 {
                        Button(action: { withAnimation { currentPage += 1 } }) {
                            Text("Next")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.blue.opacity(0.3))
                                .cornerRadius(20)
                        }
                    } else {
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
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
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
    }
}

#Preview {
    NavigationView {
        AboutScreen()
    }
} 