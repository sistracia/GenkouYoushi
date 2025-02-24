import SwiftUI

struct ContentView: View {
    @Binding var document: GenkouYoushiDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(GenkouYoushiDocument()))
}
