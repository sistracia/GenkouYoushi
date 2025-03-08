import SwiftUI

@main
struct GenkouYoushiApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: GenkouYoushiDocument()) { file in
            ContentView(document: file.$document)
        }
        DocumentGroupLaunchScene("Genkō Yōshi") {
            NewDocumentButton("Start Writing")
        } background: {
            Image(.launchBackground)
                .resizable()
        } backgroundAccessoryView: { _ in }
    }
}
