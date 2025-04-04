import SwiftUI

struct KanjiForm: View {
    private var onKanjiSelected: ((String) -> Void)?
    private var onSave: ((String, UIImage?) -> Void)?
    
    @State private var isInputKanji: Bool = false
    
    @State private var description: String = ""
    @State private var kanjiImage: UIImage? = nil
    
    
    var body: some View {
        if isInputKanji {
            KanjiPicker(isInputKanji: $isInputKanji, kanjiImage: $kanjiImage) {
            }
            .transition(.move(edge: .trailing))
        } else {
            KanjiFormInput(isInputKanji: $isInputKanji, description: $description, kanjiImage: $kanjiImage) {
                if let onSave = onSave {
                    onSave(description, kanjiImage)
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
    
    func onSave(_ action: @escaping (String, UIImage?) -> Void) -> Self {
        var copy = self
        copy.onSave = action
        return copy
    }
}

#Preview {
    @Previewable @State var modelData = ModelData()
    KanjiForm().environment(modelData)
}
