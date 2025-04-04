import SwiftUI
import SVGKit

struct KanjiPicker: View {
    @Environment(ModelData.self) var modelData
    
    @Binding var isInputKanji: Bool
    @Binding var kanjiImage: UIImage?
    let onPick: () -> Void
    
    @State private var kanjiText: String = ""
    
    var body: some View {
        ServerStateOverlay {
            FormContainer {
                VStack {
                    TextField("Kanji", text: $kanjiText)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                }
            } action: {
                HStack(spacing: 10) {
                    Button {
                        withAnimation {
                            isInputKanji = false
                        }
                    } label: {
                        Text("Cancel")
                    }
                    Button {
                        Task {
                            if let kanji = await modelData.getKanji(kanji: kanjiText),
                               let lastStrokeOrder =  kanji.strokeOrders.last,
                               let kanjiImage = UIImage.imageFromBase64SVG(lastStrokeOrder) {
                                self.kanjiImage = kanjiImage
                                self.isInputKanji = false
                            }
                        }
                    } label: {
                        Text("Pick")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
