import SwiftUI

struct ServerStateOverlay<Content: View>: View {
    @Environment(ModelData.self) var modelData
    @ViewBuilder let content: Content
    
    var isLoading: Bool {
        modelData.serverState == .loading
    }
    
    var error: (Bool, String) {
        switch modelData.serverState {
        case .error(let error):
            return (true, error)
        default:
            return (false, "")
        }
    }
    
    var body: some View {
        let showError: Binding = Binding(
            get: {
                return self.error.0
            },
            set: { showError in
                modelData.serverState = .idle
            }
        )
        
        ZStack {
            content
            // TODO: The loading overlay should be cover all screen not only over the form
            if isLoading {
                Color(white: 0, opacity: 0.50)
                ProgressView().tint(.white)
            }
        }
        // TODO: The toast should be on the bottom of the screen instead of the bottom of the sheet
        .toast(message: error.1, isShowing: showError)
    }
}
