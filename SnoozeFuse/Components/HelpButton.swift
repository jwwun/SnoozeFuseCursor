import SwiftUI

// HelpButton component for settings explanations
struct HelpButton: View {
    let helpText: String
    @State private var showingHelp = false
    
    var body: some View {
        Button(action: {
            showingHelp = true
        }) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.2))
        }
        .alert("Tip", isPresented: $showingHelp) {
            Button("OK!", role: .cancel) {}
        } message: {
            Text(helpText)
        }
    }
} 