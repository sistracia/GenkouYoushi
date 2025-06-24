import SwiftUI

@main
struct GenkouYoushiApp: App {
    @State private var modelData = ModelData()
    
    var body: some Scene {
        DocumentGroup(newDocument: GenkouYoushiDocument()) { file in
            ContentView(document: file.$document)
                .environment(modelData)
        }
        DocumentGroupLaunchScene("Genkō Yōshi") {
            NewDocumentButton("Start Writing")
        } background: {
            Image(.launchBackground)
                .resizable()
        } backgroundAccessoryView: { _ in }
    }
}
