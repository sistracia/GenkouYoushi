import SwiftUI
import Vision

struct KanjiFormInput: View {
    @Environment(ModelData.self) var modelData
    
    @Binding var isInputKanji: Bool
    @Binding var description: String
    @Binding var kanjiImage: UIImage?
    let onSave: () -> Void
    
    @State private var tmpKanjiImage: UIImage? = nil
    
    @State private var showImageTypeDialog: Bool = false
    @State private var showPhotoPicker: Bool = false
    
    @State private var type: UIImagePickerController.SourceType = .photoLibrary
    @State private var cropRect: CGRect = CGRect(x: 100, y: 100, width: 200, height: 200)
    @State private var lockRatio: Bool = true
    @State private var imageSize: CGSize = .zero
    
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
                        withAnimation {
                            isInputKanji = true
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
                onSave()
            } label: {
                Text("Save")
            }
            .buttonStyle(.borderedProminent)
        }
        .fullScreenCover(isPresented: $showPhotoPicker) {
            MyPhotoPicker(sourceType:type) { image in
                tmpKanjiImage = image
                showPhotoPicker = false
            }
        }
        .fullScreenCover(isPresented: isTmpKanjiImagePicked){
            if let tmpKanjiImage = tmpKanjiImage {
                ServerStateOverlay {
                    VStack(alignment: .center, spacing: 10) {
                        Image(uiImage: tmpKanjiImage)
                            .resizable()
                            .scaledToFit()
                            .overlay(
                                GeometryReader { geometry in
                                    CropOverlay(cropRect: $cropRect, lockRatio: $lockRatio, imageSize: geometry.size)
                                        .onAppear {
                                            imageSize = geometry.size
                                        }
                                }
                            )
                        HStack(spacing: 10) {
                            Button {
                                showPhotoPicker = true
                                isTmpKanjiImagePicked.wrappedValue = false
                            } label: {
                                Text("Re-take")
                            }
                            
                            Button {
                                if let croppedTmpKanjiImage = tmpKanjiImage.croppedImage(renderSize: imageSize, in: cropRect) {
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
    
    func extractText(image: UIImage) {
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
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
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
        debugPrint(kanjiText)
        
        Task {
            if let kanji = await modelData.getKanji(kanji: kanjiText),
               let lastStrokeOrder =  kanji.strokeOrders.last,
               let kanjiImage = UIImage.imageFromBase64SVG(lastStrokeOrder) {
                self.kanjiImage = kanjiImage
                self.tmpKanjiImage = nil
            }
        }
    }
}
