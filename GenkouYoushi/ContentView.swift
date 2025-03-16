import SwiftUI

struct ContentView: View {
    @Binding var document: GenkouYoushiDocument
    @State private var isEditing: Bool = false
    
    @State private var showInitDialog: Bool = false
    @State private var showFormSheet: Bool = false
    
    @State private var showPhotoPicker: Bool = false
    @State private var type: UIImagePickerController.SourceType = .photoLibrary
    @State private var uiImage: UIImage? = nil
    
    @State private var croppedImage: UIImage?
    @State private var cropRect: CGRect = CGRect(x: 100, y: 100, width: 200, height: 200)
    @State private var imageSize: CGSize = .zero
    
    var body: some View {
        VStack {
            if document.pdfData.isEmpty {
                Button {
                    showInitDialog = true
                } label: {
                    Text("Create Paper")
                }
                .buttonStyle(.borderedProminent)
                .confirmationDialog("Choose how will you initialize your paper?",
                                    isPresented: $showInitDialog,
                                    titleVisibility: .hidden
                ) {
                    Button {
                        showInitDialog = false
                        document.pdfData = initStroke()
                    } label: {
                        Text("Empty Paper")
                    }
                    
                    Button {
                        showInitDialog = false
                        showPhotoPicker = true
                    } label: {
                        Text("With Kanji")
                    }
                }
            } else {
                MyPDFViewPresentable(data: $document.pdfData, isEditing: $isEditing)
            }
        }.toolbar {
            ToolbarItemGroup {
                if !document.pdfData.isEmpty {
                    Toggle(isOn: $isEditing) {
                        Image(systemName: "pencil.tip.crop.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showFormSheet) {}
        .fullScreenCover(isPresented: $showPhotoPicker) {
            MyPhotoPicker(sourceType:type) { image in
                uiImage = image
                croppedImage = nil
            }
        }
    }
    
    func initStroke() -> Data {
        let pageMaxWidth: CGFloat = 1600
        let pageMaxHeight: CGFloat = 2400
        
        let blockStartHeight: CGFloat = pageMaxHeight -  pageMaxWidth
        let cellSize: CGFloat = 80
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageMaxWidth, height: pageMaxHeight))
        let pdf = renderer.pdfData { context in
            context.beginPage()
            
            let path = UIBezierPath()
            
            // Draw vertical lines
            for i in stride(from: cellSize, to: pageMaxWidth, by: cellSize) {
                path.move(to: CGPoint(x: i, y: blockStartHeight))
                path.addLine(to:  CGPoint(x: i, y: pageMaxHeight))
                path.stroke()
            }
            
            // Draw horizontal lines
            for i in stride(from: blockStartHeight, to: pageMaxHeight, by: cellSize) {
                path.move(to: CGPoint(x: 0, y: i))
                path.addLine(to:  CGPoint(x: pageMaxHeight, y: i))
                path.stroke()
            }
        }
        
        return pdf
    }
}

public extension UIImage {
    // Ref: https://stackoverflow.com/a/48110726/29628503
    func croppedImage(renderSize: CGSize, in rect: CGRect) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        
        // It somehow rotated
        let originalWidth = CGFloat(cgImage.height)
        let originalHeight = CGFloat(cgImage.width)
        let scaledWidth = renderSize.width
        let scaledHeight = renderSize.height
        
        let scaleWidth = originalWidth / scaledWidth
        let scaleHeight = originalHeight / scaledHeight
        
        let scaledX = rect.origin.x
        let scaledY = rect.origin.y
        let scaledWidthToTranslate = rect.width
        let scaledHeightToTranslate = rect.height
        
        let originalX = scaledX * scaleWidth
        let originalY = scaledY * scaleHeight
        let originalWidthTranslated = scaledWidthToTranslate * scaleWidth
        let originalHeightTranslated = scaledHeightToTranslate * scaleHeight
        
        let convertedRect = CGRect(x: originalX, y: originalY, width: originalWidthTranslated, height: originalHeightTranslated)
        
        let rad: (Double) -> CGFloat = { deg in
            return CGFloat(deg / 180.0 * .pi)
        }
        var rectTransform: CGAffineTransform
        switch imageOrientation {
        case .left:
            let rotation = CGAffineTransform(rotationAngle: rad(90))
            rectTransform = rotation.translatedBy(x: 0, y: -size.height)
        case .right:
            let rotation = CGAffineTransform(rotationAngle: rad(-90))
            rectTransform = rotation.translatedBy(x: -size.width, y: 0)
        case .down:
            let rotation = CGAffineTransform(rotationAngle: rad(-180))
            rectTransform = rotation.translatedBy(x: -size.width, y: -size.height)
        default:
            rectTransform = .identity
        }
        rectTransform = rectTransform.scaledBy(x: scale, y: scale)
        let transformedRect = convertedRect.applying(rectTransform)
        if let imageRef = cgImage.cropping(to: transformedRect) {
            return UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
}


#Preview {
    ContentView(document: .constant(GenkouYoushiDocument()))
}
