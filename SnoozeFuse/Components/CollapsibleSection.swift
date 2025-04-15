import SwiftUI

struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    let content: () -> Content
    
    init(
        title: String,
        icon: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self._isExpanded = isExpanded
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            // Header with expand/collapse control
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    // Section icon
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                    
                    // Section title
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Expand/collapse icon
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content (only shown when expanded)
            if isExpanded {
                Divider()
                    .background(Color.gray.opacity(0.5))
                    .padding(.horizontal)
                
                content()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, isExpanded ? 10 : 0)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, 8)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            CollapsibleSection(
                title: "Notifications",
                icon: "bell.fill",
                isExpanded: .constant(true)
            ) {
                Text("Notification settings would go here")
                    .padding()
            }
            
            CollapsibleSection(
                title: "Audio Settings",
                icon: "speaker.wave.3.fill",
                isExpanded: .constant(false)
            ) {
                Text("Audio settings would go here")
                    .padding()
            }
        }
        .padding()
    }
} 