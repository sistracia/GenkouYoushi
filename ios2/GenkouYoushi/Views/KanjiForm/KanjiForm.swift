import SwiftUI
import Vision

struct KanjiForm: View {
    @Environment(ModelData.self) var modelData
    
    private var onKanjiSelected: ((String) -> Void)?
    private var onSave: ((String, UIImage?, [UIImage?]) -> Void)?
    
    @State private var isInputKanji: Bool = false
    
    @State private var description: String = ""
    @State private var kanjiImage: UIImage? = nil
    @State private var kanji: Kanji? = nil
    
    var body: some View {
        if isInputKanji {
            KanjiPicker()
                .onBack {
                    withAnimation {
                        isInputKanji = false
                    }
                }
                .onPick { kanjiImage, kanji in
                    self.kanjiImage = kanjiImage
                    self.kanji = kanji
                    
                    withAnimation {
                        isInputKanji = false
                    }
                }
                .transition(.move(edge: .trailing))
        } else {
            KanjiFormInput(kanjiImage: $kanjiImage)
                .onImportKanji {
                    withAnimation {
                        isInputKanji = true
                    }
                }
                .onSave { description, kanji in
                    if let onSave = onSave {
                        let kanjiToUse = (kanji ?? self.kanji)
                        let kanjiOrders = (kanjiToUse?.strokeOrders ?? [])
                            .map { UIImage.imageFromBase64SVG($0) }
                        onSave(description, kanjiImage, kanjiOrders)
                    }
                }
                .transition(.move(edge: .leading))
        }
    }
    
    func onKanjiSelected(_ action: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.onKanjiSelected = action
        return copy
    }
    
    func onSave(_ action: @escaping (String, UIImage?, [UIImage?]) -> Void) -> Self {
        var copy = self
        copy.onSave = action
        return copy
    }
}

#Preview {
    @Previewable @State var modelData = ModelData()
    KanjiForm().environment(modelData)
}
