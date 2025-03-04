import PDFKit
import PencilKit

class MyPDFView: PDFView  {
    private let myOverlay = MyPDFPageOverlay()
    private let toolPicker = PKToolPicker()
    private var isToolPickerShow = false
    var data = Data()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.autoScales = true
        self.pageOverlayViewProvider = self.myOverlay
        self.isInMarkupMode = true
    }
    
    func loadPDF(data: Data) {
        let document = PDFDocument(data: data)!
        document.delegate = self
        self.document = document
        self.data = data
    }
    
    func showToolPicker(isEnabled: Bool) {
        if (self.isToolPickerShow || !isEnabled) {
            return
        }
        
        guard let page = currentPage as? MyPDFPage,
              let myCanvasView = myOverlay.pageToViewMapping[page],
              let document = self.document
        else { return }
        
        // When start annotating, remove our annotation then load to `PKCanvasView`
        // so we can edit back the drawing
        for i in 0...document.pageCount-1 {
            if let page = document.page(at: i) {
                for annotate in page.annotations {
                    for annotateKey in annotate.annotationKeyValues.keys {
                        if let baseKey = annotateKey.base as? String,
                           baseKey.contains("/\(MyPDFAnnotation.drawingAnnotationKey)") {
                            page.removeAnnotation(annotate)
                        }
                    }
                }
            }
        }
        
        self.isToolPickerShow = true
        self.toolPicker.addObserver(myCanvasView.canvasView)
        self.toolPicker.setVisible(true, forFirstResponder: myCanvasView.canvasView)
        myCanvasView.canvasView.isUserInteractionEnabled = true
        myCanvasView.canvasView.becomeFirstResponder()
    }
    
    func addDrawAnnotations() -> Optional<Data> {
        guard let document = self.document else { return nil }
        
        for i in 0...document.pageCount-1 {
            if let page = document.page(at: i),
               let page = page as? MyPDFPage,
               let canvasView = page.myCanvasView?.canvasView {
                
                let mediaBoxBounds = page.bounds(for: .mediaBox)
                let mediaBoxHeight = page.bounds(for: .mediaBox).height
                let properties = [MyPDFAnnotation.drawingMediaBoxAnnotationKey:NSNumber(value: mediaBoxHeight)]

                // Create an annotation of our custom subclass
                let newAnnotation = MyPDFAnnotation(bounds: mediaBoxBounds, forType: .stamp, withProperties: properties)
                
                // Add our custom data
                let codedData = try! NSKeyedArchiver.archivedData(withRootObject: canvasView.drawing, requiringSecureCoding: true)
                newAnnotation.setValue(codedData, forAnnotationKey: PDFAnnotationKey(rawValue: MyPDFAnnotation.drawingAnnotationKey))
                
                // Add our annotation to the page
                page.addAnnotation(newAnnotation)
            }
        }
        
        // Save the document to data representation
        //            let options: [PDFDocumentWriteOption: Bool] = [
        //                // To "burn" the annotation to the real page
        //                .burnInAnnotationsOption: true,
        //                // To make any image in PDF saved as JPEG
        //                .saveImagesAsJPEGOption: true,
        //                // Downsample the image to max high DPI of screen resolution
        //                .optimizeImagesForScreenOption: true
        //            ]
        if let resultData = document.dataRepresentation() {
            return resultData
        }
        
        return nil
    }
}

extension MyPDFView: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        return MyPDFPage.self
    }
}
