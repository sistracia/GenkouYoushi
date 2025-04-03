import SwiftUI

@main
struct GenkouYoushiApp: App {
    @State private var modelData = ModelData(kanjiAPIClient: KanjiAPIClient(baseURL: URL(string: "https://kanji-api.sistracia.com")!))
    
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
