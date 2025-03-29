import SwiftUI

struct KanjiForm: View {
    var onSave: (String, UIImage?) -> Void
    
    @State private var description: String = ""
    @State private var kanjiImage: UIImage? = nil
    @State private var croppedKanjiImage: UIImage? = nil
    
    @State private var showImageTypeDialog: Bool = false
    @State private var showPhotoPicker: Bool = false
    
    @State private var type: UIImagePickerController.SourceType = .photoLibrary
    @State private var cropRect: CGRect = CGRect(x: 100, y: 100, width: 200, height: 200)
    @State private var imageSize: CGSize = .zero
    
    var img: Image {
        if let croppedKanjiImage = croppedKanjiImage{
            return Image(uiImage: croppedKanjiImage)
        }
        
        return Image(systemName: "plus.square.dashed")
    }
    
    var body: some View {
        let isKanjiImagePicked = Binding(
            get: {
                return self.kanjiImage != nil
            },
            set: { value in
                self.kanjiImage = nil
            }
        )
        
        VStack(alignment: .trailing, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
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
                            // TODO: User can type the kanji the user want and app fetch the kanji image somewhere
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
            }
            Button {
                onSave(description, croppedKanjiImage)
            } label: {
                Text("Save")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(10)
        .fullScreenCover(isPresented: $showPhotoPicker) {
            MyPhotoPicker(sourceType:type) { image in
                kanjiImage = image
                showPhotoPicker = false
            }
        }
        .fullScreenCover(isPresented: isKanjiImagePicked){
            if let kanjiImage = kanjiImage {
                VStack(alignment: .center, spacing: 10) {
                    Image(uiImage: kanjiImage)
                        .resizable()
                        .scaledToFit()
                        .overlay(
                            GeometryReader { geometry in
                                CropOverlay(cropRect: $cropRect, imageSize: geometry.size)
                                    .onAppear {
                                        imageSize = geometry.size
                                    }
                            }
                        )
                    Button {
                        self.croppedKanjiImage = kanjiImage.croppedImage(renderSize: imageSize, in: cropRect)
                        self.kanjiImage = nil
                    } label: {
                        Text("Crop Image")
                    }
                }
            }
        }
    }
}

#Preview {
    KanjiForm() { _, __ in}
}
