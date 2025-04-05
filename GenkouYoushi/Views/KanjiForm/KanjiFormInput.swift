import SwiftUI
import Vision

struct KanjiFormInput: View {
    @Environment(ModelData.self) var modelData
    @Binding var kanjiImage: UIImage?
    
    @State private var description: String = ""
    @State private var kanji: Kanji? = nil
    @State private var tmpKanjiImage: UIImage? = nil
    
    @State private var showImageTypeDialog: Bool = false
    @State private var showPhotoPicker: Bool = false
    
    @State private var type: UIImagePickerController.SourceType = .photoLibrary
    @State private var cropRect: CGRect = CGRect(x: 100, y: 100, width: 200, height: 200)
    @State private var lockAspectRatio: Bool = true
    @State private var aspectRatio: CGFloat = 1.0 // Default 1:1
    
    private var importKanji: (() -> Void)?
    private var save: ((String, Kanji?) -> Void)?
    
    init(kanjiImage: Binding<UIImage?>) {
        self._kanjiImage = kanjiImage
    }
    
    var img: Image {
        if let kanjiImage = kanjiImage {
            return Image(uiImage: kanjiImage)
        }
        
        return Image(systemName: "plus.square.dashed")
    }
    
    var body: some View {
        let isTmpKanjiImagePicked = Binding(
            get: {
                return self.tmpKanjiImage != nil
            },
            set: { value in
                self.tmpKanjiImage = value ? self.tmpKanjiImage : nil
            }
        )
        
        FormContainer {
            VStack {
                img
                    .resizable()
                    .frame(width: 100, height: 100)
                Button {
                    showImageTypeDialog = true
                } label: {
                    Text("Add Image")
                }
                .buttonStyle(.borderedProminent)
                .confirmationDialog("Choose where will you import the image?",
                                    isPresented: $showImageTypeDialog,
                                    titleVisibility: .hidden
                ) {
                    Button {
                        if let importKanji = self.importKanji {
                            importKanji()
                        }
                    } label: {
                        Text("Import")
                    }
                    
                    Button {
                        type = .camera
                        showPhotoPicker = true
                    } label: {
                        Text("Camera")
                    }
                    
                    Button {
                        type = .photoLibrary
                        showPhotoPicker = true
                    } label: {
                        Text("Gallery")
                    }
                }
            }
            TextField("Description", text: $description, axis: .vertical)
                .lineLimit(5...10)
                .textFieldStyle(.roundedBorder)
                .padding(10)
        } action: {
            Button {
                if let save = self.save {
                    save(description, kanji)
                }
            } label: {
                Text("Save")
            }
            .buttonStyle(.borderedProminent)
        }
        .fullScreenCover(isPresented: $showPhotoPicker) {
            MyPhotoPicker(sourceType:type) { image in
                let fixedImageOrientation = image.fixOrientation()
                tmpKanjiImage = fixedImageOrientation
                showPhotoPicker = false
                cropRect = getImageRect(image: fixedImageOrientation)
            }
        }
        .fullScreenCover(isPresented: isTmpKanjiImagePicked){
            if let tmpKanjiImage = tmpKanjiImage {
                ServerStateOverlay {
                    VStack(alignment: .center, spacing: 10) {
                        CropOverlay(image: tmpKanjiImage, cropRect: $cropRect, lockAspectRatio: $lockAspectRatio, aspectRatio: $aspectRatio)
                        
                        HStack(spacing: 10) {
                            Button {
                                showPhotoPicker = true
                                isTmpKanjiImagePicked.wrappedValue = false
                            } label: {
                                Text("Re-take")
                            }
                            
                            Button {
                                if let croppedTmpKanjiImage = tmpKanjiImage.cropImage(cropRect: cropRect) {
                                    self.extractText(image: croppedTmpKanjiImage)
                                }
                            } label: {
                                Text("Crop Image")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func onImportKanji(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.importKanji = action
        return copy
    }
    
    func onSave(_ action: @escaping (String, Kanji?) -> Void) -> Self {
        var copy = self
        copy.save = action
        return copy
    }
    
    private func getImageRect(image: UIImage) -> CGRect {
        // Default to center square that's 80% of the smaller dimension
        let minDimension = min(image.size.width, image.size.height) * 0.8
        let centerX = (image.size.width - minDimension) / 2
        let centerY = (image.size.height - minDimension) / 2
        return CGRect(x: centerX, y: centerY, width: minDimension, height: minDimension)
    }
    
    private func extractText(image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        
        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        request.recognitionLanguages = ["ja-JP"]
        
        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
    
    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations =
                request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        let recognizedStrings = observations.compactMap { observation in
            // Return the string of the top VNRecognizedText instance.
            return observation.topCandidates(1).first?.string
        }
        
        // Process the recognized strings.
        let kanjiText = recognizedStrings.joined(separator: " ")
        
        Task {
            if let kanji = await modelData.getKanji(kanji: kanjiText),
               let lastStrokeOrder =  kanji.strokeOrders.last,
               let kanjiImage = UIImage.imageFromBase64SVG(lastStrokeOrder) {
                self.kanji = kanji
                self.kanjiImage = kanjiImage
                self.tmpKanjiImage = nil
            }
        }
    }
}
