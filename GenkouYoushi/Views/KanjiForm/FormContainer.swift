import SwiftUI

struct FormContainer<Content: View, Action: View>: View {
    @ViewBuilder let content: Content
    @ViewBuilder let action: Action
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack(spacing: 10) {
                content
            }
            action
        }
        .padding(10)
    }
}
