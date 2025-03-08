import SwiftUI

struct BookEditorLaunchView: View {
    @State private var isPresented = false
    var body: some View {
        DocumentLaunchView(for: [.pdf]) {
            NewDocumentButton("Start Learning")
        } onDocumentOpen: { url in
            ContentView(url: url)
        } background: {
            Image(.launchBackground)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } backgroundAccessoryView: { _ in }
    }
}


@main
struct GenkouYoushiApp: App {
    var body: some Scene {
        WindowGroup {
            BookEditorLaunchView()
        }
    }
}
