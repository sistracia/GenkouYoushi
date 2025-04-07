import SwiftUI

struct Toast: ViewModifier {
    let message: String
    @Binding var isShowing: Bool
    let zIndex: Double
    let autoClose: Bool
    let duration: Double
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                VStack {
                    Spacer()
                    
                    HStack {
                        Text(message)
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            withAnimation {
                                isShowing.toggle()
                            }
                        } label: {
                            Label("Close Toast", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                        }
                        
                    }
                    .padding()
                    .foregroundStyle(.background)
                    .background(.foreground.opacity(0.7))
                    .clipShape(.buttonBorder)
                    .padding(.bottom, 20)
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom))
                    .zIndex(zIndex)
                    
                }
                .onAppear {
                    if autoClose {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                isShowing = false
                            }
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func toast(message: String, isShowing: Binding<Bool>, zIndex: Double = 1, autoClose: Bool = false, duration: Double = 2.0) -> some View {
        modifier(Toast(message: message, isShowing: isShowing, zIndex: zIndex, autoClose: autoClose, duration: duration))
    }
}


#Preview {
    struct PlaceholderView: View {
        @State private var showToast = false
        
        var body: some View {
            VStack {
                Button("Show Toast") {
                    withAnimation {
                        showToast = true
                    }
                }
            }
            .toast(message: "Hello, this is a toast!", isShowing: $showToast)
        }
    }
    
    return PlaceholderView()
}
