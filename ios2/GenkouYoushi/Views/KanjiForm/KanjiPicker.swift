import SwiftUI
import SVGKit

struct KanjiPicker: View {
    @Environment(ModelData.self) var modelData
    @State private var kanjiText: String = ""
    
    private var cancel: (() -> Void)?
    private var pick: ((UIImage, Kanji) -> Void)?
    
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
                        if let cancel = self.cancel {
                            cancel()
                        }
                    } label: {
                        Text("Cancel")
                    }
                    Button {
                        Task {
                            if let kanji = await modelData.getKanji(kanji: kanjiText),
                               let lastStrokeOrder =  kanji.strokeOrders.last,
                               let kanjiImage = UIImage.imageFromBase64SVG(lastStrokeOrder) {
                                if let pick = self.pick {
                                    pick(kanjiImage, kanji)
                                }
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
    
    func onBack(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.cancel = action
        return copy
    }
    
    
    func onPick(_ action: @escaping (UIImage, Kanji) -> Void) -> Self {
        var copy = self
        copy.pick = action
        return copy
    }
}
